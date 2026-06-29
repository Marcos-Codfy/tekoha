// test/features/culture/data/repositories/culture_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/culture/data/datasources/culture_remote_datasource.dart';
import 'package:tekoha/features/culture/data/dtos/airtable_culture_content_dto.dart';
import 'package:tekoha/features/culture/data/repositories/culture_repository_impl.dart';

class _MockDS extends Mock implements CultureRemoteDataSource {}

void main() {
  late _MockDS ds;
  late CultureRepositoryImpl repo;

  setUp(() {
    ds = _MockDS();
    repo = CultureRepositoryImpl(ds);
  });

  const sample = [
    AirtableCultureContentDto(
      id: 'c1',
      language: 'nheengatu',
      category: 'history',
      title: 't',
      body: 'b',
      order: 1,
      isActive: true,
    ),
  ];

  test('cache hit por (language + category) na 2a chamada', () async {
    when(
      () =>
          ds.fetchContent(language: 'nheengatu', category: 'history'),
    ).thenAnswer((_) async => const Success(sample));

    await repo.getContent(language: 'nheengatu', category: 'history');
    await repo.getContent(language: 'nheengatu', category: 'history');

    verify(
      () =>
          ds.fetchContent(language: 'nheengatu', category: 'history'),
    ).called(1);
  });

  test('category diferente NAO hita o mesmo cache', () async {
    when(() => ds.fetchContent(
        language: 'nheengatu', category: 'history'))
        .thenAnswer((_) async => const Success(sample));
    when(() => ds.fetchContent(
        language: 'nheengatu', category: 'curiosities'))
        .thenAnswer((_) async => const Success([]));

    await repo.getContent(language: 'nheengatu', category: 'history');
    await repo.getContent(language: 'nheengatu', category: 'curiosities');

    verify(() => ds.fetchContent(
        language: 'nheengatu', category: 'history')).called(1);
    verify(() => ds.fetchContent(
        language: 'nheengatu', category: 'curiosities')).called(1);
  });

  test('forceRefresh ignora cache', () async {
    when(() => ds.fetchContent(
        language: 'nheengatu', category: 'history'))
        .thenAnswer((_) async => const Success(sample));

    await repo.getContent(language: 'nheengatu', category: 'history');
    await repo.getContent(
      language: 'nheengatu',
      category: 'history',
      forceRefresh: true,
    );

    verify(() => ds.fetchContent(
        language: 'nheengatu', category: 'history')).called(2);
  });

  test('falha propagada', () async {
    when(() => ds.fetchContent(
        language: 'nheengatu', category: 'history'))
        .thenAnswer((_) async => const FailureResult(NetworkFailure()));

    final r = await repo
        .getContent(language: 'nheengatu', category: 'history');
    expect(r.failureOrNull(), isA<NetworkFailure>());
  });
}
