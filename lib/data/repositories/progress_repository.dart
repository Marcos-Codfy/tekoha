// lib/data/repositories/progress_repository.dart
// CONTRATO para salvar e buscar o progresso do usuÃ¡rio
// ResponsÃ¡vel: Marcos

import '../models/user_progress_model.dart';

abstract class ProgressRepository {
  Future<UserProgressModel?> getUserProgress(String userId);
  Future<void> saveProgress(UserProgressModel progress);
  Future<void> addXp(String userId, int xpAmount);
  Future<void> markLessonCompleted(String userId, String lessonId);
}
