// lib/features/auth/domain/usecases/sign_in.dart

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<Result<AuthUser, Failure>> call({
    required String email,
    required String password,
  }) =>
      _repository.signIn(email: email, password: password);
}
