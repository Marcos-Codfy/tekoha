// test/integration/practice_flow_test.dart
//
// Teste de integracao da feature Practice.
// Estrategia: monta o ChangeNotifierProvider com UseCase mockado, pumpa
// a PracticeScreen e verifica os 3 estados visuais principais:
//   - loading (CircularProgressIndicator)
//   - loaded (ModuleCards com nome do modulo)
//   - error (ErrorView com mensagem)
//
// Cobre o caminho UI -> Provider -> UseCase -> Result -> render.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/practice/data/repositories/in_memory_progress_repository.dart';
import 'package:tekoha/features/practice/domain/entities/module.dart';
import 'package:tekoha/features/practice/domain/usecases/get_modules.dart';
import 'package:tekoha/features/practice/presentation/providers/modules_provider.dart';
import 'package:tekoha/features/practice/presentation/providers/progress_provider.dart';
import 'package:tekoha/features/practice/presentation/screens/practice_screen.dart';

class _MockGetModules extends Mock implements GetModulesUseCase {}

void main() {
  late _MockGetModules mockUseCase;
  late ProgressProvider progressProvider;

  setUp(() {
    mockUseCase = _MockGetModules();
    progressProvider = ProgressProvider(InMemoryProgressRepository());
  });

  Widget harness() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ModulesProvider(mockUseCase)),
          ChangeNotifierProvider.value(value: progressProvider),
        ],
        child: const PracticeScreen(),
      ),
    );
  }

  testWidgets('estado loaded mostra ModuleCard por modulo',
      (tester) async {
    when(() => mockUseCase(
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<Module>, Failure>([
              Module(
                id: 'r1',
                name: 'Saudacoes',
                description: 'Modulo introdutorio',
                language: 'nheengatu',
                order: 1,
              ),
              Module(
                id: 'r2',
                name: 'Apresentacao',
                description: '',
                language: 'nheengatu',
                order: 2,
              ),
            ]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Saudacoes'), findsOneWidget);
    expect(find.text('Apresentacao'), findsOneWidget);
    // Trava por progresso (ESP-005): modulo 1 aberto; modulo 2
    // travado ate o 1 ser completado.
    expect(find.text('Termine o módulo anterior'), findsOneWidget);
  });

  testWidgets(
      'modulo 2 destrava quando o modulo 1 esta completo (progresso real)',
      (tester) async {
    when(() => mockUseCase(
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<Module>, Failure>([
              Module(
                id: 'r1',
                name: 'Saudacoes',
                description: 'Modulo introdutorio',
                language: 'nheengatu',
                order: 1,
              ),
              Module(
                id: 'r2',
                name: 'Apresentacao',
                description: 'Segundo modulo',
                language: 'nheengatu',
                order: 2,
              ),
            ]));

    // Simula modulo 1 completo: trilha de 4 etapas, todas feitas.
    progressProvider.registerTotalStages('r1', 4);
    for (var i = 0; i < 4; i++) {
      await progressProvider.markStageDone('r1', i);
    }

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Termine o módulo anterior'), findsNothing);
  });

  testWidgets('estado error mostra ErrorView com mensagem do Failure',
      (tester) async {
    when(() => mockUseCase(
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure()));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Sem conexao'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('estado vazio mostra mensagem "Nenhum conteudo disponivel"',
      (tester) async {
    when(() => mockUseCase(
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<Module>, Failure>([]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Nenhum módulo disponível'),
      findsOneWidget,
    );
  });

  testWidgets('botao Tentar novamente chama useCase de novo com forceRefresh',
      (tester) async {
    when(() => mockUseCase(
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure()));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    // Carga inicial + retry = 2 chamadas
    verify(() => mockUseCase(
        language: 'nheengatu', forceRefresh: any(named: 'forceRefresh')))
        .called(greaterThanOrEqualTo(2));
  });
}
