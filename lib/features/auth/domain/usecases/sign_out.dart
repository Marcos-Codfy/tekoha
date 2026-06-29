// lib/features/auth/domain/usecases/sign_out.dart

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<Result<void, Failure>> call() => _repository.signOut();
}
