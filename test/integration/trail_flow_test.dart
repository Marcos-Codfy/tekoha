// test/integration/trail_flow_test.dart
//
// Teste de integracao da ModuleTrailScreen (ESP-005 + ESP-006).
// Estrategia: registra UseCases mockados no get_it (a tela resolve via
// sl<>) e injeta UserProgressProvider com repositorio mockado. Verifica:
//   - loaded: 4 etapas curadas, primeira ativa, demais travadas
//   - progresso persistido: etapa done vem do Firestore mockado
//   - error: ErrorView com mensagem do Failure
//   - celebracao: modulo completo mostra banner + CTA de avanco

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/di/injection.dart';
import 'package:tekoha/features/achievements/domain/entities/achievement.dart';
import 'package:tekoha/features/achievements/domain/usecases/get_achievements.dart';
import 'package:tekoha/features/lesson/domain/entities/lesson.dart';
import 'package:tekoha/features/lesson/domain/entities/word.dart';
import 'package:tekoha/features/lesson/domain/usecases/get_lessons_by_module.dart';
import 'package:tekoha/features/lesson/domain/usecases/get_words_by_lesson.dart';
import 'package:tekoha/features/practice/domain/entities/module.dart';
import 'package:tekoha/features/practice/presentation/screens/module_trail_screen.dart';
import 'package:tekoha/features/progress/domain/entities/user_progress.dart';
import 'package:tekoha/features/progress/domain/repositories/user_progress_repository.dart';
import 'package:tekoha/features/progress/presentation/providers/user_progress_provider.dart';

class _MockGetLessons extends Mock implements GetLessonsByModuleUseCase {}

class _MockGetWords extends Mock implements GetWordsByLessonUseCase {}

class _MockProgressRepo extends Mock implements UserProgressRepository {}

class _MockGetAchievements extends Mock implements GetAchievementsUseCase {}

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
  late _MockProgressRepo progressRepo;
  late _MockGetAchievements getAchievements;
  late UserProgressProvider progressProvider;

  setUp(() async {
    await resetDependencies();
    mockGetLessons = _MockGetLessons();
    mockGetWords = _MockGetWords();
    progressRepo = _MockProgressRepo();
    getAchievements = _MockGetAchievements();
    sl.registerLazySingleton<GetLessonsByModuleUseCase>(() => mockGetLessons);
    sl.registerLazySingleton<GetWordsByLessonUseCase>(() => mockGetWords);

    when(() => progressRepo.fetch(any())).thenAnswer(
      (_) async => const Success(UserProgress.empty),
    );
    when(() => getAchievements()).thenAnswer(
      (_) async => const Success(<Achievement>[]),
    );
    progressProvider =
        UserProgressProvider(progressRepo, getAchievements, () => 'u1');
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

  testWidgets('etapa concluida (persistida no Firestore) vira done e '
      'destrava a proxima', (tester) async {
    stubHappyPath();
    when(() => progressRepo.fetch('u1')).thenAnswer(
      (_) async => const Success(UserProgress(
        xp: 40,
        streakDays: 1,
        lastPracticeAt: null,
        stagesDoneByModule: {
          'm1': {0},
        },
      )),
    );

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
    when(() => progressRepo.fetch('u1')).thenAnswer(
      (_) async => Success(const UserProgress(
        xp: 160,
        streakDays: 1,
        lastPracticeAt: null,
        stagesDoneByModule: {
          'm1': {0, 1, 2, 3},
        },
      ).withModuleDone('m1')),
    );

    await tester.pumpWidget(
      harness(modules: const [_module1, _module2], index: 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Módulo concluído!'), findsOneWidget);
    // CTA curto (ESP-008); o nome do proximo modulo aparece como
    // legenda abaixo do botao.
    expect(find.text('Próximo módulo'), findsOneWidget);
    expect(find.text('Apresentacao'), findsOneWidget);
    expect(progressProvider.isModuleComplete('m1'), isTrue);
  });

  testWidgets('ultimo modulo completo agradece em Nheengatu (sem CTA)',
      (tester) async {
    stubHappyPath();
    when(() => progressRepo.fetch('u1')).thenAnswer(
      (_) async => const Success(UserProgress(
        xp: 160,
        streakDays: 1,
        lastPracticeAt: null,
        stagesDoneByModule: {
          'm1': {0, 1, 2, 3},
        },
      )),
    );

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
