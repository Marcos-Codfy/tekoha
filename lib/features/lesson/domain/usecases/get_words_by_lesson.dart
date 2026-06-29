// lib/features/lesson/domain/usecases/get_words_by_lesson.dart
// Camada: Domain (Lesson).

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/word.dart';
import '../repositories/lesson_repository.dart';

class GetWordsByLessonUseCase {
  final LessonRepository _repository;

  const GetWordsByLessonUseCase(this._repository);

  Future<Result<List<Word>, Failure>> call(
    String lessonId, {
    bool forceRefresh = false,
  }) =>
      _repository.getWordsByLesson(lessonId, forceRefresh: forceRefresh);
}
