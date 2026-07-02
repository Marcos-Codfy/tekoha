// lib/features/practice/data/repositories/in_memory_progress_repository.dart
// Camada: Data (Practice).
//
// Implementacao EM MEMORIA do ProgressRepository — o progresso da
// trilha vive so na sessao atual e zera ao fechar o app. Decisao de
// escopo do MVP (ESP-005): persistencia real (XP, streak, conquistas)
// entra na proxima fase, trocando esta impl no injection.dart.

import '../../domain/repositories/progress_repository.dart';

class InMemoryProgressRepository implements ProgressRepository {
  /// moduleId -> indices de etapas concluidas.
  final Map<String, Set<int>> _done = {};

  @override
  Future<Set<int>> doneStages(String moduleId) async =>
      {...(_done[moduleId] ?? const <int>{})};

  @override
  Future<void> markStageDone(String moduleId, int stageIndex) async {
    _done.putIfAbsent(moduleId, () => <int>{}).add(stageIndex);
  }
}
