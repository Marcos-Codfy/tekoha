// test/features/progress/data/repositories/user_progress_repository_impl_test.dart
//
// Estrategia: datasource mockado (mocktail). Casos: usuario novo (doc
// null -> empty), doc existente mapeado pra entity, uid vazio barrado,
// FirebaseException mapeada pra Failure tipada, excecao generica.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/progress/data/datasources/firestore_progress_datasource.dart';
import 'package:tekoha/features/progress/data/repositories/user_progress_repository_impl.dart';
import 'package:tekoha/features/progress/domain/entities/user_progress.dart';

class _MockDataSource extends Mock implements FirestoreProgressDataSource {}

void main() {
  late _MockDataSource dataSource;
  late UserProgressRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDataSource();
    repository = UserProgressRepositoryImpl(dataSource);
  });

  group('fetch', () {
    test('documento inexistente devolve UserProgress.empty (nao e erro)',
        () async {
      when(() => dataSource.fetch('u1')).thenAnswer((_) async => null);

      final result = await repository.fetch('u1');

      final progress = result.fold(
        onSuccess: (p) => p,
        onFailure: (_) => null,
      );
      expect(progress, isNotNull);
      expect(progress!.xp, 0);
      expect(progress.streakDays, 0);
    });

    test('documento existente e mapeado pra entity', () async {
      when(() => dataSource.fetch('u1')).thenAnswer((_) async => {
            'xp': 200,
            'streak_days': 4,
            'last_practice_at': '2026-07-02T08:00:00.000',
            'stages_done': {
              'm1': [0, 1],
            },
          });

      final result = await repository.fetch('u1');

      final progress = result.fold(
        onSuccess: (p) => p,
        onFailure: (_) => null,
      );
      expect(progress!.xp, 200);
      expect(progress.streakDays, 4);
      expect(progress.lastPracticeAt, DateTime(2026, 7, 2, 8));
      expect(progress.stagesDone('m1'), {0, 1});
    });

    test('uid vazio devolve AuthApiFailure sem tocar o datasource',
        () async {
      final result = await repository.fetch('');

      expect(result, isA<FailureResult<UserProgress, Failure>>());
      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (f) => f,
      );
      expect(failure, isA<AuthApiFailure>());
      verifyNever(() => dataSource.fetch(any()));
    });

    test('permission-denied vira AuthApiFailure', () async {
      when(() => dataSource.fetch('u1')).thenThrow(FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'denied',
      ));

      final result = await repository.fetch('u1');

      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (f) => f,
      );
      expect(failure, isA<AuthApiFailure>());
    });

    test('unavailable vira NetworkFailure', () async {
      when(() => dataSource.fetch('u1')).thenThrow(FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      ));

      final result = await repository.fetch('u1');

      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (f) => f,
      );
      expect(failure, isA<NetworkFailure>());
    });

    test('excecao generica vira UnknownFailure (fallback)', () async {
      when(() => dataSource.fetch('u1')).thenThrow(StateError('boom'));

      final result = await repository.fetch('u1');

      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (f) => f,
      );
      expect(failure, isA<UnknownFailure>());
    });
  });

  group('save', () {
    test('persiste o mapa do DTO via datasource', () async {
      when(() => dataSource.save(any(), any())).thenAnswer((_) async {});

      final progress = UserProgress.empty.afterStageCompleted(
        gainedXp: 30,
        moduleId: 'm1',
        stageIndex: 0,
        now: DateTime(2026, 7, 2, 10),
      );

      final result = await repository.save('u1', progress);

      expect(result, isA<Success<void, Failure>>());
      final captured =
          verify(() => dataSource.save('u1', captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['xp'], 30);
      expect(captured['streak_days'], 1);
      expect(captured['stages_done'], {
        'm1': [0],
      });
    });

    test('uid vazio devolve AuthApiFailure sem tocar o datasource',
        () async {
      final result = await repository.save('', UserProgress.empty);

      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (f) => f,
      );
      expect(failure, isA<AuthApiFailure>());
      verifyNever(() => dataSource.save(any(), any()));
    });

    test('deadline-exceeded vira TimeoutFailure', () async {
      when(() => dataSource.save(any(), any())).thenThrow(FirebaseException(
        plugin: 'cloud_firestore',
        code: 'deadline-exceeded',
      ));

      final result = await repository.save('u1', UserProgress.empty);

      final failure = result.fold(
        onSuccess: (_) => null,
        onFailure: (f) => f,
      );
      expect(failure, isA<TimeoutFailure>());
    });
  });
}
