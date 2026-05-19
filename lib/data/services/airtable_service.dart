// lib/data/services/airtable_service.dart
// Implementacao do ContentRepository que conversa com a API REST do Airtable.
// Responsavel: Marcos (gerado por Claude na Sprint 3)
//
// O que esse arquivo faz:
// - Le AIRTABLE_API_KEY, AIRTABLE_BASE_ID e nomes das tabelas do .env
// - Monta requests HTTP GET pra Airtable com filterByFormula + sort
// - Converte o JSON de resposta nos models (ModuleModel, LessonModel, WordModel)
// - Trata erros de rede, auth e dados de forma amigavel pro usuario
//
// REGRA DE SEGURANCA: nunca logar o token e nunca expor o token em
// mensagem de erro pro usuario final.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/module_model.dart';
import '../models/lesson_model.dart';
import '../models/word_model.dart';
import '../repositories/content_repository.dart';

/// Excecao customizada do AirtableService.
/// Carrega uma `userMessage` em portugues que pode ser mostrada na UI direto.
/// `technicalDetails` e SO pra log/debug, NUNCA mostrar pro usuario final.
class AirtableException implements Exception {
  final String userMessage;
  final String? technicalDetails;
  AirtableException(this.userMessage, [this.technicalDetails]);

  @override
  String toString() => 'AirtableException: $userMessage';
}

class AirtableService implements ContentRepository {
  // Le as variaveis do .env uma unica vez quando a classe e instanciada.
  // Se a variavel nao existir no .env, cai pro fallback (string vazia ou nome padrao).
  final String _apiKey     = dotenv.env['AIRTABLE_API_KEY']       ?? '';
  final String _baseId     = dotenv.env['AIRTABLE_BASE_ID']       ?? '';
  final String _modulesTab = dotenv.env['AIRTABLE_MODULES_TABLE'] ?? 'Modules';
  final String _lessonsTab = dotenv.env['AIRTABLE_LESSONS_TABLE'] ?? 'Lessons';
  final String _wordsTab   = dotenv.env['AIRTABLE_WORDS_TABLE']   ?? 'Words';

  // Tempo maximo que uma requisicao pode demorar antes de ser cancelada.
  // 15s e generoso pra rede ruim, mas evita o app travar pra sempre.
  static const Duration _timeout = Duration(seconds: 15);

