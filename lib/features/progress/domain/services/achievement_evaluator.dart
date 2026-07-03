// lib/features/progress/domain/services/achievement_evaluator.dart
// Camada: Domain (Progress). Funcao pura — sem Flutter, sem IO.
//
// Avalia quais conquistas o usuario ACABOU de desbloquear comparando
// as definicoes (Airtable) com o estado do progresso (Firestore).
//
// Regras de negocio (ESP-006 / doc 07 do Material Base):
//   - So conquistas ativas contam.
//   - Conquista ja desbloqueada nunca "des-desbloqueia" (o streak pode
//     cair depois; o badge fica — padrao da industria e coerente com o
//     tom sem punicao do app, Pekrun 2006).
//   - criterion_type desconhecido nunca desbloqueia (forward-compat
//     com valores novos criados no Airtable antes do codigo).

import '../../../achievements/domain/entities/achievement.dart';
import '../entities/user_progress.dart';

class AchievementEvaluator {
  AchievementEvaluator._();

  /// Conquistas que passaram a cumprir o criterio AGORA (nao estavam
  /// no `unlockedAchievements` do [progress]). Ordenadas por `order`
  /// pra celebracao em sequencia estavel.
  static List<Achievement> newlyUnlocked({
    required List<Achievement> achievements,
    required UserProgress progress,
  }) {
    final unlocked = achievements
        .where((a) =>
            a.isActive &&
            !progress.unlockedAchievements.containsKey(a.code) &&
            meets(a, progress))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return unlocked;
  }

  /// O progresso atual cumpre o criterio da conquista?
  static bool meets(Achievement achievement, UserProgress progress) {
    final value = achievement.criterionValue;
    switch (achievement.criterionType) {
      case AchievementCriterionType.stagesDone:
        return progress.totalStagesDone >= value;
      case AchievementCriterionType.modulesDone:
        return progress.modulesDone.length >= value;
      case AchievementCriterionType.xpTotal:
        return progress.xp >= value;
      case AchievementCriterionType.streakDays:
        return progress.streakDays >= value;
      case AchievementCriterionType.wordsMastered:
        return progress.masteredWordIds.length >= value;
      case AchievementCriterionType.speechCorrect:
        return progress.speechCorrectTotal >= value;
      case AchievementCriterionType.unknown:
        return false;
    }
  }
}
