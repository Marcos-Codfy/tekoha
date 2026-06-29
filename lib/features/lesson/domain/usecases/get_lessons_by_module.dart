// lib/features/lesson/domain/usecases/get_lessons_by_module.dart
// Camada: Domain (Lesson).

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/lesson.dart';
import '../repositories/lesson_repository.dart';

class GetLessonsByModuleUseCase {
  final LessonRepository _repository;

  const GetLessonsByModuleUseCase(this._repository);

  Future<Result<List<Lesson>, Failure>> call(
    String moduleId, {
    bool forceRefresh = false,
  }) =>
      _repository.getLessonsByModule(moduleId, forceRefresh: forceRefresh);
}
