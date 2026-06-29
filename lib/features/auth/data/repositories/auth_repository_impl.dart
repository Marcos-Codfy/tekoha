// lib/features/auth/data/repositories/auth_repository_impl.dart
// Camada: Data (Auth).
//
// Implementacao concreta do AuthRepository sobre Firebase. Traduz
// FirebaseAuthException em [AuthFailure] tipada com mensagem em PT-BR.

import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../mappers/firebase_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  bool get isAvailable => _datasource.isAvailable;

  @override
  Stream<AuthUser?> authStateChanges() => _datasource
      .authStateChanges()
      .map((user) => user == null ? null : FirebaseUserMapper.toEntity(user));

  @override
  AuthUser? get currentUser {
    final user = _datasource.currentUser;
    return user == null ? null : FirebaseUserMapper.toEntity(user);
  }

  @override
  Future<Result<AuthUser, Failure>> signIn({
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      return const FailureResult(
        ConfigFailure('Login indisponivel neste ambiente.', 'auth not available'),
      );
    }
    try {
      final user = await _datasource.signIn(email, password);
      return Success(FirebaseUserMapper.toEntity(user));
    } on FirebaseAuthException catch (e) {
      return FailureResult(_mapException(e));
    } catch (e) {
      return FailureResult(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<AuthUser, Failure>> register({
    required String email,
    required String password,
  }) async {
    if (!isAvailable) {
      return const FailureResult(
        ConfigFailure('Cadastro indisponivel neste ambiente.', 'auth not available'),
      );
    }
    try {
      final user = await _datasource.register(email, password);
      return Success(FirebaseUserMapper.toEntity(user));
    } on FirebaseAuthException catch (e) {
      return FailureResult(_mapException(e));
    } catch (e) {
      return FailureResult(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    if (!isAvailable) {
      return const Success(null);
    }
    try {
      await _datasource.signOut();
      return const Success(null);
    } catch (e) {
      return FailureResult(UnknownFailure(e.toString()));
    }
  }

  /// Mapeia FirebaseAuthException -> AuthFailure tipada com mensagem PT-BR.
  /// Centraliza a traducao num lugar so — a UI escolhe a mensagem por
  /// `code` se quiser microcopy contextual.
  AuthFailure _mapException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'user-not-found' => 'Nenhuma conta encontrada com este e-mail.',
      'wrong-password' => 'Senha incorreta. Tente novamente.',
      'email-already-in-use' => 'Este e-mail ja esta cadastrado.',
      'invalid-email' => 'E-mail invalido.',
      'weak-password' => 'Senha fraca. Use pelo menos 6 caracteres.',
      'too-many-requests' => 'Muitas tentativas. Aguarde alguns minutos.',
      'invalid-credential' => 'E-mail ou senha incorretos.',
      'auth-unavailable' => 'Login indisponivel neste ambiente.',
      _ => 'Erro ao autenticar. Tente novamente.',
    };
    return AuthFailure(
      code: e.code,
      userMessage: message,
      technicalDetails: e.message,
    );
  }
}
