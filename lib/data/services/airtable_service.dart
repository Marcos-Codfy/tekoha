// lib/data/services/airtable_service.dart
// Camada: Data (implementacao concreta de ContentRepository).
//
// Conversa com a API REST do Airtable pra buscar modulos, licoes e palavras.
// Toda falha (HTTP, rede, parse) e empacotada como [ContentException] —
// a unica excecao que sobe pra camada de Provider/UI. Assim a UI nunca
// precisa saber que Airtable existe (Clean Architecture).
//
// REGRA DE SEGURANCA: nunca logar o token e nunca expor o token em
// mensagem de erro pro usuario final.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/lesson_model.dart';
import '../models/module_model.dart';
import '../models/word_model.dart';
import '../repositories/content_repository.dart';

class AirtableService implements ContentRepository {
  // ── Configuracao vinda do .env ──────────────────────────────────────
  // Le as variaveis uma unica vez quando a classe e instanciada.
  // Se a variavel nao existir no .env, cai pro fallback (string vazia
  // ou nome de tabela padrao). Credenciais ausentes sao detectadas em
  // [_ensureCredentials] antes da primeira chamada HTTP.
  final String _apiKey     = dotenv.env['AIRTABLE_API_KEY']       ?? '';
  final String _baseId     = dotenv.env['AIRTABLE_BASE_ID']       ?? '';
  final String _modulesTab = dotenv.env['AIRTABLE_MODULES_TABLE'] ?? 'Modules';
  final String _lessonsTab = dotenv.env['AIRTABLE_LESSONS_TABLE'] ?? 'Lessons';
  final String _wordsTab   = dotenv.env['AIRTABLE_WORDS_TABLE']   ?? 'Words';

  /// Tempo maximo que uma requisicao pode demorar. 15s e generoso pra
  /// rede ruim mas evita o app travar pra sempre.
  static const Duration _timeout = Duration(seconds: 15);

  /// Header HTTP com Bearer token. Encapsulado num getter pra reaproveitar.
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
      };

  /// Valida que temos credenciais antes de tentar bater na API.
  /// Da mensagem clara em vez de erro HTTP confuso depois.
  void _ensureCredentials() {
    if (_apiKey.isEmpty || _baseId.isEmpty) {
      throw ContentException(
        'Configuracao do Airtable nao encontrada. Verifique o arquivo .env.',
        'AIRTABLE_API_KEY ou AIRTABLE_BASE_ID ausente no dotenv',
      );
    }
  }

  /// Faz um GET autenticado no Airtable e devolve a lista de records.
  /// Centraliza HTTP + tratamento de erro + parse de JSON num lugar so,
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
      throw ContentException(
        'Sem conexao com a internet. Verifique sua rede e tente de novo.',
      );
    } on TimeoutException {
      // TimeoutException = requisicao demorou mais que [_timeout].
      throw ContentException(
        'A requisicao demorou demais. Tente de novo em alguns segundos.',
      );
    } catch (e) {
      // Qualquer outro erro de rede inesperado.
      throw ContentException('Erro de rede ao buscar conteudo.', e.toString());
    }

    // Tratamento por status code HTTP. Cada caso da uma mensagem amigavel.
    switch (response.statusCode) {
      case 200:
        break; // sucesso, continua pro parse abaixo
      case 401:
        throw ContentException(
          'Token do Airtable invalido ou expirado. Avise o desenvolvedor.',
          'HTTP 401 - verifique AIRTABLE_API_KEY no .env',
        );
      case 403:
        throw ContentException(
          'Sem permissao pra acessar essa base no Airtable.',
          'HTTP 403',
        );
      case 404:
        throw ContentException(
          'Base ou tabela "$tableName" nao encontrada.',
          'HTTP 404',
        );
      case 429:
        throw ContentException(
          'Muitas requisicoes em pouco tempo. Aguarde alguns segundos.',
          'HTTP 429 (rate limit)',
        );
      default:
        throw ContentException(
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
      throw ContentException('Resposta do servidor em formato invalido.');
    }

    final records = jsonBody['records'];
    if (records is! List) {
      throw ContentException('Resposta do servidor sem a chave "records".');
    }

    return records.cast<Map<String, dynamic>>();
  }

  // ── Metodos publicos do contrato ContentRepository ────────────────

  @override
  Future<List<ModuleModel>> fetchAllModules(String language) async {
    // Filtro: so modulos ATIVOS do idioma pedido.
    // {is_active} e {language} sao nomes de campos nao-linkados — funcionam
    // dentro de uma formula do Airtable sem o problema dos Linked Records
    // (ver comentario em fetchLessonsByModule).
    final formula = "AND({is_active}=TRUE(), {language}='$language')";

    final records = await _get(_modulesTab, queryParams: {
      'filterByFormula': formula,
      // Sort no servidor garante que vem ordenado 1, 2, 3 — nao precisa
      // reordenar no app.
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
    //
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
