// lib/features/practice/domain/repositories/progress_repository.dart
// Camada: Domain (Practice).
//
// CONTRATO de persistencia do progresso da trilha (etapas concluidas
// por modulo). O app inteiro so conhece esta interface — a impl atual
// e em memoria (MVP, progresso vive na sessao); a Sprint de
// persistencia troca por Firestore/local SEM tocar em UI ou providers,
// so registrando outra impl no injection.dart.
//
// Metodos sao assincronos DE PROPOSITO: implementacoes futuras (rede,
// disco) precisam de Future, e mudar assinatura depois seria retrabalho.

abstract class ProgressRepository {
  /// Indices (0-based) das etapas ja concluidas do modulo.
  Future<Set<int>> doneStages(String moduleId);

  /// Marca uma etapa do modulo como concluida (idempotente).
  Future<void> markStageDone(String moduleId, int stageIndex);
}
