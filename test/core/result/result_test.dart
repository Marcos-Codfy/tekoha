// test/core/result/result_test.dart
//
// Estrategia: testar TODOS os caminhos do `fold` (success e failure)
// e dos atalhos getOrNull/failureOrNull. Boundary cases: tipo de S e F
// genericos, valores `null` validos quando S = void.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';

void main() {
  group('Result<S, F>', () {
    test('Success.fold chama onSuccess com o valor', () {
      const Result<int, Failure> r = Success(42);
      final out = r.fold(
        onSuccess: (v) => 'ok:$v',
        onFailure: (f) => 'fail:${f.userMessage}',
      );
      expect(out, 'ok:42');
    });

    test('FailureResult.fold chama onFailure com o failure', () {
      const Result<int, Failure> r =
          FailureResult(NetworkFailure('no net'));
      final out = r.fold(
        onSuccess: (v) => 'ok:$v',
        onFailure: (f) => 'fail:${f.userMessage}',
      );
      expect(
        out,
        'fail:Sem conexao com a internet. Verifique sua rede e tente de novo.',
      );
    });

    test('isSuccess / isFailure refletem o tipo concreto', () {
      const Result<int, Failure> ok = Success(1);
      const Result<int, Failure> bad = FailureResult(UnknownFailure());

      expect(ok.isSuccess, true);
      expect(ok.isFailure, false);
      expect(bad.isSuccess, false);
      expect(bad.isFailure, true);
    });

    test('getOrNull devolve valor em Success e null em FailureResult', () {
      const Result<String, Failure> ok = Success('hi');
      const Result<String, Failure> bad = FailureResult(UnknownFailure());

      expect(ok.getOrNull(), 'hi');
      expect(bad.getOrNull(), isNull);
    });

    test('failureOrNull devolve failure em FailureResult e null em Success',
        () {
      const Result<String, Failure> ok = Success('hi');
      const failure = NetworkFailure();
      const Result<String, Failure> bad = FailureResult(failure);

      expect(ok.failureOrNull(), isNull);
      expect(bad.failureOrNull(), same(failure));
    });

    test('Success com tipo void aceita null como valor', () {
      const Result<void, Failure> r = Success(null);
      expect(r.isSuccess, true);
      // getOrNull em Result<void, _> tem tipo void e nao pode ser comparado;
      // o que importa e que isSuccess seja true e fold dispare onSuccess.
      bool called = false;
      r.fold(onSuccess: (_) => called = true, onFailure: (_) => null);
      expect(called, true);
    });
  });
}
