// lib/features/achievements/domain/repositories/achievements_repository.dart
// Camada: Domain (Achievements).
//
// Contrato de acesso as definicoes de conquistas.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/achievement.dart';

abstract class AchievementsRepository {
  /// Conquistas ativas, ordenadas por `order`. Cache em memoria na
  /// impl — definicoes mudam raramente.
  Future<Result<List<Achievement>, Failure>> getAchievements({
    bool forceRefresh = false,
  });
}
