// test/features/progress/domain/services/achievement_evaluator_test.dart
//
// Estrategia: cada criterion_type com caso de cumpre/nao cumpre,
// conquista ja desbloqueada nao repete, inativa nao conta, unknown
// nunca desbloqueia, ordenacao por order.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/achievements/domain/entities/achievement.dart';
import 'package:tekoha/features/progress/domain/entities/user_progress.dart';
import 'package:tekoha/features/progress/domain/services/achievement_evaluator.dart';

Achievement _a(
  String code,
  AchievementCriterionType type,
  int value, {
  int order = 1,
  bool active = true,
}) =>
    Achievement(
      id: 'rec_$code',
      code: code,
      title: code,
      description: '',
      lockedHint: '',
      criterionType: type,
      criterionValue: value,
      iconUrl: '',
      order: order,
      isActive: active,
    );

void main() {
  group('AchievementEvaluator.meets — um caso por criterio', () {
    test('stages_done conta etapas de TODOS os modulos', () {
      const progress = UserProgress(
        xp: 0,
        streakDays: 0,
        lastPracticeAt: null,
        stagesDoneByModule: {
          'm1': {0, 1},
          'm2': {0},
        },
      );

      expect(
        AchievementEvaluator.meets(
            _a('x', AchievementCriterionType.stagesDone, 3), progress),
        isTrue,
      );
      expect(
        AchievementEvaluator.meets(
            _a('x', AchievementCriterionType.stagesDone, 4), progress),
        isFalse,
      );
    });

    test('modules_done, xp_total, streak_days, words_mastered e '
        'speech_correct comparam com >=', () {
      const progress = UserProgress(
        xp: 100,
        streakDays: 3,
        lastPracticeAt: null,
        stagesDoneByModule: {},
        modulesDone: {'m1'},
        masteredWordIds: {'w1', 'w2'},
        speechCorrectTotal: 10,
      );

      expect(
        AchievementEvaluator.meets(
            _a('a', AchievementCriterionType.modulesDone, 1), progress),
        isTrue,
      );
      expect(
        AchievementEvaluator.meets(
            _a('b', AchievementCriterionType.xpTotal, 100), progress),
        isTrue,
      );
      expect(
        AchievementEvaluator.meets(
            _a('c', AchievementCriterionType.streakDays, 4), progress),
        isFalse,
      );
      expect(
        AchievementEvaluator.meets(
            _a('d', AchievementCriterionType.wordsMastered, 2), progress),
        isTrue,
      );
      expect(
        AchievementEvaluator.meets(
            _a('e', AchievementCriterionType.speechCorrect, 11), progress),
        isFalse,
      );
    });

    test('criterion_type unknown nunca desbloqueia (forward-compat)', () {
      expect(
        AchievementEvaluator.meets(
          _a('x', AchievementCriterionType.unknown, 0),
          UserProgress.empty,
        ),
        isFalse,
      );
    });
  });

  group('AchievementEvaluator.newlyUnlocked', () {
    final progress = UserProgress.empty
        .afterStageCompleted(
          gainedXp: 120,
          moduleId: 'm1',
          stageIndex: 0,
          now: DateTime(2026, 7, 2),
        )
        .withAchievementsUnlocked(['ja_tinha'], DateTime(2026, 7, 1));

    test('devolve so as conquistas que passaram a cumprir o criterio '
        'e ainda nao estavam desbloqueadas', () {
      final unlocked = AchievementEvaluator.newlyUnlocked(
        achievements: [
          _a('first_stage', AchievementCriterionType.stagesDone, 1,
              order: 1),
          _a('xp_100', AchievementCriterionType.xpTotal, 100, order: 2),
          _a('xp_500', AchievementCriterionType.xpTotal, 500, order: 3),
          _a('ja_tinha', AchievementCriterionType.stagesDone, 1, order: 4),
        ],
        progress: progress,
      );

      expect(unlocked.map((a) => a.code), ['first_stage', 'xp_100']);
    });

    test('conquista inativa nao desbloqueia mesmo cumprindo criterio', () {
      final unlocked = AchievementEvaluator.newlyUnlocked(
        achievements: [
          _a('off', AchievementCriterionType.stagesDone, 1, active: false),
        ],
        progress: progress,
      );

      expect(unlocked, isEmpty);
    });

    test('resultado vem ordenado por order (celebracao estavel)', () {
      final unlocked = AchievementEvaluator.newlyUnlocked(
        achievements: [
          _a('b', AchievementCriterionType.xpTotal, 50, order: 9),
          _a('a', AchievementCriterionType.stagesDone, 1, order: 2),
        ],
        progress: progress,
      );

      expect(unlocked.map((a) => a.code), ['a', 'b']);
    });
  });

  group('UserProgress — novos acumuladores', () {
    test('afterStageCompleted acumula palavras dominadas sem duplicar '
        'e soma falas corretas', () {
      final progress = UserProgress.empty
          .afterStageCompleted(
            gainedXp: 10,
            moduleId: 'm1',
            stageIndex: 0,
            now: DateTime(2026, 7, 2),
            masteredWordIdsInSession: {'w1', 'w2'},
            speechCorrectInSession: 2,
          )
          .afterStageCompleted(
            gainedXp: 10,
            moduleId: 'm1',
            stageIndex: 1,
            now: DateTime(2026, 7, 2),
            masteredWordIdsInSession: {'w2', 'w3'},
            speechCorrectInSession: 3,
          );

      expect(progress.masteredWordIds, {'w1', 'w2', 'w3'});
      expect(progress.speechCorrectTotal, 5);
    });

    test('withModuleDone e withAchievementsUnlocked sao idempotentes', () {
      final t1 = DateTime(2026, 7, 1);
      final t2 = DateTime(2026, 7, 2);
      final progress = UserProgress.empty
          .withModuleDone('m1')
          .withModuleDone('m1')
          .withAchievementsUnlocked(['a'], t1)
          .withAchievementsUnlocked(['a', 'b'], t2);

      expect(progress.modulesDone, {'m1'});
      // 'a' mantem a data original do primeiro desbloqueio.
      expect(progress.unlockedAchievements['a'], t1);
      expect(progress.unlockedAchievements['b'], t2);
    });
  });
}
