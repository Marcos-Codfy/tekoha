// test/features/progress/presentation/providers/user_progress_provider_test.dart
//
// Estrategia: repositorio e usecase de conquistas mockados (mocktail).
// Cobre o ciclo central da ESP-006: carga por uid, registro de etapa
// (xp/streak/contadores), deteccao de modulo completo, desbloqueio de
// conquista, persistencia best-effort e modo sem login (uid vazio).

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/achievements/domain/entities/achievement.dart';
import 'package:tekoha/features/achievements/domain/usecases/get_achievements.dart';
import 'package:tekoha/features/lesson/presentation/controllers/lesson_outcome.dart';
import 'package:tekoha/features/progress/domain/entities/user_progress.dart';
import 'package:tekoha/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:tekoha/features/progress/presentation/providers/user_progress_provider.dart';

class _MockRepo extends Mock implements UserProgressRepository {}

class _MockGetAchievements extends Mock implements GetAchievementsUseCase {}

Achievement _a(String code, AchievementCriterionType type, int value) =>
    Achievement(
      id: 'rec_$code',
      code: code,
      title: code,
      description: '',
      lockedHint: '',
      criterionType: type,
      criterionValue: value,
      iconUrl: '',
      order: 1,
      isActive: true,
    );

const _outcome = LessonOutcome(
  xpEarned: 40,
  masteredWordIds: {'w1', 'w2'},
  speechCorrectCount: 3,
);

void main() {
  late _MockRepo repo;
  late _MockGetAchievements getAchievements;
  String uid = 'u1';

  setUpAll(() {
    registerFallbackValue(UserProgress.empty);
  });

  setUp(() {
    repo = _MockRepo();
    getAchievements = _MockGetAchievements();
    uid = 'u1';

    when(() => repo.fetch(any())).thenAnswer(
      (_) async => const Success(UserProgress.empty),
    );
    when(() => repo.save(any(), any())).thenAnswer(
      (_) async => const Success(null),
    );
    when(() => getAchievements(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success(<Achievement>[]));
    when(() => getAchievements()).thenAnswer(
      (_) async => const Success(<Achievement>[]),
    );
  });

  UserProgressProvider provider() =>
      UserProgressProvider(repo, getAchievements, () => uid);

  group('ensureLoaded', () {
    test('carrega o progresso do uid logado uma unica vez', () async {
      final p = provider();
      await p.ensureLoaded();
      await p.ensureLoaded();

      verify(() => repo.fetch('u1')).called(1);
    });

    test('sem login (uid vazio) nao toca o repositorio', () async {
      uid = '';
      await provider().ensureLoaded();

      verifyNever(() => repo.fetch(any()));
    });

    test('progresso persistido alimenta as travas de modulo', () async {
      when(() => repo.fetch('u1')).thenAnswer(
        (_) async => Success(
          UserProgress.empty.withModuleDone('m1'),
        ),
      );

      final p = provider();
      await p.ensureLoaded();

      expect(p.isModuleComplete('m1'), isTrue);
      expect(p.isModuleComplete('m2'), isFalse);
    });
  });

  group('recordStageCompleted', () {
    test('atualiza xp, streak, etapa e contadores e persiste', () async {
      final p = provider();
      await p.ensureLoaded();

      await p.recordStageCompleted(
        moduleId: 'm1',
        stageIndex: 0,
        outcome: _outcome,
        now: DateTime(2026, 7, 2, 10),
      );

      expect(p.xp, 40);
      expect(p.streakDays, 1);
      expect(p.isStageDone('m1', 0), isTrue);
      expect(p.progress.masteredWordIds, {'w1', 'w2'});
      expect(p.progress.speechCorrectTotal, 3);
      verify(() => repo.save('u1', any())).called(1);
    });

    test('ultima etapa do modulo marca modules_done', () async {
      final p = provider();
      await p.ensureLoaded();
      p.registerTotalStages('m1', 2);

      await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 0, outcome: _outcome);
      expect(p.isModuleComplete('m1'), isFalse);

      await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 1, outcome: _outcome);
      expect(p.isModuleComplete('m1'), isTrue);
    });

    test('desbloqueia conquista quando o criterio passa a ser cumprido '
        'e devolve pra UI celebrar', () async {
      when(() => getAchievements()).thenAnswer(
        (_) async => Success([
          _a('first_stage', AchievementCriterionType.stagesDone, 1),
          _a('xp_500', AchievementCriterionType.xpTotal, 500),
        ]),
      );

      final p = provider();
      await p.ensureLoaded();

      final newly = await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 0, outcome: _outcome);

      expect(newly.map((a) => a.code), ['first_stage']);
      expect(p.isAchievementUnlocked('first_stage'), isTrue);
      expect(p.isAchievementUnlocked('xp_500'), isFalse);

      // Repetir a etapa NAO desbloqueia de novo.
      final again = await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 0, outcome: _outcome);
      expect(again, isEmpty);
    });

    test('sem login: estado local atualiza e nada e salvo', () async {
      uid = '';
      final p = provider();

      await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 0, outcome: _outcome);

      expect(p.xp, 40);
      verifyNever(() => repo.save(any(), any()));
    });

    test('falha ao salvar nao perde o estado local (best-effort)',
        () async {
      when(() => repo.save(any(), any())).thenAnswer(
        (_) async => const FailureResult(NetworkFailure()),
      );

      final p = provider();
      await p.ensureLoaded();
      await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 0, outcome: _outcome);

      expect(p.xp, 40);
      expect(p.isStageDone('m1', 0), isTrue);
    });
  });

  group('clearOnLogout', () {
    test('zera o estado local e permite carga do proximo usuario',
        () async {
      final p = provider();
      await p.ensureLoaded();
      await p.recordStageCompleted(
          moduleId: 'm1', stageIndex: 0, outcome: _outcome);

      p.clearOnLogout();

      expect(p.xp, 0);
      expect(p.isStageDone('m1', 0), isFalse);

      uid = 'u2';
      await p.ensureLoaded();
      verify(() => repo.fetch('u2')).called(1);
    });
  });
}
