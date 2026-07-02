// lib/features/progress/data/repositories/user_progress_repository_impl.dart
// Camada: Data (Progress).
//
// Implementacao Firestore do contrato UserProgressRepository.
// Converte excecoes do Firebase em Failures tipadas (padrao do projeto).

import 'package:firebase_core/firebase_core.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/repositories/user_progress_repository.dart';
import '../datasources/firestore_progress_datasource.dart';
import '../dtos/user_progress_dto.dart';
import '../mappers/user_progress_mapper.dart';

class UserProgressRepositoryImpl implements UserProgressRepository {
  final FirestoreProgressDataSource _dataSource;

  UserProgressRepositoryImpl(this._dataSource);

  @override
  Future<Result<UserProgress, Failure>> fetch(String uid) async {
    if (uid.isEmpty) {
      return const FailureResult(
        AuthApiFailure(
          'Você precisa estar logado pra carregar seu progresso.',
          'fetch chamado com uid vazio (usuario nao autenticado)',
        ),
      );
    }
    try {
      final map = await _dataSource.fetch(uid);
      // Documento inexistente = usuario novo -> progresso zerado.
      final dto = UserProgressDto.fromMap(map);
      return Success(UserProgressMapper.toEntity(dto));
    } on FirebaseException catch (e) {
      return FailureResult(_mapFirebase(e));
    } catch (e) {
      return FailureResult(UnknownFailure('fetch user_progress: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> save(
    String uid,
    UserProgress progress,
  ) async {
    if (uid.isEmpty) {
      return const FailureResult(
        AuthApiFailure(
          'Você precisa estar logado pra salvar seu progresso.',
          'save chamado com uid vazio (usuario nao autenticado)',
        ),
      );
    }
    try {
      await _dataSource.save(uid, UserProgressMapper.toDto(progress).toMap());
      return const Success(null);
    } on FirebaseException catch (e) {
      return FailureResult(_mapFirebase(e));
    } catch (e) {
      return FailureResult(UnknownFailure('save user_progress: $e'));
    }
  }

  /// Mapeia codigos do Firestore pra hierarquia de Failure do projeto.
  Failure _mapFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return AuthApiFailure(
          'Acesso negado ao seu progresso. Faça login novamente.',
          'Firestore ${e.code}: ${e.message}',
        );
      case 'unavailable':
      case 'network-request-failed':
        return NetworkFailure('Firestore ${e.code}: ${e.message}');
      case 'deadline-exceeded':
        return TimeoutFailure('Firestore ${e.code}: ${e.message}');
      default:
        return ServerFailure(
          'Erro ao acessar seu progresso. Tente novamente.',
          'Firestore ${e.code}: ${e.message}',
        );
    }
  }
}
