// lib/features/auth/domain/repositories/auth_repository.dart
// Camada: Domain (Auth).
//
// CONTRATO da feature Auth. Quem implementa decide a fonte de
// identidade (Firebase, OAuth, mock).
//
// A interface devolve Result tipado pra forcar tratamento de erros.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  /// `true` se o backend de auth foi inicializado com sucesso.
  /// Pode ser `false` quando rodando em ambiente sem Firebase (ex.: web
  /// sem `flutterfire configure --platforms=web`).
  bool get isAvailable;

  /// Stream do usuario logado. `null` quando ninguem esta logado.
  /// Util pra UI escutar mudancas globais (login feito em outra aba, etc).
  Stream<AuthUser?> authStateChanges();

  /// Usuario atualmente logado, ou `null`.
  AuthUser? get currentUser;

  Future<Result<AuthUser, Failure>> signIn({
    required String email,
    required String password,
  });

  Future<Result<AuthUser, Failure>> register({
    required String email,
    required String password,
    String? displayName,
  });

  Future<Result<void, Failure>> signOut();
}
