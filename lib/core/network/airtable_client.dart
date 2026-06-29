// lib/core/network/airtable_client.dart
// Camada: Core / Network.
//
// Cliente HTTP focado em Airtable REST API.
// Centraliza:
//   - autenticacao (Bearer token)
//   - timeout
//   - mapeamento de status code -> Failure tipada
//   - parse defensivo do JSON
//
// Cada DataSource concreto (Practice/Culture/Lesson) injeta este cliente
// e SO chama [getRecords]. Mantem a logica de rede num lugar so e os
// datasources curtinhos.
//
// REGRA DE SEGURANCA: nunca logar o `apiKey` e nunca devolver ele em
// `technicalDetails` (vazaria pro debug log).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/failures.dart';
import '../result/result.dart';

class AirtableClient {
  final String _apiKey;
  final String _baseId;
  final http.Client _httpClient;

  /// Tempo maximo da requisicao. 15s e generoso pra rede ruim mas evita
  /// travar o app pra sempre.
  static const Duration _timeout = Duration(seconds: 15);

  AirtableClient({
    required String apiKey,
    required String baseId,
    required http.Client httpClient,
  })  : _apiKey = apiKey,
        _baseId = baseId,
        _httpClient = httpClient;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      };

  /// Devolve a lista de `records` da tabela [tableName].
  ///
  /// Quando algo da errado, devolve `FailureResult<..., Failure>` com a
  /// Failure mais especifica possivel — o caller faz `result.fold` e
  /// decide o que mostrar ao usuario.
  Future<Result<List<Map<String, dynamic>>, Failure>> getRecords(
    String tableName, {
    Map<String, String>? queryParams,
  }) async {
    // ── Validacao de credenciais antes de bater na rede ──────────────
    if (_apiKey.isEmpty || _baseId.isEmpty) {
      return const FailureResult(
        ConfigFailure(
          'Configuracao do Airtable nao encontrada. Verifique o arquivo .env.',
          'AIRTABLE_API_KEY ou AIRTABLE_BASE_ID ausente',
        ),
      );
    }

    final uri = Uri.https(
      'api.airtable.com',
      '/v0/$_baseId/$tableName',
      queryParams,
    );

    http.Response response;
    try {
      response = await _httpClient
          .get(uri, headers: _headers)
          .timeout(_timeout);
    } on SocketException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on TimeoutException catch (e) {
      return FailureResult(TimeoutFailure(e.message));
    } catch (e) {
      return FailureResult(UnknownFailure(e.toString()));
    }

    // ── Mapeamento status code -> Failure ────────────────────────────
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        return const FailureResult(
          AuthApiFailure(
            'Token do Airtable invalido ou expirado. Avise o desenvolvedor.',
            'HTTP 401',
          ),
        );
      case 403:
        return const FailureResult(
          AuthApiFailure(
            'Sem permissao pra acessar essa base no Airtable.',
            'HTTP 403',
          ),
        );
      case 404:
        return FailureResult(
          NotFoundFailure('Base ou tabela "$tableName" nao encontrada.', 'HTTP 404'),
        );
      case 429:
        return const FailureResult(RateLimitFailure('HTTP 429'));
      default:
        return FailureResult(
          ServerFailure(
            'Erro ao buscar conteudo (codigo ${response.statusCode}).',
            'HTTP ${response.statusCode}',
          ),
        );
    }

    // ── Parse defensivo do JSON ──────────────────────────────────────
    Map<String, dynamic> jsonBody;
    try {
      jsonBody = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      return FailureResult(ServerFailure(
        'Resposta do servidor em formato invalido.',
        e.message,
      ));
    } catch (e) {
      return FailureResult(ServerFailure(
        'Resposta do servidor em formato invalido.',
        e.toString(),
      ));
    }

    final records = jsonBody['records'];
    if (records is! List) {
      return const FailureResult(ServerFailure(
        'Resposta do servidor sem a chave "records".',
      ));
    }

    return Success(records.cast<Map<String, dynamic>>());
  }
}
