// lib/features/lesson/presentation/controllers/lesson_runner.dart
// Camada: Presentation (Lesson).
//
// CONTROLLER (ChangeNotifier) que ENCAPSULA toda a maquina de estado
// de uma sessao de licao. Foi extraido de dentro de lesson_screen.dart
// (1094 linhas) — agora a Screen so renderiza widget baseado neste
// estado e dispara acoes.
//
// O QUE ESTA AQUI:
//   - Carregamento (UseCases de licao/palavras)
//   - Construcao da sequencia de passos (audio + quiz intercalados)
//   - Avaliacao de resposta (quiz, audio-escolha, audio-fala)
//   - Acumulo de XP local, contador de tentativas
//   - Set de curiosidades ja exibidas (1x por palavra)
//   - Coordenacao de audio (preload, play) e fala (init, listen, eval)
//
// REGRAS DE NEGOCIO (preservadas do original):
//   - Acerto = +10 XP, mostra curiosidade so na 1a vez por palavra
//   - Quiz errado = encoraja e libera (tenta ate acertar)
//   - Audio errado 1a vez = encoraja e libera
//   - Audio errado 2a vez = avanca sem XP, mostra resposta
//   - Pular fala = avanca sem XP, sem acusar erro
//
// XP NAO PERSISTE — vive nesta sessao. Sprint futura: salvar no
// Firestore via novo UseCase SaveXpUseCase.

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../domain/builders/audio_exercise_builder.dart';
import '../../domain/builders/quiz_builder.dart';
import '../../domain/entities/audio_exercise.dart';
import '../../domain/usecases/get_lessons_by_module.dart';
import '../../domain/usecases/get_words_by_lesson.dart';
import 'lesson_step.dart';

/// XP ganho por exercicio correto.
const int kXpPerCorrect = 10;

/// Maximo de tentativas em exercicios de audio antes de avancar sem XP.
const int kMaxAudioAttempts = 2;

/// Quantas perguntas no fluxo de quiz puro (modulos sem audio).
const int kQuizCountLegacy = 4;

/// Minimo de palavras necessarias pra montar o quiz puro.
const int kMinWordsForQuiz = 4;

enum LessonRunnerStatus { idle, loading, error, exercising, done }

class LessonRunner extends ChangeNotifier {
  final GetLessonsByModuleUseCase _getLessons;
  final GetWordsByLessonUseCase _getWords;
  final AudioPlayerService _player;
  final SpeechService _speech;

  LessonRunner({
    required GetLessonsByModuleUseCase getLessons,
    required GetWordsByLessonUseCase getWords,
    required AudioPlayerService player,
    required SpeechService speech,
  })  : _getLessons = getLessons,
        _getWords = getWords,
        _player = player,
        _speech = speech;

  // ── Estado geral ────────────────────────────────────────────────────
  LessonRunnerStatus _status = LessonRunnerStatus.idle;
  String? _errorMessage;
  List<LessonStep> _steps = const [];
  int _index = 0;
  int _xpEarned = 0;

  /// IDs de palavras cuja curiosidade JA FOI exibida nesta sessao.
  /// Mantemos imutavel pra UI — exposto so como `View` interna.
  final Set<String> _shownCuriosities = {};

  // ── Estado do exercicio atual ───────────────────────────────────────
  int? _selectedOption;
  bool _answered = false;
  bool _wasCorrect = false;
  String _feedbackMessage = '';
  int _audioAttempts = 0;

  // ── Estado especifico de fala ───────────────────────────────────────
  String _spokenText = '';
  bool _listening = false;
  bool _speechAvailable = true;

  /// `true` apos primeiro `load` bem sucedido. Util pra testes / tela
  /// nao chamar acoes antes da carga.
  bool _loaded = false;

  // ── Getters publicos (read-only pra UI) ─────────────────────────────
  LessonRunnerStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<LessonStep> get steps => List.unmodifiable(_steps);
  int get currentIndex => _index;
  int get xpEarned => _xpEarned;

  /// XP total possivel = numero de passos x xpPerCorrect.
  int get totalPossibleXp => _steps.length * kXpPerCorrect;

  LessonStep get current => _steps[_index];

  int? get selectedOption => _selectedOption;
  bool get answered => _answered;
  bool get wasCorrect => _wasCorrect;
  String get feedbackMessage => _feedbackMessage;
  int get audioAttempts => _audioAttempts;

  String get spokenText => _spokenText;
  bool get listening => _listening;
  bool get speechAvailable => _speechAvailable;

  bool get isLastStep => _index + 1 >= _steps.length;
  double get progress =>
      _steps.isEmpty ? 0.0 : (_index + 1) / _steps.length;

  bool get isLoading => _status == LessonRunnerStatus.loading;
  bool get hasError => _status == LessonRunnerStatus.error;
  bool get isExercising => _status == LessonRunnerStatus.exercising;
  bool get isDone => _status == LessonRunnerStatus.done;

