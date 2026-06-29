// test/features/practice/domain/usecases/get_modules_test.dart
//
// UseCase e fino — apenas repassa pro repo. Verifica que:
//   - usa o default `nheengatu` quando nada e passado
//   - propaga forceRefresh
//   - propaga Result tal qual

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/practice/domain/entities/module.dart';
import 'package:tekoha/features/practice/domain/repositories/practice_repository.dart';
import 'package:tekoha/features/practice/domain/usecases/get_modules.dart';

class _MockRepo extends Mock implements PracticeRepository {}

void main() {
  late _MockRepo repo;
  late GetModulesUseCase useCase;

  setUp(() {
    repo = _MockRepo();
    useCase = GetModulesUseCase(repo);
  });

  test('default language e nheengatu', () async {
    when(() =>
            repo.getModules(language: 'nheengatu', forceRefresh: false))
        .thenAnswer((_) async => const Success<List<Module>, Failure>([]));

    await useCase();
    verify(() =>
        repo.getModules(language: 'nheengatu', forceRefresh: false))
        .called(1);
  });

  test('forceRefresh e propagado', () async {
    when(() => repo.getModules(language: 'nheengatu', forceRefresh: true))
        .thenAnswer((_) async => const Success<List<Module>, Failure>([]));

    await useCase(forceRefresh: true);
    verify(() => repo.getModules(language: 'nheengatu', forceRefresh: true))
        .called(1);
  });

  test('Result do repo e devolvido tal qual', () async {
    when(() => repo.getModules(
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure()));

    final r = await useCase();
    expect(r.failureOrNull(), isA<NetworkFailure>());
  });
}
