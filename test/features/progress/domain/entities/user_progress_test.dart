// test/features/progress/domain/entities/user_progress_test.dart
//
// Estrategia: comportamento de afterStageCompleted (acumulo de xp,
// streak, marcacao de etapa, imutabilidade) partindo de empty e de
// estado existente.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/progress/domain/entities/user_progress.dart';

void main() {
  group('UserProgress.afterStageCompleted', () {
    test('usuario novo: primeira etapa soma xp, inicia streak e marca '
        'a etapa', () {
      final updated = UserProgress.empty.afterStageCompleted(
        gainedXp: 42,
        moduleId: 'm1',
        stageIndex: 0,
        now: DateTime(2026, 7, 2, 10),
      );

      expect(updated.xp, 42);
      expect(updated.streakDays, 1);
      expect(updated.lastPracticeAt, DateTime(2026, 7, 2, 10));
      expect(updated.stagesDone('m1'), {0});
    });

    test('acumula xp e etapas sobre estado existente sem perder nada', () {
      final base = UserProgress(
        xp: 100,
        streakDays: 2,
        lastPracticeAt: DateTime(2026, 7, 1, 20),
        stagesDoneByModule: const {
          'm1': {0, 1},
        },
      );

      final updated = base.afterStageCompleted(
        gainedXp: 38,
        moduleId: 'm1',
        stageIndex: 2,
        now: DateTime(2026, 7, 2, 9),
      );

      expect(updated.xp, 138);
      expect(updated.streakDays, 3); // dia seguinte -> +1
      expect(updated.stagesDone('m1'), {0, 1, 2});
    });

    test('etapa de outro modulo nao mistura com o primeiro', () {
      final updated = UserProgress.empty
          .afterStageCompleted(
            gainedXp: 10,
            moduleId: 'm1',
            stageIndex: 0,
            now: DateTime(2026, 7, 2),
          )
          .afterStageCompleted(
            gainedXp: 10,
            moduleId: 'm2',
            stageIndex: 0,
            now: DateTime(2026, 7, 2),
          );

      expect(updated.stagesDone('m1'), {0});
      expect(updated.stagesDone('m2'), {0});
      expect(updated.stagesDone('m3'), isEmpty);
    });

    test('nao muta o estado original (imutabilidade)', () {
      final base = UserProgress(
        xp: 50,
        streakDays: 1,
        lastPracticeAt: DateTime(2026, 7, 1),
        stagesDoneByModule: const {
          'm1': {0},
        },
      );

      base.afterStageCompleted(
        gainedXp: 10,
        moduleId: 'm1',
        stageIndex: 1,
        now: DateTime(2026, 7, 2),
      );

      expect(base.xp, 50);
      expect(base.stagesDone('m1'), {0});
    });

    test('stagesDone devolve copia defensiva', () {
      const progress = UserProgress(
        xp: 0,
        streakDays: 0,
        lastPracticeAt: null,
        stagesDoneByModule: {
          'm1': {0},
        },
      );

      progress.stagesDone('m1').add(99);

      expect(progress.stagesDone('m1'), {0});
    });
  });
}