  /// Decide se mostra a curiosidade no feedback bar do passo atual.
  /// Mostra 1x por palavra apenas quando o usuario acertou.
  /// **Tem efeito colateral** (marca como exibida) — chame UMA vez por
  /// build do feedback bar.
  bool consumeShouldShowCuriosity() {
    if (!_wasCorrect) return false;
    final word = current.target;
    if (word.culturalNote.trim().isEmpty) return false;
    if (_shownCuriosities.contains(word.id)) return false;
    _shownCuriosities.add(word.id);
    return true;
  }

  /// Texto da resposta correta — exibido quando o usuario esgotou
  /// tentativas no audio (ou pulou a fala). Null em quiz (sempre acerta
  /// no fim) e quando wasCorrect = true.
  String? get correctAnswerText {
    if (_wasCorrect) return null;
    final step = current;
    if (step is AudioStep) {
      return step.data.type == AudioExerciseType.listenAndRepeat
          ? step.target.nheengatu
          : step.data.correctAnswer;
    }
    if (step is QuizStep) {
      return step.target.nheengatu;
    }
    return null;
  }

  // ── Acoes ───────────────────────────────────────────────────────────

  /// Carrega licao + palavras do modulo e monta a sequencia de passos.
  /// Se ja foi chamado uma vez com sucesso, vira no-op (idempotente).
  Future<void> load(String moduleId) async {
    if (_loaded) return;

    _status = LessonRunnerStatus.loading;
    _errorMessage = null;
    notifyListeners();

    // 1. Pega licoes do modulo (usa cache do repo se ja carregou).
    final lessonsResult = await _getLessons(moduleId);

    final lessons = lessonsResult.fold(
      onSuccess: (l) => l,
      onFailure: (Failure f) {
        _showError(f.userMessage);
        return null;
      },
    );
    if (lessons == null) return;

    if (lessons.isEmpty) {
      _showError('Nenhuma licao encontrada para este modulo.');
      return;
    }

    final lesson = lessons.first;

    // 2. Carrega palavras da licao.
    final wordsResult = await _getWords(lesson.id);
    final allWords = wordsResult.fold(
      onSuccess: (w) => w,
      onFailure: (Failure f) {
        _showError(f.userMessage);
        return null;
      },
    );
    if (allWords == null) return;

    if (allWords.isEmpty) {
      _showError('Esta licao ainda nao tem palavras cadastradas.');
      return;
    }

    // 3. Decide modo e monta steps.
    final audioWords = allWords.where((w) => w.hasAudio).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final List<LessonStep> steps;

    if (audioWords.isNotEmpty) {
      // Modo misto: preload audio + speech init.
      await _player.preload(audioWords.map((w) => w.audioUrl).toList());
      _speechAvailable = await _speech.init();
      if (_speechAvailable) {
        _speech.onStatus = _onSpeechStatus;
      }

      final audioExercises = AudioExerciseBuilder.build(audioWords);
      final quizQuestions = QuizBuilder.build(
        targets: audioWords,
        pool: audioWords,
      );

      // Pra cada saudacao: 3 exercicios de audio + 1 quiz intercalado.
      steps = <LessonStep>[];
      for (var i = 0; i < audioWords.length; i++) {
        steps.add(AudioStep(audioExercises[i * 3])); // trad
        steps.add(AudioStep(audioExercises[i * 3 + 1])); // word
        steps.add(AudioStep(audioExercises[i * 3 + 2])); // repete
        steps.add(QuizStep(quizQuestions[i]));
      }
    } else {
      // Modo quiz puro (modulos 2 e 3, ainda sem audio).
      if (allWords.length < kMinWordsForQuiz) {
        _showError(
          'Esta licao precisa de pelo menos $kMinWordsForQuiz palavras pra gerar o quiz '
          '(achei ${allWords.length}).',
        );
        return;
      }
      final quizQuestions = QuizBuilder.build(
        targets: allWords.take(kQuizCountLegacy).toList(),
        pool: allWords,
      );
      steps = quizQuestions.map((q) => QuizStep(q)).toList();
    }

    _steps = steps;
    _status = LessonRunnerStatus.exercising;
    _loaded = true;
    notifyListeners();

    _maybeAutoPlay();
  }

