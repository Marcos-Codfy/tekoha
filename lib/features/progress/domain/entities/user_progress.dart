// lib/features/progress/domain/entities/user_progress.dart
// Camada: Domain (Progress).
//
// Entidade pura do progresso de UM usuario logado (ESP-006). Espelha o
// documento `user_progress/{uid}` do Firestore (regras de seguranca ja
// publicadas: cada usuario so acessa o proprio documento).
//
// Alem de xp/streak/etapas, acumula os contadores que alimentam as
// CONQUISTAS (modulos completos, palavras dominadas, falas corretas e
// o registro do que ja foi desbloqueado).

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

  /// IDs dos modulos com TODAS as etapas concluidas (registrado pela
  /// trilha no momento da celebracao — criterio `modules_done`).
  final Set<String> modulesDone;

  /// IDs unicos de palavras "dominadas" (acertou de primeira, sem erro).
  /// Set de IDs (nao contador) evita contagem dupla ao refazer etapas.
  final Set<String> masteredWordIds;

  /// Total acumulado de exercicios de fala corretos (criterio
  /// `speech_correct`).
  final int speechCorrectTotal;

  /// Conquistas desbloqueadas: code -> momento do desbloqueio.
  final Map<String, DateTime> unlockedAchievements;

  const UserProgress({
    required this.xp,
    required this.streakDays,
    required this.lastPracticeAt,
    required this.stagesDoneByModule,
    this.modulesDone = const {},
    this.masteredWordIds = const {},
    this.speechCorrectTotal = 0,
    this.unlockedAchievements = const {},
  });

  /// Progresso zerado — estado de um usuario novo.
  static const empty = UserProgress(
    xp: 0,
    streakDays: 0,
    lastPracticeAt: null,
    stagesDoneByModule: {},
  );

  /// Total de etapas concluidas somando todos os modulos (criterio
  /// `stages_done`).
  int get totalStagesDone =>
      stagesDoneByModule.values.fold(0, (t, s) => t + s.length);

  /// Novo estado apos concluir uma etapa da trilha: soma o XP ganho,
  /// atualiza o streak, marca a etapa e acumula os contadores de
  /// conquistas da sessao. Funcao pura — quem persiste e o repositorio.
  UserProgress afterStageCompleted({
    required int gainedXp,
    required String moduleId,
    required int stageIndex,
    required DateTime now,
    Set<String> masteredWordIdsInSession = const {},
    int speechCorrectInSession = 0,
  }) {
    final updatedStages = <String, Set<int>>{
      for (final entry in stagesDoneByModule.entries)
        entry.key: {...entry.value},
    };
    updatedStages.putIfAbsent(moduleId, () => <int>{}).add(stageIndex);

    return _copyWith(
      xp: xp + gainedXp,
      streakDays: StreakCalculator.nextStreak(
        currentStreak: streakDays,
        lastPracticeAt: lastPracticeAt,
        now: now,
      ),
      lastPracticeAt: now,
      stagesDoneByModule: updatedStages,
      masteredWordIds: {...masteredWordIds, ...masteredWordIdsInSession},
      speechCorrectTotal: speechCorrectTotal + speechCorrectInSession,
    );
  }

  /// Marca um modulo como totalmente concluido (chamado pela trilha
  /// quando a ultima etapa fecha).
  UserProgress withModuleDone(String moduleId) =>
      _copyWith(modulesDone: {...modulesDone, moduleId});

  /// Registra conquistas recem-desbloqueadas (idempotente — codigos ja
  /// registrados mantem a data original).
  UserProgress withAchievementsUnlocked(
    Iterable<String> codes,
    DateTime now,
  ) {
    final updated = {...unlockedAchievements};
    for (final code in codes) {
      updated.putIfAbsent(code, () => now);
    }
    return _copyWith(unlockedAchievements: updated);
  }

  /// Etapas concluidas de um modulo (conjunto vazio se nenhum registro).
  Set<int> stagesDone(String moduleId) =>
      {...(stagesDoneByModule[moduleId] ?? const <int>{})};

  UserProgress _copyWith({
    int? xp,
    int? streakDays,
    DateTime? lastPracticeAt,
    Map<String, Set<int>>? stagesDoneByModule,
    Set<String>? modulesDone,
    Set<String>? masteredWordIds,
    int? speechCorrectTotal,
    Map<String, DateTime>? unlockedAchievements,
  }) =>
      UserProgress(
        xp: xp ?? this.xp,
        streakDays: streakDays ?? this.streakDays,
        lastPracticeAt: lastPracticeAt ?? this.lastPracticeAt,
        stagesDoneByModule: stagesDoneByModule ?? this.stagesDoneByModule,
        modulesDone: modulesDone ?? this.modulesDone,
        masteredWordIds: masteredWordIds ?? this.masteredWordIds,
        speechCorrectTotal: speechCorrectTotal ?? this.speechCorrectTotal,
        unlockedAchievements:
            unlockedAchievements ?? this.unlockedAchievements,
      );

  @override
  String toString() =>
      'UserProgress(xp: $xp, streakDays: $streakDays, '
      'etapas: $totalStagesDone, modulos: ${modulesDone.length}, '
      'conquistas: ${unlockedAchievements.length})';
}