  /// Header HTTP com Bearer token. Encapsulado num getter pra reaproveitar.
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      };

  /// Valida que temos credenciais antes de tentar bater na API.
  /// Se faltar API key ou Base ID, da mensagem clara em vez de erro HTTP confuso.
  void _ensureCredentials() {
    if (_apiKey.isEmpty || _baseId.isEmpty) {
      throw AirtableException(
        'Configuracao do Airtable nao encontrada. Verifique o arquivo .env.',
        'AIRTABLE_API_KEY ou AIRTABLE_BASE_ID ausente no dotenv',
      );
    }
  }

  /// Faz um GET autenticado no Airtable e devolve a lista de records.
  /// Concentra HTTP + tratamento de erro + parse de JSON em um lugar so,
  /// pra cada metodo publico (fetchAllModules etc) ficar curto e claro.
  Future<List<Map<String, dynamic>>> _get(
    String tableName, {
    Map<String, String>? queryParams,
  }) async {
    _ensureCredentials();

    // Uri.https monta a URL com encoding correto dos query params.
    // Ex: api.airtable.com/v0/appXXX/Modules?filterByFormula=...&sort[0][field]=order
    final uri = Uri.https(
      'api.airtable.com',
      '/v0/$_baseId/$tableName',
      queryParams,
    );

    http.Response response;
    try {
      response = await http.get(uri, headers: _headers).timeout(_timeout);
    } on SocketException {
      // SocketException = sem internet, DNS falhou, host inalcancavel.
      throw AirtableException(
        'Sem conexao com a internet. Verifique sua rede e tente de novo.',
      );
    } on TimeoutException {
      // TimeoutException = requisicao demorou mais que _timeout.
      throw AirtableException(
        'A requisicao demorou demais. Tente de novo em alguns segundos.',
      );
    } catch (e) {
      // Qualquer outro erro de rede inesperado.
      throw AirtableException(
        'Erro de rede ao buscar conteudo.',
        e.toString(),
      );
    }

    // Tratamento por status code HTTP. Cada caso devolve mensagem amigavel.
    switch (response.statusCode) {
      case 200:
        break; // sucesso, continua o parse abaixo
      case 401:
        throw AirtableException(
          'Token do Airtable invalido ou expirado. Avise o desenvolvedor.',
          'HTTP 401 - verifique AIRTABLE_API_KEY no .env',
        );
      case 403:
        throw AirtableException(
          'Sem permissao pra acessar essa base no Airtable.',
          'HTTP 403',
        );
      case 404:
        throw AirtableException(
          'Base ou tabela "$tableName" nao encontrada.',
          'HTTP 404',
        );
      case 429:
        throw AirtableException(
          'Muitas requisicoes em pouco tempo. Aguarde alguns segundos.',
          'HTTP 429 (rate limit)',
        );
      default:
        throw AirtableException(
          'Erro ao buscar conteudo (codigo ${response.statusCode}).',
          'HTTP ${response.statusCode}',
        );
    }

    // Tenta decodificar o corpo. Se vier malformado, lanca excecao amigavel
    // em vez de quebrar com FormatException feia pro usuario.
    Map<String, dynamic> jsonBody;
    try {
      jsonBody = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw AirtableException('Resposta do servidor em formato invalido.');
    }

    final records = jsonBody['records'];
    if (records is! List) {
      throw AirtableException('Resposta do servidor sem a chave "records".');
    }

    return records.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<ModuleModel>> fetchAllModules(String language) async {
    // Filtro: so modulos ATIVOS do idioma pedido.
    // {is_active} e {language} sao nomes dos campos no Airtable.
    final formula = "AND({is_active}=TRUE(), {language}='$language')";

    final records = await _get(_modulesTab, queryParams: {
      'filterByFormula': formula,
      // Sort no servidor garante que vem ordenado 1, 2, 3 sem precisar reordenar no app.
      'sort[0][field]': 'order',
      'sort[0][direction]': 'asc',
    });

    return records.map((record) {
      final id = (record['id'] ?? '').toString();
      final fields = (record['fields'] ?? <String, dynamic>{}) as Map<String, dynamic>;
      return ModuleModel.fromAirtable(id, fields);
    }).toList();
  }

  @override
  Future<List<LessonModel>> fetchLessonsByModule(String moduleId) async {
    // Buscamos TODAS as licoes e filtramos no codigo pelo moduleId.
    //
    // Por que nao filterByFormula no servidor?
    // Quando uma formula do Airtable referencia um Linked Record, o motor de
    // formulas devolve o NOME (primary field) do registro linkado, nao o ID.
    // Entao FIND('recXXX', ARRAYJOIN({module})) sempre da 0 — filtra tudo.
    // A REST API, porem, devolve o link como ARRAY DE IDS no campo `fields`,
    // entao podemos parsear o moduleId no model e filtrar em Dart. Robusto e
    // suficiente pro MVP (3 licoes total).
    final records = await _get(_lessonsTab, queryParams: {
      'sort[0][field]': 'order',
      'sort[0][direction]': 'asc',
    });

    return records
        .map((record) {
          final id = (record['id'] ?? '').toString();
          final fields = (record['fields'] ?? <String, dynamic>{}) as Map<String, dynamic>;
          return LessonModel.fromAirtable(id, fields);
        })
        .where((lesson) => lesson.moduleId == moduleId)
        .toList();
  }

  @override
  Future<List<WordModel>> fetchWordsByLesson(String lessonId) async {
    // Mesma logica do fetchLessonsByModule: traz todas as palavras e filtra
    // no codigo pelo lessonId. Com 30 palavras no MVP, o custo e desprezivel.
    final records = await _get(_wordsTab, queryParams: {
      'sort[0][field]': 'order',
      'sort[0][direction]': 'asc',
    });

    return records
        .map((record) {
          final id = (record['id'] ?? '').toString();
          final fields = (record['fields'] ?? <String, dynamic>{}) as Map<String, dynamic>;
          return WordModel.fromAirtable(id, fields);
        })
        .where((word) => word.lessonId == lessonId)
        .toList();
  }
}
