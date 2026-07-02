// lib/features/progress/domain/entities/user_progress.dart
// Camada: Domain (Progress).
//
// Entidade pura do progresso de UM usuario logado (ESP-006). Espelha o
// documento `user_progress/{uid}` do Firestore (regras de seguranca ja
// publicadas: cada usuario so acessa o proprio documento).
//
// ESTRUTURA PRONTA, AINDA INATIVA: o app hoje roda com kBypassAuth =
// true e progresso em memoria. Quando o login for reativado, esta
// entidade vira a fonte de verdade persistida.

import '../services/streak_calculator.dart';

class UserProgress {
  /// XP acumulado de todas as sessoes.
  final int xp;

  /// Dias consecutivos de pratica (ver [StreakCalculator]).
  final int streakDays;

  /// Momento da ultima pratica concluida. Null = nunca praticou.
  final DateTime? lastPracticeAt;

  /// Etapas da trilha concluidas, por modulo:
  /// { moduleId: {0, 1, 2} } (indices 0-based das etapas).
  final Map<String, Set<int>> stagesDoneByModule;

  const UserProgress({
    required this.xp,
    required this.streakDays,
    required this.lastPracticeAt,
    required this.stagesDoneByModule,
  });

  /// Progresso zerado — estado de um usuario novo.
  static const empty = UserProgress(
    xp: 0,
    streakDays: 0,
    lastPracticeAt: null,
    stagesDoneByModule: {},
  );

  /// Novo estado apos concluir uma etapa da trilha: soma o XP ganho,
  /// atualiza o streak e marca a etapa como feita. Funcao pura — quem
  /// persiste e o repositorio.
  UserProgress afterStageCompleted({
    required int gainedXp,
    required String moduleId,
    required int stageIndex,
    required DateTime now,
  }) {
    final updatedStages = <String, Set<int>>{
      for (final entry in stagesDoneByModule.entries)
        entry.key: {...entry.value},
    };
    updatedStages.putIfAbsent(moduleId, () => <int>{}).add(stageIndex);

    return UserProgress(
      xp: xp + gainedXp,
      streakDays: StreakCalculator.nextStreak(
        currentStreak: streakDays,
        lastPracticeAt: lastPracticeAt,
        now: now,
      ),
      lastPracticeAt: now,
      stagesDoneByModule: updatedStages,
    );
  }

  /// Etapas concluidas de um modulo (conjunto vazio se nenhum registro).
  Set<int> stagesDone(String moduleId) =>
      {...(stagesDoneByModule[moduleId] ?? const <int>{})};

  @override
  String toString() =>
      'UserProgress(xp: $xp, streakDays: $streakDays, '
      'lastPracticeAt: $lastPracticeAt, '
      'modulesComEtapas: ${stagesDoneByModule.length})';
}
