// lib/features/practice/presentation/providers/progress_provider.dart
// Camada: Presentation (Practice).
//
// ChangeNotifier GLOBAL (registrado no MultiProvider do main) que
// espelha o progresso da trilha pra UI. Duas telas dependem dele:
//   - PracticeScreen: trava modulo N ate o N-1 estar completo
//   - ModuleTrailScreen: estado dos nos (concluida/atual/travada)
//
// Mantem cache local dos Sets por modulo pra leitura sincrona nos
// builds; toda escrita passa pelo ProgressRepository (contrato) e
// recarrega o cache — quando a impl virar Firestore, nada muda aqui.

import 'package:flutter/foundation.dart';

import '../../domain/repositories/progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _repository;

  ProgressProvider(this._repository);

  final Map<String, Set<int>> _cache = {};

  /// Carrega (ou recarrega) o progresso de um modulo pro cache.
  /// Com a impl em memoria e instantaneo; com impl remota futura, a UI
  /// mostra estado "sem progresso" ate o load completar e notificar.
  Future<void> loadModule(String moduleId) async {
    _cache[moduleId] = await _repository.doneStages(moduleId);
    notifyListeners();
  }

  bool isStageDone(String moduleId, int stageIndex) =>
      _cache[moduleId]?.contains(stageIndex) ?? false;

  int doneCount(String moduleId) => _cache[moduleId]?.length ?? 0;

  /// Modulo completo = todas as [totalStages] etapas concluidas.
  bool isModuleDone(String moduleId, int totalStages) =>
      totalStages > 0 && doneCount(moduleId) >= totalStages;

  // ── Total de etapas por modulo ────────────────────────────────────
  // Registrado pela ModuleTrailScreen quando a trilha carrega. Permite
  // que a PracticeScreen (que nao conhece as palavras) responda
  // "o modulo anterior foi completado?" pra travar/destravar modulos.

  final Map<String, int> _totalStages = {};

  /// Registra quantas etapas a trilha do modulo tem. Idempotente — so
  /// notifica quando o valor muda.
  void registerTotalStages(String moduleId, int total) {
    if (_totalStages[moduleId] == total) return;
    _totalStages[moduleId] = total;
    notifyListeners();
  }

  /// Modulo comprovadamente completo: o total de etapas e conhecido
  /// (a trilha ja foi aberta ao menos uma vez) E todas foram feitas.
  /// Modulo nunca visitado = incompleto por definicao.
  bool isModuleComplete(String moduleId) {
    final total = _totalStages[moduleId];
    return total != null && isModuleDone(moduleId, total);
  }

  /// Indice da proxima etapa a fazer (primeira nao concluida), ou -1
  /// se todas as [totalStages] etapas ja foram concluidas.
  int nextStageIndex(String moduleId, int totalStages) {
    for (var i = 0; i < totalStages; i++) {
      if (!isStageDone(moduleId, i)) return i;
    }
    return -1;
  }

  Future<void> markStageDone(String moduleId, int stageIndex) async {
    await _repository.markStageDone(moduleId, stageIndex);
    _cache[moduleId] = await _repository.doneStages(moduleId);
    notifyListeners();
  }
}
