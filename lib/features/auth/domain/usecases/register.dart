// lib/features/auth/domain/usecases/register.dart

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  const RegisterUseCase(this._repository);

  Future<Result<AuthUser, Failure>> call({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
}
