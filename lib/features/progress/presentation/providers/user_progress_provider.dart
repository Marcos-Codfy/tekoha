// lib/features/progress/presentation/providers/user_progress_provider.dart
// Camada: Presentation (Progress).
//
// Provider GLOBAL unico do progresso do usuario (ESP-006). Substitui o
// antigo ProgressProvider em memoria: agora o MESMO estado alimenta
//   - PracticeScreen (trava de modulos por progresso real)
//   - ModuleTrailScreen (nos da trilha + celebracao)
//   - Home e Perfil (XP, streak, licoes)
//   - Sistema de conquistas (avaliacao + registro de desbloqueio)
//
// Fonte de verdade: entidade UserProgress, persistida no Firestore em
// `user_progress/{uid}` via UserProgressRepository. SEM usuario logado
// (uid vazio) o provider opera 100% em memoria — mesma UX, nada salvo.
//
// Resiliencia: falha de rede NUNCA trava a UI. Leitura falhou -> segue
// com estado local; escrita falhou -> estado local mantem e a proxima
// escrita bem-sucedida reenvia o documento inteiro (save e merge do
// doc completo, entao nada se perde de forma silenciosa).

import 'package:flutter/foundation.dart';

import '../../../achievements/domain/entities/achievement.dart';
import '../../../achievements/domain/usecases/get_achievements.dart';
import '../../../lesson/presentation/controllers/lesson_outcome.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/user_progress_repository.dart';
import '../../domain/services/achievement_evaluator.dart';

class UserProgressProvider extends ChangeNotifier {
  final UserProgressRepository _repository;
  final GetAchievementsUseCase _getAchievements;

  /// Fornece o uid do usuario logado NO MOMENTO da chamada. Vazio =
  /// ninguem logado (modo em memoria).
  final String Function() _currentUid;

  UserProgressProvider(
    this._repository,
    this._getAchievements,
    this._currentUid,
  );

  UserProgress _progress = UserProgress.empty;
  List<Achievement> _achievements = const [];
  String? _loadedForUid;

  /// Total de etapas por modulo, registrado pela trilha ao carregar.
  /// Permite detectar "modulo completo" no momento da ultima etapa.
  final Map<String, int> _totalStages = {};

  // ── Getters de leitura pra UI ───────────────────────────────────────

  UserProgress get progress => _progress;
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  int get xp => _progress.xp;
  int get streakDays => _progress.streakDays;

  bool isStageDone(String moduleId, int stageIndex) =>
      _progress.stagesDone(moduleId).contains(stageIndex);

  int doneCount(String moduleId) => _progress.stagesDone(moduleId).length;

  /// Modulo comprovadamente completo (persistido em `modules_done`).
  bool isModuleComplete(String moduleId) =>
      _progress.modulesDone.contains(moduleId);

  /// Indice da proxima etapa a fazer, ou -1 se todas concluidas.
  int nextStageIndex(String moduleId, int totalStages) {
    for (var i = 0; i < totalStages; i++) {
      if (!isStageDone(moduleId, i)) return i;
    }
    return -1;
  }

  bool isAchievementUnlocked(String code) =>
      _progress.unlockedAchievements.containsKey(code);

  int get unlockedCount => _progress.unlockedAchievements.length;

  // ── Ciclo de vida ───────────────────────────────────────────────────

  /// Carrega o progresso do usuario logado (idempotente por uid — chame
  /// a vontade nas telas). Troca de conta refaz a carga.
  Future<void> ensureLoaded() async {
    final uid = _currentUid();
    if (uid.isEmpty) return;
    if (_loadedForUid == uid) return;

    final result = await _repository.fetch(uid);
    result.fold(
      onSuccess: (p) {
        _progress = p;
        _loadedForUid = uid;
        notifyListeners();
      },
      onFailure: (_) {
        // Sem rede no boot: segue com estado local vazio; a proxima
        // chamada de ensureLoaded tenta de novo (uid nao marcado).
      },
    );
    await _ensureAchievementsLoaded();
  }

  /// Zera o estado local ao sair da conta (o Firestore mantem o do
  /// usuario que saiu; o proximo login carrega o dele).
  void clearOnLogout() {
    _progress = UserProgress.empty;
    _loadedForUid = null;
    _totalStages.clear();
    notifyListeners();
  }

  /// Registra quantas etapas a trilha do modulo tem (idempotente).
  void registerTotalStages(String moduleId, int total) {
    if (_totalStages[moduleId] == total) return;
    _totalStages[moduleId] = total;
    notifyListeners();
  }

  // ── Regra de negocio central ────────────────────────────────────────

  /// Registra uma etapa concluida: XP + streak + contadores + deteccao
  /// de modulo completo + avaliacao de conquistas + persistencia.
  /// Devolve as conquistas RECEM-desbloqueadas pra UI celebrar
  /// (Peak-End — Kahneman et al., 1993).
  Future<List<Achievement>> recordStageCompleted({
    required String moduleId,
    required int stageIndex,
    required LessonOutcome outcome,
    DateTime? now,
  }) async {
    final when = now ?? DateTime.now();

    var updated = _progress.afterStageCompleted(
      gainedXp: outcome.xpEarned,
      moduleId: moduleId,
      stageIndex: stageIndex,
      now: when,
      masteredWordIdsInSession: outcome.masteredWordIds,
      speechCorrectInSession: outcome.speechCorrectCount,
    );

    // Fechou a ultima etapa? Marca o modulo (criterio `modules_done`).
    final totalStages = _totalStages[moduleId] ?? 0;
    if (totalStages > 0 &&
        updated.stagesDone(moduleId).length >= totalStages) {
      updated = updated.withModuleDone(moduleId);
    }

    // Avalia conquistas com o estado NOVO.
    await _ensureAchievementsLoaded();
    final newlyUnlocked = AchievementEvaluator.newlyUnlocked(
      achievements: _achievements,
      progress: updated,
    );
    if (newlyUnlocked.isNotEmpty) {
      updated = updated.withAchievementsUnlocked(
        newlyUnlocked.map((a) => a.code),
        when,
      );
    }

    _progress = updated;
    notifyListeners();

    // Persistencia best-effort (doc inteiro, merge no servidor).
    final uid = _currentUid();
    if (uid.isNotEmpty) {
      await _repository.save(uid, updated);
    }

    return newlyUnlocked;
  }

  // ── Interno ─────────────────────────────────────────────────────────

  Future<void> _ensureAchievementsLoaded() async {
    if (_achievements.isNotEmpty) return;
    final result = await _getAchievements();
    result.fold(
      onSuccess: (list) {
        _achievements = list;
        notifyListeners();
      },
      onFailure: (_) {
        // Sem definicoes agora: conquistas simplesmente nao desbloqueiam
        // nesta sessao; proxima chamada tenta de novo.
      },
    );
  }
}
