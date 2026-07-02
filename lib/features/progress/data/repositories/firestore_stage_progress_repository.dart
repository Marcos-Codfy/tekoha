// lib/features/progress/data/repositories/firestore_stage_progress_repository.dart
// Camada: Data (Progress).
//
// ADAPTER: implementa o contrato ProgressRepository da feature Practice
// (trilha de etapas — ESP-005) por cima do documento user_progress do
// Firestore. E a peca que torna a troca "memoria -> nuvem" um swap de
// UMA linha no injection.dart quando o login for reativado:
//
//   sl.registerLazySingleton<ProgressRepository>(
//     () => FirestoreStageProgressRepository(
//       sl<FirestoreProgressDataSource>(),
//       () => FirebaseAuth.instance.currentUser?.uid ?? '',
//     ),
//   );
//
// Comportamento sem usuario logado (uid vazio): le como "sem progresso"
// e ignora escritas — a UI continua funcionando igual a impl em memoria.

import '../../../practice/domain/repositories/progress_repository.dart';
import '../datasources/firestore_progress_datasource.dart';
import '../dtos/user_progress_dto.dart';

class FirestoreStageProgressRepository implements ProgressRepository {
  final FirestoreProgressDataSource _dataSource;

  /// Fornece o uid do usuario logado no momento da chamada (nao no
  /// registro do DI) — troca de conta nao exige recriar o repositorio.
  final String Function() _currentUid;

  FirestoreStageProgressRepository(this._dataSource, this._currentUid);

  @override
  Future<Set<int>> doneStages(String moduleId) async {
    final uid = _currentUid();
    if (uid.isEmpty) return const <int>{};
    try {
      final dto = UserProgressDto.fromMap(await _dataSource.fetch(uid));
      return (dto.stagesDone[moduleId] ?? const <int>[]).toSet();
    } catch (_) {
      // Falha de rede aqui nao pode travar a trilha — degrada pra
      // "sem progresso" e a UI segue navegavel.
      return const <int>{};
    }
  }

  @override
  Future<void> markStageDone(String moduleId, int stageIndex) async {
    final uid = _currentUid();
    if (uid.isEmpty) return;
    try {
      final dto = UserProgressDto.fromMap(await _dataSource.fetch(uid));
      final updated = <String, List<int>>{...dto.stagesDone};
      final stages = {...(updated[moduleId] ?? const <int>[]), stageIndex};
      updated[moduleId] = stages.toList()..sort();
      await _dataSource.save(uid, {'stages_done': updated});
    } catch (_) {
      // Escrita perdida por falha de rede: o usuario refaz a etapa.
      // Aceitavel no MVP; retry/fila offline e evolucao futura.
    }
  }
}
