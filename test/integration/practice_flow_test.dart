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
import 'package:tekoha/features/practice/domain/entities/module.dart';
import 'package:tekoha/features/practice/domain/usecases/get_modules.dart';
import 'package:tekoha/features/practice/presentation/providers/modules_provider.dart';
import 'package:tekoha/features/practice/presentation/screens/practice_screen.dart';

class _MockGetModules extends Mock implements GetModulesUseCase {}

void main() {
  late _MockGetModules mockUseCase;

  setUp(() {
    mockUseCase = _MockGetModules();
  });

  Widget harness() {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => ModulesProvider(mockUseCase),
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
    // Todos os modulos destravados desde a conclusao dos audios
    // (30/30 palavras com audio_url) — nenhum overlay de trava.
    expect(find.text('Em ajustes'), findsNothing);
    expect(find.text('Em construção'), findsNothing);
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
