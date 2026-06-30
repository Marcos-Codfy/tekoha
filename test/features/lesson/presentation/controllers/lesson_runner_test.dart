// test/features/lesson/presentation/controllers/lesson_runner_test.dart
//
// MAIOR e MAIS CRITICO arquivo de testes do projeto.
//
// O LessonRunner contem TODA a logica de negocio da licao: carga, XP,
// tentativas, fala, transicoes. Esse arquivo cobre os fluxos
// representativos com particionamento:
//
//   Carga:
//     - sucesso modo MISTO (3 palavras com audio): monta 12 steps
//     - sucesso modo QUIZ PURO (4+ palavras sem audio): monta 4 steps
//     - falha em GetLessons (NetworkFailure) -> status error
//     - falha em GetWords -> status error
//     - lista vazia de lessons -> status error
//     - lista vazia de words -> status error
//     - quiz puro com < 4 palavras -> status error (boundary)
//
//   Quiz tradicional:
//     - acerto: +10 XP, answered=true, wasCorrect=true
//     - 1a errada: feedbackMessage, NAO answered
//     - clearWrongQuizSelection: desmarca, mesmo apos varias erradas
//     - 2a tentativa acerta: +10 XP final
//
//   Audio escolha:
//     - acerto: +10 XP
//     - 1a errada: encoraja (NAO answered)
//     - 2a errada: avanca sem XP, wasCorrect=false
//
//   Fala (listenAndRepeat):
//     - speech indisponivel: avanca sem XP
//     - skipSpeech: avanca sem XP
//
//   Curiosidade:
//     - consumeShouldShowCuriosity: true so na 1a vez por palavra e
//       SO em acerto
//
//   Transicoes:
//     - next() avanca; no ultimo passo, status -> done
//     - progress aumenta proporcionalmente

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tekoha/core/errors/failures.dart';
import 'package:tekoha/core/result/result.dart';
import 'package:tekoha/core/services/audio_player_service.dart';
import 'package:tekoha/core/services/speech_service.dart';
import 'package:tekoha/features/lesson/domain/entities/lesson.dart';
import 'package:tekoha/features/lesson/domain/entities/word.dart';
import 'package:tekoha/features/lesson/domain/usecases/get_lessons_by_module.dart';
import 'package:tekoha/features/lesson/domain/usecases/get_words_by_lesson.dart';
import 'package:tekoha/features/lesson/presentation/controllers/lesson_runner.dart';
import 'package:tekoha/features/lesson/presentation/controllers/lesson_step.dart';

class _MockGetLessons extends Mock implements GetLessonsByModuleUseCase {}

class _MockGetWords extends Mock implements GetWordsByLessonUseCase {}

class _MockAudio extends Mock implements AudioPlayerService {}

class _MockSpeech extends Mock implements SpeechService {}

// Helpers --------------------------------------------------------------------

Lesson _lesson() => const Lesson(
      id: 'L1',
      title: 'Cumprimentos',
      moduleId: 'M1',
      order: 1,
      xpReward: 100,
    );

Word _w(int order, String nh, String tr,
        {String url = '', String pron = '', String note = ''}) =>
    Word(
      id: 'rec$order',
      nheengatu: nh,
      translation: tr,
      pronunciation: pron,
      culturalNote: note,
      lessonId: 'L1',
      order: order,
      audioUrl: url,
    );

