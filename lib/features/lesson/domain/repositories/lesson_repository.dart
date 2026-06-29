// lib/features/lesson/domain/repositories/lesson_repository.dart
// Camada: Domain (Lesson).
//
// CONTRATO do repositorio da feature Lesson. Quem implementa decide a
// fonte (Airtable, Firestore, mock).

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/lesson.dart';
import '../entities/word.dart';

abstract class LessonRepository {
  /// Busca todas as licoes do modulo [moduleId], ordenadas por `order`.
  Future<Result<List<Lesson>, Failure>> getLessonsByModule(
    String moduleId, {
    bool forceRefresh = false,
  });

  /// Busca todas as palavras da licao [lessonId], ordenadas por `order`.
  Future<Result<List<Word>, Failure>> getWordsByLesson(
    String lessonId, {
    bool forceRefresh = false,
  });
}
