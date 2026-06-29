// lib/core/result/result.dart
// Camada: Core.
//
// Tipo Result generico — equivalente "caseiro" do Either<L, R>.
// Forca quem chama a TRATAR sucesso E falha EXPLICITAMENTE.
//
// Por que isso e melhor que try/catch que retorna bool?
//   1. Tipagem do erro: voce sabe QUE FALHA pode vir (NetworkFailure,
//      AuthFailure, etc), em vez de adivinhar.
//   2. Match exaustivo: o compilador grita se voce esquecer de tratar
//      um caso (sealed class na Failure + .fold aqui).
//   3. Testavel: UseCases retornam Result<X, Failure> direto, sem
//      try/catch nem mock de stack trace.
//
// EXEMPLO DE USO:
//
//   final result = await getModulesUseCase('nheengatu');
//   result.fold(
//     onSuccess: (modules) => _modules = modules,
//     onFailure: (failure) => _errorMessage = failure.userMessage,
//   );

import '../errors/failures.dart';

sealed class Result<S, F extends Failure> {
  const Result();

  /// Aplica uma das duas funcoes dependendo do tipo concreto.
  /// E o ponto de entrada principal pra usar o Result.
  R fold<R>({
    required R Function(S value) onSuccess,
    required R Function(F failure) onFailure,
  });

  /// `true` se o Result e Success.
  bool get isSuccess => this is Success<S, F>;

  /// `true` se o Result e FailureResult.
  bool get isFailure => this is FailureResult<S, F>;

  /// Devolve o valor se Success, ou `null` se Failure.
  /// Use quando o caller pode trabalhar com null (ex.: cache lookup).
  S? getOrNull() {
    final self = this;
    if (self is Success<S, F>) return self.value;
    return null;
  }

  /// Devolve o failure se FailureResult, ou `null` se Success.
  F? failureOrNull() {
    final self = this;
    if (self is FailureResult<S, F>) return self.failure;
    return null;
  }
}

class Success<S, F extends Failure> extends Result<S, F> {
  final S value;
  const Success(this.value);

  @override
  R fold<R>({
    required R Function(S value) onSuccess,
    required R Function(F failure) onFailure,
  }) =>
      onSuccess(value);

  @override
  String toString() => 'Success($value)';
}

class FailureResult<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const FailureResult(this.failure);

  @override
  R fold<R>({
    required R Function(S value) onSuccess,
    required R Function(F failure) onFailure,
  }) =>
      onFailure(failure);

  @override
  String toString() => 'FailureResult($failure)';
}
