// test/integration/trail_flow_test.dart
//
// Teste de integracao da ModuleTrailScreen (ESP-005).
// Estrategia: registra UseCases mockados no get_it (a tela resolve via
// sl<>), pumpa a trilha e verifica:
//   - loaded: 4 etapas curadas, primeira ativa, demais travadas
//   - progresso: etapa feita vira "done" e a proxima destrava
//   - error: ErrorView com mensagem do Failure
//   - celebracao: modulo completo mostra banner + CTA de avanco

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/di/injection.dart';
import 'package:tekoha/features/lesson/domain/entities/lesson.dart';
import 'package:tekoha/features/lesson/domain/entities/word.dart';
import 'package:tekoha/features/lesson/domain/usecases/get_lessons_by_module.dart';
import 'package:tekoha/features/lesson/domain/usecases/get_words_by_lesson.dart';
import 'package:tekoha/features/practice/data/repositories/in_memory_progress_repository.dart';
import 'package:tekoha/features/practice/domain/entities/module.dart';
import 'package:tekoha/features/practice/presentation/providers/progress_provider.dart';
import 'package:tekoha/features/practice/presentation/screens/module_trail_screen.dart';

class _MockGetLessons extends Mock implements GetLessonsByModuleUseCase {}

class _MockGetWords extends Mock implements GetWordsByLessonUseCase {}

Word _w(int order) => Word(
      id: 'w$order',
      nheengatu: 'nh$order',
      translation: 'tr$order',
      pronunciation: 'pr$order',
      culturalNote: '',
      lessonId: 'L1',
      order: order,
      audioUrl: 'http://a/$order.mp3',
    );

const _module1 = Module(
  id: 'm1',
  name: 'Cumprimentos',
  description: 'Modulo introdutorio',
  language: 'nheengatu',
  order: 1,
);

const _module2 = Module(
  id: 'm2',
  name: 'Apresentacao',
  description: 'Segundo modulo',
  language: 'nheengatu',
  order: 2,
);

void main() {
  late _MockGetLessons mockGetLessons;
  late _MockGetWords mockGetWords;
  late ProgressProvider progressProvider;

  setUp(() async {
    await resetDependencies();
    mockGetLessons = _MockGetLessons();
    mockGetWords = _MockGetWords();
    sl.registerLazySingleton<GetLessonsByModuleUseCase>(() => mockGetLessons);
    sl.registerLazySingleton<GetWordsByLessonUseCase>(() => mockGetWords);
    progressProvider = ProgressProvider(InMemoryProgressRepository());
  });

  tearDown(() async {
    await resetDependencies();
  });

  void stubHappyPath() {
    when(() => mockGetLessons(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const Success<List<Lesson>, Failure>([
              Lesson(
                id: 'L1',
                title: 'Saudacoes Essenciais',
                moduleId: 'm1',
                order: 1,
                xpReward: 100,
              ),
            ]));
    when(() => mockGetWords(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => Success<List<Word>, Failure>(
              List.generate(10, (i) => _w(i + 1)),
            ));
  }

  Widget harness({List<Module> modules = const [_module1], int index = 0}) {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: progressProvider,
        child: ModuleTrailScreen(modules: modules, index: index),
      ),
    );
  }

  testWidgets('trilha carrega 4 etapas curadas; 1a ativa e demais travadas',
      (tester) async {
    stubHappyPath();

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('A palavra curinga'), findsOneWidget);
    expect(find.text('O encontro'), findsOneWidget);
    expect(find.text('Sim e não'), findsOneWidget);
    expect(find.text('Gratidão e despedida'), findsOneWidget);

    // 3 etapas travadas exibem a dica de destravamento.
    expect(find.text('Termine a etapa anterior'), findsNWidgets(3));
    // A etapa ativa mostra a contagem de exercicios (3 palavras x 4).
    expect(find.text('12 exercícios'), findsOneWidget);
  });

  testWidgets('etapa concluida vira done e destrava a proxima',
      (tester) async {
    stubHappyPath();
    await progressProvider.markStageDone('m1', 0);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Uma etapa done (icone de replay), duas ainda travadas.
    expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
    expect(find.text('Termine a etapa anterior'), findsNWidgets(2));
    // Goal-Gradient: faltam 3.
    expect(find.text('Faltam 3 etapas pra fechar o módulo.'), findsOneWidget);
  });

  testWidgets('modulo completo mostra celebracao com CTA pro proximo',
      (tester) async {
    stubHappyPath();
    for (var i = 0; i < 4; i++) {
      await progressProvider.markStageDone('m1', i);
    }

    await tester.pumpWidget(
      harness(modules: const [_module1, _module2], index: 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Módulo concluído!'), findsOneWidget);
    expect(find.text('Avançar: Apresentacao'), findsOneWidget);
    // Total de etapas registrado -> PracticeScreen sabera que m1 completou.
    expect(progressProvider.isModuleComplete('m1'), isTrue);
  });

  testWidgets('ultimo modulo completo agradece em Nheengatu (sem CTA)',
      (tester) async {
    stubHappyPath();
    for (var i = 0; i < 4; i++) {
      await progressProvider.markStageDone('m1', i);
    }

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Kuekatu reté!'), findsOneWidget);
  });

  testWidgets('falha de rede mostra ErrorView com mensagem', (tester) async {
    when(() => mockGetLessons(any(), forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => const FailureResult(NetworkFailure()));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.textContaining('Sem conexao'), findsOneWidget);
  });
}
