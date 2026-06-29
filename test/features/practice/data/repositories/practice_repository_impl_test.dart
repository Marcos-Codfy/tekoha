// test/features/practice/data/repositories/practice_repository_impl_test.dart
//
// Foco: comportamento do cache (1a chamada bate na fonte, 2a usa cache,
// forceRefresh ignora cache) e propagacao de erro do datasource.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/practice/data/datasources/practice_remote_datasource.dart';
import 'package:tekoha/features/practice/data/dtos/airtable_module_dto.dart';
import 'package:tekoha/features/practice/data/repositories/practice_repository_impl.dart';

class _MockDS extends Mock implements PracticeRemoteDataSource {}

void main() {
  late _MockDS ds;
  late PracticeRepositoryImpl repo;

  setUp(() {
    ds = _MockDS();
    repo = PracticeRepositoryImpl(ds);
  });

  const sampleDtos = [
    AirtableModuleDto(
      id: 'r1',
      name: 'Saudacoes',
      description: '',
      language: 'nheengatu',
      order: 1,
    ),
  ];

  test('1a chamada bate na fonte e devolve entities', () async {
    when(() => ds.fetchModules('nheengatu'))
        .thenAnswer((_) async => const Success(sampleDtos));

    final r = await repo.getModules(language: 'nheengatu');

    expect(r.isSuccess, true);
    expect(r.getOrNull()!.first.name, 'Saudacoes');
    verify(() => ds.fetchModules('nheengatu')).called(1);
  });

  test('2a chamada usa cache (datasource chamado 1x apenas)', () async {
    when(() => ds.fetchModules('nheengatu'))
        .thenAnswer((_) async => const Success(sampleDtos));

    await repo.getModules(language: 'nheengatu');
    await repo.getModules(language: 'nheengatu');

    verify(() => ds.fetchModules('nheengatu')).called(1);
  });

  test('forceRefresh = true ignora cache e bate na fonte de novo', () async {
    when(() => ds.fetchModules('nheengatu'))
        .thenAnswer((_) async => const Success(sampleDtos));

    await repo.getModules(language: 'nheengatu');
    await repo.getModules(language: 'nheengatu', forceRefresh: true);

    verify(() => ds.fetchModules('nheengatu')).called(2);
  });

  test('falha do datasource e propagada sem cache', () async {
    when(() => ds.fetchModules('nheengatu'))
        .thenAnswer((_) async => const FailureResult(NetworkFailure()));

    final r1 = await repo.getModules(language: 'nheengatu');
    expect(r1.failureOrNull(), isA<NetworkFailure>());

    // 2a chamada bate de novo na fonte (cache nao guardou erro).
    when(() => ds.fetchModules('nheengatu'))
        .thenAnswer((_) async => const Success(sampleDtos));
    final r2 = await repo.getModules(language: 'nheengatu');
    expect(r2.isSuccess, true);
    verify(() => ds.fetchModules('nheengatu')).called(2);
  });

  test('cache e por idioma (nheengatu vs outro nao colidem)', () async {
    when(() => ds.fetchModules('nheengatu'))
        .thenAnswer((_) async => const Success(sampleDtos));
    when(() => ds.fetchModules('outro'))
        .thenAnswer((_) async => const Success([]));

    await repo.getModules(language: 'nheengatu');
    await repo.getModules(language: 'outro');
    await repo.getModules(language: 'nheengatu'); // cache hit
    await repo.getModules(language: 'outro'); // cache hit

    verify(() => ds.fetchModules('nheengatu')).called(1);
    verify(() => ds.fetchModules('outro')).called(1);
  });
}
