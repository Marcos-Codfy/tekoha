// test/features/lesson/data/repositories/lesson_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/lesson/data/datasources/lesson_remote_datasource.dart';
import 'package:tekoha/features/lesson/data/dtos/airtable_lesson_dto.dart';
import 'package:tekoha/features/lesson/data/dtos/airtable_word_dto.dart';
import 'package:tekoha/features/lesson/data/repositories/lesson_repository_impl.dart';

class _MockDS extends Mock implements LessonRemoteDataSource {}

void main() {
  late _MockDS ds;
  late LessonRepositoryImpl repo;

  setUp(() {
    ds = _MockDS();
    repo = LessonRepositoryImpl(ds);
  });

  const lessons = [
    AirtableLessonDto(
      id: 'L1',
      title: 'Cumprimentos',
      moduleId: 'M1',
      order: 1,
      xpReward: 100,
    ),
  ];

  const words = [
    AirtableWordDto(
      id: 'W1',
      nheengatu: 'ara',
      translation: 'manha',
      pronunciation: 'A-ra',
      culturalNote: '',
      lessonId: 'L1',
      order: 1,
      audioUrl: 'http://a/a.mp3',
    ),
  ];

  group('getLessonsByModule', () {
    test('cache hit na 2a chamada', () async {
      when(() => ds.fetchLessonsByModule('M1'))
          .thenAnswer((_) async => const Success(lessons));

      await repo.getLessonsByModule('M1');
      await repo.getLessonsByModule('M1');

      verify(() => ds.fetchLessonsByModule('M1')).called(1);
    });

    test('forceRefresh bate de novo na fonte', () async {
      when(() => ds.fetchLessonsByModule('M1'))
          .thenAnswer((_) async => const Success(lessons));

      await repo.getLessonsByModule('M1');
      await repo.getLessonsByModule('M1', forceRefresh: true);

      verify(() => ds.fetchLessonsByModule('M1')).called(2);
    });

    test('falha do datasource e propagada', () async {
      when(() => ds.fetchLessonsByModule('M1'))
          .thenAnswer((_) async => const FailureResult(TimeoutFailure()));

      final r = await repo.getLessonsByModule('M1');
      expect(r.failureOrNull(), isA<TimeoutFailure>());
    });

    test('cache separado por moduleId', () async {
      when(() => ds.fetchLessonsByModule('M1'))
          .thenAnswer((_) async => const Success(lessons));
      when(() => ds.fetchLessonsByModule('M2'))
          .thenAnswer((_) async => const Success([]));

      await repo.getLessonsByModule('M1');
      await repo.getLessonsByModule('M2');
      await repo.getLessonsByModule('M1'); // hit
      await repo.getLessonsByModule('M2'); // hit

      verify(() => ds.fetchLessonsByModule('M1')).called(1);
      verify(() => ds.fetchLessonsByModule('M2')).called(1);
    });
  });

  group('getWordsByLesson', () {
    test('cache hit na 2a chamada', () async {
      when(() => ds.fetchWordsByLesson('L1'))
          .thenAnswer((_) async => const Success(words));

      await repo.getWordsByLesson('L1');
      await repo.getWordsByLesson('L1');

      verify(() => ds.fetchWordsByLesson('L1')).called(1);
    });

    test('forceRefresh bate de novo', () async {
      when(() => ds.fetchWordsByLesson('L1'))
          .thenAnswer((_) async => const Success(words));

      await repo.getWordsByLesson('L1');
      await repo.getWordsByLesson('L1', forceRefresh: true);

      verify(() => ds.fetchWordsByLesson('L1')).called(2);
    });

    test('falha propagada', () async {
      when(() => ds.fetchWordsByLesson('L1'))
          .thenAnswer((_) async => const FailureResult(ServerFailure()));

      final r = await repo.getWordsByLesson('L1');
      expect(r.failureOrNull(), isA<ServerFailure>());
    });
  });
}
