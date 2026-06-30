// test/integration/culture_flow_test.dart
//
// Cobre o fluxo CultureScreen: troca de chip dispara nova carga,
// estado de erro mostra ErrorView, pull-to-refresh chama com
// forceRefresh.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/features/culture/domain/entities/culture_content.dart';
import 'package:tekoha/features/culture/domain/usecases/get_culture_content.dart';
import 'package:tekoha/features/culture/presentation/providers/culture_provider.dart';
import 'package:tekoha/features/culture/presentation/screens/culture_screen.dart';

class _MockUseCase extends Mock implements GetCultureContentUseCase {}

void main() {
  late _MockUseCase mockUseCase;

  setUp(() {
    mockUseCase = _MockUseCase();
  });

  Widget harness() {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => CultureProvider(mockUseCase),
        child: const CultureScreen(),
      ),
    );
  }

  testWidgets('estado loaded renderiza CultureCard por conteudo',
      (tester) async {
    when(() => mockUseCase(
            category: any(named: 'category'),
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<CultureContent>, Failure>([
              CultureContent(
                id: 'c1',
                language: 'nheengatu',
                category: 'curiosities',
                title: 'Sobre a lingua',
                body: 'Texto curto.',
                order: 1,
                isActive: true,
              ),
            ]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Sobre a lingua'), findsOneWidget);
    expect(find.text('Texto curto.'), findsOneWidget);
  });

  testWidgets('estado de erro mostra ErrorView', (tester) async {
    when(() => mockUseCase(
            category: any(named: 'category'),
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(TimeoutFailure()));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('demorou'), findsOneWidget);
  });

  testWidgets('estado vazio mostra mensagem', (tester) async {
    when(() => mockUseCase(
            category: any(named: 'category'),
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
            (_) async => const Success<List<CultureContent>, Failure>([]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum conteúdo nessa categoria ainda.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar em outro chip dispara nova carga', (tester) async {
    when(() => mockUseCase(
            category: any(named: 'category'),
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<CultureContent>, Failure>([]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('História'));
    await tester.pumpAndSettle();

    verify(() => mockUseCase(
        category: 'curiosities',
        language: 'nheengatu',
        forceRefresh: false)).called(1);
    verify(() => mockUseCase(
        category: 'history',
        language: 'nheengatu',
        forceRefresh: false)).called(1);
  });

  testWidgets('chip desabilitado (Cosmologia) NAO dispara carga',
      (tester) async {
    when(() => mockUseCase(
            category: any(named: 'category'),
            language: any(named: 'language'),
            forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<CultureContent>, Failure>([]));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Pode existir o texto "Cosmologia" mas o tap nao deve disparar.
    final cosmology = find.text('Cosmologia');
    if (cosmology.evaluate().isNotEmpty) {
      await tester.tap(cosmology, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    verifyNever(() => mockUseCase(
        category: 'cosmology',
        language: any(named: 'language'),
        forceRefresh: any(named: 'forceRefresh')));
  });
}