  void _showError(String msg) {
    _status = LessonRunnerStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  /// Toca o audio do passo atual quando aplicavel (chamada no avancar
  /// e no botao play).
  void _maybeAutoPlay() {
    final step = current;
    if (step is AudioStep) {
      _player.play(step.target.audioUrl);
    }
  }

  /// Tocar o audio do passo atual manualmente (botao de play).
  void playCurrentAudio() {
    final step = current;
    if (step is AudioStep) {
      _player.play(step.target.audioUrl);
    }
  }

  // ── Quiz tradicional ────────────────────────────────────────────────

  /// "Tenta ate acertar". 1a errada -> encoraja e desmarca; acerto -> +XP.
  void onQuizOptionTap(int index) {
    if (_answered) return;
    final step = current;
    if (step is! QuizStep) return;

    final q = step.data;
    if (index == q.correctIndex) {
      _selectedOption = index;
      _xpEarned += kXpPerCorrect;
      _answered = true;
      _wasCorrect = true;
      _feedbackMessage = '';
      notifyListeners();
    } else {
      _selectedOption = index;
      _feedbackMessage = 'Quase. Tenta outra — voce consegue.';
      notifyListeners();

      // A UI faz o "desmarcar apos 900ms" via Future.delayed — preferi
      // manter esse efeito visual na screen (responsabilidade de UI) em
      // vez de mover o timer aqui. Screen chama `clearWrongQuizSelection`
      // depois do delay.
    }
  }

  /// Chamado pela screen apos delay visual: desmarca a opcao errada e
  /// libera nova tentativa. No-op se o usuario ja respondeu nesse meio
  /// tempo.
  void clearWrongQuizSelection() {
    if (_answered) return;
    _selectedOption = null;
    notifyListeners();
  }

  // ── Audio escolha ───────────────────────────────────────────────────

  /// 1a errada -> encoraja e libera. 2a errada -> avanca sem XP.
  void onAudioOptionTap(int index) {
    if (_answered) return;
    final step = current;
    if (step is! AudioStep) return;
    final ex = step.data;

    if (index == ex.correctIndex) {
      _selectedOption = index;
      _xpEarned += kXpPerCorrect;
      _answered = true;
      _wasCorrect = true;
      _feedbackMessage = '';
      notifyListeners();
      return;
    }

    _audioAttempts++;
    if (_audioAttempts >= kMaxAudioAttempts) {
      _selectedOption = index;
      _answered = true;
      _wasCorrect = false;
      _feedbackMessage = 'Boa tentativa! A resposta era:';
    } else {
      _selectedOption = index;
      _feedbackMessage = 'Quase. Ouve mais uma vez e tenta de novo.';
    }
    notifyListeners();
  }

  /// Espelho do clearWrongQuizSelection — pra exercicios de audio que
  /// ainda tem tentativa.
  void clearWrongAudioSelection() {
    if (_answered) return;
    _selectedOption = null;
    notifyListeners();
  }

  // ── Fala ────────────────────────────────────────────────────────────

  /// Toggle do microfone. Se ja esta ouvindo, para. Senao, comeca a
  /// gravar e roda avaliacao no callback de status `done`.
  Future<void> toggleMic() async {
    if (_answered) return;

    if (!_speechAvailable) {
      // Sem microfone: avanca sem XP, com aviso gentil.
      _answered = true;
      _wasCorrect = false;
      _spokenText = '';
      _feedbackMessage =
          'Microfone indisponivel neste aparelho. Vamos seguindo.';
      notifyListeners();
      return;
    }

    if (_listening) {
      await _speech.stop();
      _listening = false;
      notifyListeners();
      return;
    }

    _listening = true;
    _spokenText = '';
    notifyListeners();

    await _speech.listen(onResult: (text) {
      _spokenText = text;
      notifyListeners();
    });
    // Avaliacao acontece em _evaluateSpeech, disparada via _onSpeechStatus.
  }

  /// Pular fala: avanca sem XP, sem acusar erro.
  void skipSpeech() {
    if (_answered) return;
    _answered = true;
    _wasCorrect = false;
    _spokenText = '';
    _feedbackMessage = 'Vamos seguindo. Era:';
    notifyListeners();
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' && _listening) {
      _listening = false;
      notifyListeners();
    } else if (status == 'done' && !_answered && !_listening) {
      _evaluateSpeech();
    }
  }

  void _evaluateSpeech() {
    if (_answered) return;
    _listening = false;
    final step = current;
    if (step is! AudioStep) return;

    final ex = step.data;
    final ok = _speech.matches(
      _spokenText,
      [ex.target.pronunciation, ex.target.nheengatu],
    );

    if (ok) {
      _xpEarned += kXpPerCorrect;
      _answered = true;
      _wasCorrect = true;
      _feedbackMessage = '';
      notifyListeners();
      return;
    }

    _audioAttempts++;
    if (_audioAttempts >= kMaxAudioAttempts) {
      _answered = true;
      _wasCorrect = false;
      _feedbackMessage = 'Boa tentativa! Era:';
    } else {
      _feedbackMessage = 'Quase. Ouve de novo e tenta mais uma vez.';
    }
    notifyListeners();
  }

  // ── Avancar ─────────────────────────────────────────────────────────

  /// Vai pro proximo passo OU finaliza a licao.
  void next() {
    if (isLastStep) {
      _status = LessonRunnerStatus.done;
      notifyListeners();
      return;
    }
    _index++;
    _selectedOption = null;
    _answered = false;
    _wasCorrect = false;
    _feedbackMessage = '';
    _audioAttempts = 0;
    _spokenText = '';
    _listening = false;
    notifyListeners();
    _maybeAutoPlay();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────

  @override
  void dispose() {
    _speech.onStatus = null;
    _player.stop();
    _speech.stop();
    super.dispose();
  }
}
