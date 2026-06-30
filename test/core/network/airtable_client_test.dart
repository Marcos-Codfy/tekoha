// test/core/network/airtable_client_test.dart
//
// Estrategia: a peca mais critica do tratamento de erros vive aqui.
// Vou cobrir:
//   - sucesso (200 com records validos)
//   - sucesso com lista vazia
//   - 401 -> AuthApiFailure
//   - 403 -> AuthApiFailure (mensagem diferente)
//   - 404 -> NotFoundFailure (com nome da tabela)
//   - 429 -> RateLimitFailure
//   - 500/qualquer outro -> ServerFailure
//   - JSON sem chave 'records' -> ServerFailure
//   - JSON malformado -> ServerFailure
//   - SocketException -> NetworkFailure
//   - TimeoutException -> TimeoutFailure
//   - excecao generica -> UnknownFailure
//   - sem credenciais (apiKey/baseId vazios) -> ConfigFailure (sem bater HTTP)

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/network/airtable_client.dart';

class _MockHttpClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockHttpClient httpClient;
  late AirtableClient airtable;

  setUp(() {
    httpClient = _MockHttpClient();
    airtable = AirtableClient(
      apiKey: 'fake-key',
      baseId: 'appXYZ',
      httpClient: httpClient,
    );
  });

  http.Response ok(List<Map<String, dynamic>> records) {
    return http.Response(
      json.encode({'records': records}),
      200,
    );
  }

  group('getRecords - sucesso', () {
    test('200 com records retorna Success com a lista', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => ok([
                {'id': 'r1', 'fields': {'name': 'A'}},
                {'id': 'r2', 'fields': {'name': 'B'}},
              ]));

      final result = await airtable.getRecords('Modules');

      expect(result.isSuccess, true);
      final list = result.getOrNull()!;
      expect(list, hasLength(2));
      expect(list[0]['id'], 'r1');
    });

    test('200 com lista vazia tambem e sucesso', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => ok([]));

      final result = await airtable.getRecords('Modules');

      expect(result.isSuccess, true);
      expect(result.getOrNull(), isEmpty);
    });
  });

  group('getRecords - erros HTTP', () {
    Future<Failure> runWithStatus(int status, [String body = '{}']) async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(body, status));
      final result = await airtable.getRecords('Modules');
      expect(result.isFailure, true);
      return result.failureOrNull()!;
    }

    test('401 -> AuthApiFailure', () async {
      final f = await runWithStatus(401);
      expect(f, isA<AuthApiFailure>());
      expect(f.userMessage, contains('Token'));
    });

    test('403 -> AuthApiFailure com mensagem de permissao', () async {
      final f = await runWithStatus(403);
      expect(f, isA<AuthApiFailure>());
      expect(f.userMessage, contains('permissao'));
    });

    test('404 -> NotFoundFailure com nome da tabela', () async {
      final f = await runWithStatus(404);
      expect(f, isA<NotFoundFailure>());
      expect(f.userMessage, contains('Modules'));
    });

    test('429 -> RateLimitFailure', () async {
      final f = await runWithStatus(429);
      expect(f, isA<RateLimitFailure>());
    });

    test('500 -> ServerFailure', () async {
      final f = await runWithStatus(500);
      expect(f, isA<ServerFailure>());
    });

    test('418 (codigo qualquer) -> ServerFailure', () async {
      final f = await runWithStatus(418);
      expect(f, isA<ServerFailure>());
    });
  });

  group('getRecords - parse', () {
    test('JSON sem chave "records" -> ServerFailure', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"foo": 1}', 200));

      final result = await airtable.getRecords('Modules');
      expect(result.failureOrNull(), isA<ServerFailure>());
    });

    test('JSON malformado -> ServerFailure', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('not-json', 200));

      final result = await airtable.getRecords('Modules');
      expect(result.failureOrNull(), isA<ServerFailure>());
    });

    test('records nao e lista -> ServerFailure', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response('{"records": "nao-lista"}', 200),
      );

      final result = await airtable.getRecords('Modules');
      expect(result.failureOrNull(), isA<ServerFailure>());
    });
  });

  group('getRecords - excecoes de rede', () {
    test('SocketException -> NetworkFailure', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(const SocketException('dns'));

      final result = await airtable.getRecords('Modules');
      expect(result.failureOrNull(), isA<NetworkFailure>());
    });

    test('TimeoutException -> TimeoutFailure', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(TimeoutException('demorou'));

      final result = await airtable.getRecords('Modules');
      expect(result.failureOrNull(), isA<TimeoutFailure>());
    });

    test('excecao desconhecida -> UnknownFailure', () async {
      when(() => httpClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(StateError('boom'));

      final result = await airtable.getRecords('Modules');
      expect(result.failureOrNull(), isA<UnknownFailure>());
    });
  });

  group('getRecords - credenciais', () {
    test('apiKey vazio -> ConfigFailure SEM bater HTTP', () async {
      final clientSemKey = AirtableClient(
        apiKey: '',
        baseId: 'appXYZ',
        httpClient: httpClient,
      );
      final result = await clientSemKey.getRecords('Modules');
      expect(result.failureOrNull(), isA<ConfigFailure>());
      verifyNever(() => httpClient.get(any(), headers: any(named: 'headers')));
    });

    test('baseId vazio -> ConfigFailure SEM bater HTTP', () async {
      final clientSemBase = AirtableClient(
        apiKey: 'k',
        baseId: '',
        httpClient: httpClient,
      );
      final result = await clientSemBase.getRecords('Modules');
      expect(result.failureOrNull(), isA<ConfigFailure>());
      verifyNever(() => httpClient.get(any(), headers: any(named: 'headers')));
    });
  });
}
