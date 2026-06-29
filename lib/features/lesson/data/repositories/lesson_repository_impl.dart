// lib/features/lesson/data/repositories/lesson_repository_impl.dart
// Camada: Data (Lesson).
//
// Implementacao concreta com cache em memoria por moduleId e lessonId.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/word.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../datasources/lesson_remote_datasource.dart';
import '../mappers/lesson_mapper.dart';
import '../mappers/word_mapper.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonRemoteDataSource _remote;

  final Map<String, List<Lesson>> _lessonsByModule = {};
  final Map<String, List<Word>> _wordsByLesson = {};

  LessonRepositoryImpl(this._remote);

  @override
  Future<Result<List<Lesson>, Failure>> getLessonsByModule(
    String moduleId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _lessonsByModule.containsKey(moduleId)) {
      return Success(_lessonsByModule[moduleId]!);
    }

    final dtoResult = await _remote.fetchLessonsByModule(moduleId);
    return dtoResult.fold(
      onSuccess: (dtos) {
        final lessons = LessonMapper.toEntityList(dtos);
        _lessonsByModule[moduleId] = lessons;
        return Success(lessons);
      },
      onFailure: (f) => FailureResult(f),
    );
  }

  @override
  Future<Result<List<Word>, Failure>> getWordsByLesson(
    String lessonId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _wordsByLesson.containsKey(lessonId)) {
      return Success(_wordsByLesson[lessonId]!);
    }

    final dtoResult = await _remote.fetchWordsByLesson(lessonId);
    return dtoResult.fold(
      onSuccess: (dtos) {
        final words = WordMapper.toEntityList(dtos);
        _wordsByLesson[lessonId] = words;
        return Success(words);
      },
      onFailure: (f) => FailureResult(f),
    );
  }
}
