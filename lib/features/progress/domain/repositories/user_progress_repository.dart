// lib/features/progress/domain/repositories/user_progress_repository.dart
// Camada: Domain (Progress).
//
// CONTRATO de persistencia do progresso do usuario logado (ESP-006).
// A impl de producao e Firestore (data/); em testes usa-se mock.
//
// Granularidade grossa de proposito (fetch/save do documento inteiro):
// o volume de dados e minusculo (1 doc por usuario) e isso simplifica
// merge de estado no MVP. Se um dia houver escrita concorrente real,
// evoluir pra operacoes atomicas por campo.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/user_progress.dart';

abstract class UserProgressRepository {
  /// Progresso do usuario [uid]. Usuario sem documento ainda (primeiro
  /// acesso) devolve [UserProgress.empty] — nao e erro.
  Future<Result<UserProgress, Failure>> fetch(String uid);

  /// Persiste o progresso inteiro do usuario [uid] (merge no servidor).
  Future<Result<void, Failure>> save(String uid, UserProgress progress);
}