LessonRunner _build({
  required _MockGetLessons getLessons,
  required _MockGetWords getWords,
  required _MockAudio audio,
  required _MockSpeech speech,
}) {
  // Defaults: audio/speech nao crasham em chamadas comuns.
  when(() => audio.preload(any())).thenAnswer((_) async {});
  when(() => audio.play(any())).thenAnswer((_) async {});
  when(() => audio.stop()).thenAnswer((_) async {});
  when(() => speech.init()).thenAnswer((_) async => true);
  when(() => speech.stop()).thenAnswer((_) async {});
  when(() => speech.listen(onResult: any(named: 'onResult')))
      .thenAnswer((_) async {});
  when(() => speech.matches(any(), any())).thenReturn(false);

  return LessonRunner(
    getLessons: getLessons,
    getWords: getWords,
    player: audio,
    speech: speech,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  late _MockGetLessons getLessons;
  late _MockGetWords getWords;
  late _MockAudio audio;
  late _MockSpeech speech;

  setUp(() {
    getLessons = _MockGetLessons();
    getWords = _MockGetWords();
    audio = _MockAudio();
    speech = _MockSpeech();
  });

  // ── Carga ─────────────────────────────────────────────────────────────

  group('load - modo MISTO (palavras com audio)', () {
    test('sucesso: 3 palavras com audio -> 12 steps (3 audio + 1 quiz x 3)',
        () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3'),
            _w(2, 'karuka', 'tarde', url: 'http://k.mp3'),
            _w(3, 'pituna', 'noite', url: 'http://p.mp3'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      expect(r.status, LessonRunnerStatus.exercising);
      expect(r.steps, hasLength(12));
      expect(r.totalPossibleXp, 120);
      verify(() => audio.preload(any())).called(1);
      verify(() => speech.init()).called(1);
    });

    test('load e idempotente (chamada dupla nao re-carrega)', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3'),
            _w(2, 'karuka', 'tarde', url: 'http://k.mp3'),
            _w(3, 'pituna', 'noite', url: 'http://p.mp3'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');
      await r.load('M1');

      verify(() => getLessons('M1')).called(1);
    });
  });

  group('load - modo QUIZ PURO (sem audio)', () {
    test('4 palavras sem audio -> 4 quiz steps', () async {
      when(() => getLessons('M2'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'a', 'aa'),
            _w(2, 'b', 'bb'),
            _w(3, 'c', 'cc'),
            _w(4, 'd', 'dd'),
            _w(5, 'e', 'ee'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M2');

      expect(r.status, LessonRunnerStatus.exercising);
      expect(r.steps, hasLength(4));
      expect(r.steps.every((s) => s is QuizStep), true);
      // Modo quiz puro NAO inicializa audio nem speech.
      verifyNever(() => audio.preload(any()));
      verifyNever(() => speech.init());
    });

    test('boundary: < 4 palavras sem audio -> erro', () async {
      when(() => getLessons('M2'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'a', 'aa'),
            _w(2, 'b', 'bb'),
            _w(3, 'c', 'cc'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M2');

      expect(r.status, LessonRunnerStatus.error);
      expect(r.errorMessage, contains('4 palavras'));
    });
  });

  group('load - erros', () {
    test('NetworkFailure em getLessons -> status error com userMessage',
        () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => const FailureResult(NetworkFailure()));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      expect(r.status, LessonRunnerStatus.error);
      expect(r.errorMessage, contains('Sem conexao'));
    });

    test('falha em getWords -> status error', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1'))
          .thenAnswer((_) async => const FailureResult(TimeoutFailure()));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      expect(r.status, LessonRunnerStatus.error);
    });

    test('lessons vazia -> mensagem especifica', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => const Success<List<Lesson>, Failure>([]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      expect(r.status, LessonRunnerStatus.error);
      expect(r.errorMessage, contains('Nenhuma licao'));
    });

    test('words vazia -> mensagem especifica', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1'))
          .thenAnswer((_) async => const Success<List<Word>, Failure>([]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      expect(r.status, LessonRunnerStatus.error);
      expect(r.errorMessage, contains('nao tem palavras'));
    });
  });

  // ── Quiz tradicional ──────────────────────────────────────────────────

  group('quiz tradicional', () {
    Future<LessonRunner> loadedQuizPureRunner() async {
      when(() => getLessons('M2'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'a', 'aa'),
            _w(2, 'b', 'bb'),
            _w(3, 'c', 'cc'),
            _w(4, 'd', 'dd'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M2');
      return r;
    }

    test('acerto da +10 XP e marca answered/wasCorrect', () async {
      final r = await loadedQuizPureRunner();
      final q = (r.current as QuizStep).data;

      r.onQuizOptionTap(q.correctIndex);

      expect(r.xpEarned, 10);
      expect(r.answered, true);
      expect(r.wasCorrect, true);
      expect(r.selectedOption, q.correctIndex);
    });

    test('1a errada NAO marca answered e libera com clearWrongQuizSelection',
        () async {
      final r = await loadedQuizPureRunner();
      final q = (r.current as QuizStep).data;
      final wrongIndex = q.correctIndex == 0 ? 1 : 0;

      r.onQuizOptionTap(wrongIndex);

      expect(r.answered, false);
      expect(r.xpEarned, 0);
      expect(r.feedbackMessage, contains('Quase'));
      expect(r.selectedOption, wrongIndex);

      r.clearWrongQuizSelection();
      expect(r.selectedOption, isNull);
    });

    test('apos tap em qualquer opcao quando ja answered, ignora', () async {
      final r = await loadedQuizPureRunner();
      final q = (r.current as QuizStep).data;

      r.onQuizOptionTap(q.correctIndex);
      final xpAposAcerto = r.xpEarned;
      r.onQuizOptionTap(q.correctIndex == 0 ? 1 : 0); // tap apos respondido

      expect(r.xpEarned, xpAposAcerto);
      expect(r.wasCorrect, true);
    });
  });

  // ── Curiosidade ───────────────────────────────────────────────────────

  group('curiosidade', () {
    test('consumeShouldShowCuriosity: so 1x por palavra e so em acerto',
        () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3', note: 'nota da ara'),
            _w(2, 'karuka', 'tarde', url: 'http://k.mp3', note: 'nota karuka'),
            _w(3, 'pituna', 'noite', url: 'http://p.mp3', note: 'nota pituna'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      // Primeiro passo (audio) — vamos forcar acerto via tap correta.
      final step1 = r.current;
      expect(step1, isA<AudioStep>());
      final ex1 = (step1 as AudioStep).data;
      r.onAudioOptionTap(ex1.correctIndex);

      expect(r.wasCorrect, true);
      expect(r.consumeShouldShowCuriosity(), true,
          reason: '1a vez com a palavra ara em acerto');
      expect(r.consumeShouldShowCuriosity(), false,
          reason: '2a chamada na mesma palavra ja foi exibida');
    });

    test('em erro, consumeShouldShowCuriosity sempre false', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3', note: 'nota'),
            _w(2, 'karuka', 'tarde', url: 'http://k.mp3'),
            _w(3, 'pituna', 'noite', url: 'http://p.mp3'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');

      final ex = (r.current as AudioStep).data;
      final wrong = ex.correctIndex == 0 ? 1 : 0;
      r.onAudioOptionTap(wrong);
      r.onAudioOptionTap(wrong); // segunda errada -> esgota tentativas

      expect(r.answered, true);
      expect(r.wasCorrect, false);
      expect(r.consumeShouldShowCuriosity(), false);
    });
  });

  // ── Audio escolha (tentativas) ────────────────────────────────────────

  group('audio - tentativas', () {
    Future<LessonRunner> loadedAudioRunner() async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3'),
            _w(2, 'karuka', 'tarde', url: 'http://k.mp3'),
            _w(3, 'pituna', 'noite', url: 'http://p.mp3'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');
      return r;
    }

    test('acerto na 1a tentativa: +10 XP, wasCorrect', () async {
      final r = await loadedAudioRunner();
      final ex = (r.current as AudioStep).data;
      r.onAudioOptionTap(ex.correctIndex);
      expect(r.xpEarned, 10);
      expect(r.wasCorrect, true);
    });

    test('errada 1a -> encoraja, NAO answered', () async {
      final r = await loadedAudioRunner();
      final ex = (r.current as AudioStep).data;
      final wrong = ex.correctIndex == 0 ? 1 : 0;
      r.onAudioOptionTap(wrong);

      expect(r.answered, false);
      expect(r.feedbackMessage, contains('Quase'));
      expect(r.audioAttempts, 1);
    });

    test('errada 2x consecutivas: avanca sem XP, mostra resposta', () async {
      final r = await loadedAudioRunner();
      final ex = (r.current as AudioStep).data;
      final wrong = ex.correctIndex == 0 ? 1 : 0;
      r.onAudioOptionTap(wrong);
      r.onAudioOptionTap(wrong);

      expect(r.answered, true);
      expect(r.wasCorrect, false);
      expect(r.xpEarned, 0);
      expect(r.feedbackMessage, contains('Boa tentativa'));
      expect(r.correctAnswerText, isNotNull);
    });
  });

  // ── Fala ──────────────────────────────────────────────────────────────

  group('fala (listenAndRepeat)', () {
    test('speech indisponivel -> toggleMic avanca sem XP', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      // Sobrescreve o default do _build APOS construcao — esse e o
      // ultimo `when` registrado e o que vale na chamada de load().
      when(() => speech.init()).thenAnswer((_) async => false);
      await r.load('M1');
      // Avanca ate o exercicio listenAndRepeat (step index 2 com 1 palavra).
      r.onAudioOptionTap((r.current as AudioStep).data.correctIndex);
      r.next();
      r.onAudioOptionTap((r.current as AudioStep).data.correctIndex);
      r.next();

      expect(r.speechAvailable, false);
      await r.toggleMic();

      expect(r.answered, true);
      expect(r.wasCorrect, false);
      expect(r.feedbackMessage, contains('indisponivel'));
    });

    test('skipSpeech avanca sem XP, sem acusar erro', () async {
      when(() => getLessons('M1'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'ara', 'manha', url: 'http://a.mp3'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M1');
      // pular pros listenAndRepeat (3o exercicio com 1 palavra)
      r.onAudioOptionTap((r.current as AudioStep).data.correctIndex);
      r.next();
      r.onAudioOptionTap((r.current as AudioStep).data.correctIndex);
      r.next();

      r.skipSpeech();

      expect(r.answered, true);
      expect(r.wasCorrect, false);
      expect(r.xpEarned, 20); // 2 acertos anteriores
    });
  });

  // ── Transicoes ────────────────────────────────────────────────────────

  group('next() e transicoes', () {
    test('next no ultimo passo -> status done', () async {
      when(() => getLessons('M2'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'a', 'aa'),
            _w(2, 'b', 'bb'),
            _w(3, 'c', 'cc'),
            _w(4, 'd', 'dd'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M2');

      // 4 steps. Avancar 3 vezes mantém status exercising; a 4a vira done.
      for (var i = 0; i < r.steps.length; i++) {
        final q = (r.current as QuizStep).data;
        r.onQuizOptionTap(q.correctIndex);
        r.next();
      }

      expect(r.status, LessonRunnerStatus.done);
      expect(r.xpEarned, 40);
    });

    test('progress aumenta proporcionalmente', () async {
      when(() => getLessons('M2'))
          .thenAnswer((_) async => Success([_lesson()]));
      when(() => getWords('L1')).thenAnswer((_) async => Success([
            _w(1, 'a', 'aa'),
            _w(2, 'b', 'bb'),
            _w(3, 'c', 'cc'),
            _w(4, 'd', 'dd'),
          ]));

      final r = _build(
        getLessons: getLessons,
        getWords: getWords,
        audio: audio,
        speech: speech,
      );
      await r.load('M2');

      expect(r.progress, closeTo(0.25, 0.001));
      r.onQuizOptionTap((r.current as QuizStep).data.correctIndex);
      r.next();
      expect(r.progress, closeTo(0.5, 0.001));
    });
  });
}
