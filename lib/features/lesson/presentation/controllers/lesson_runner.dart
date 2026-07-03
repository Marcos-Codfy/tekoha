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

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../domain/builders/audio_exercise_builder.dart';
import '../../domain/builders/quiz_builder.dart';
import '../../domain/builders/trail_builder.dart';
import '../../domain/entities/audio_exercise.dart';
import '../../domain/usecases/get_lessons_by_module.dart';
import '../../domain/usecases/get_words_by_lesson.dart';
import 'lesson_outcome.dart';
import 'lesson_step.dart';

/// XP "central" exibido em mensagens e calculo de XP maximo possivel.
/// Os valores reais sao sorteados de [kXpRewardOptions] (Variable Reward).
const int kXpPerCorrect = 10;

/// Opcoes possiveis de XP por acerto. Sorteadas com [kXpRewardWeights].
/// Fundamentacao: Skinner (1953) — Variable Reward Schedules. Variancia
/// baixa em torno de 10 mantem antecipacao sem virar caca-niquel.
const List<int> kXpRewardOptions = [8, 10, 12];

/// Pesos da escolha de [kXpRewardOptions] (devem somar 100). 8 e 12 sao
/// menos frequentes que 10 — distribuicao centrada na media.
const List<int> kXpRewardWeights = [25, 50, 25];

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

  /// Fonte de aleatoriedade — em testes, passe `Random(seed)` pra obter
  /// XP variavel deterministico.
  final Random _random;

  LessonRunner({
    required GetLessonsByModuleUseCase getLessons,
    required GetWordsByLessonUseCase getWords,
    required AudioPlayerService player,
    required SpeechService speech,
    Random? random,
  })  : _getLessons = getLessons,
        _getWords = getWords,
        _player = player,
        _speech = speech,
        _random = random ?? Random();

  // ── Estado geral ────────────────────────────────────────────────────
  LessonRunnerStatus _status = LessonRunnerStatus.idle;
  String? _errorMessage;
  List<LessonStep> _steps = const [];
  int _index = 0;
  int _xpEarned = 0;

  /// IDs de palavras cuja curiosidade JA FOI exibida nesta sessao.
  /// Mantemos imutavel pra UI — exposto so como `View` interna.
  final Set<String> _shownCuriosities = {};

  /// IDs de palavras "dominadas" na sessao — acertou na 1a tentativa
  /// SEM nenhum erro previo (audio_attempts == 0 e _selectedOption nunca
  /// foi marcado como errado neste passo).
  ///
  /// Fundamentacao: SDT-Competencia (Deci & Ryan, 2000). Visivel no
  /// XpBadge da UI como "Y dominadas".
  final Set<String> _masteredInSession = {};

  /// Flag interna: o usuario ja errou alguma opcao neste exercicio?
  /// Reseta a cada `next()`. Usado pra determinar "dominou".
  bool _hadErrorInCurrentStep = false;

  /// XP ganho NO ULTIMO ACERTO (8, 10 ou 12). Reseta a cada `next()`.
  /// A UI usa pra mostrar "Boa! +N XP" com o valor real, nao o central.
  int _lastXpGained = 0;

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

  /// Quantas palavras o usuario "dominou" nesta sessao (acertou na 1a
  /// tentativa, sem nenhum erro). Visivel no XpBadge.
  int get masteredWordsCount => _masteredInSession.length;

  /// IDs das palavras dominadas na sessao — alimenta o acumulado
  /// persistido (criterio `words_mastered` das conquistas).
  Set<String> get masteredWordIds => {..._masteredInSession};

  /// Exercicios de fala (ouvir e repetir) corretos na sessao — alimenta
  /// o criterio `speech_correct` das conquistas.
  int get speechCorrectCount => _speechCorrectCount;
  int _speechCorrectCount = 0;

  /// Resultado consolidado da sessao, devolvido no pop da LessonScreen.
  LessonOutcome get outcome => LessonOutcome(
        xpEarned: _xpEarned,
        masteredWordIds: masteredWordIds,
        speechCorrectCount: _speechCorrectCount,
      );

  /// XP ganho no ULTIMO acerto (sorteado entre 8/10/12). 0 quando ainda
  /// nao houve acerto ou o passo foi resetado por `next()`.
  int get lastXpGained => _lastXpGained;

  /// XP maximo POSSIVEL da sessao: numero de exercicios pontuaveis
  /// (apresentacoes de palavra nao contam) x maior recompensa do
  /// sorteio (12). Usar a media (10) aqui gerava "+126 de ate 120" —
  /// teto exibido nunca pode ser menor que o alcancavel (ESP-008).
  int get totalPossibleXp {
    final exerciseCount =
        _steps.where((s) => s is! IntroStep).length;
    final maxReward =
        kXpRewardOptions.reduce((a, b) => a > b ? a : b);
    return exerciseCount * maxReward;
  }

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

  /// Sorteia o XP de um acerto entre [kXpRewardOptions] usando os pesos
  /// [kXpRewardWeights] (25/50/25). Variancia controlada (Variable Reward,
  /// Skinner 1953 / Eyal 2014) sustenta antecipacao sem virar caca-niquel.
  int _drawXpReward() {
    final roll = _random.nextInt(100); // 0..99
    var cumulative = 0;
    for (var i = 0; i < kXpRewardOptions.length; i++) {
      cumulative += kXpRewardWeights[i];
      if (roll < cumulative) return kXpRewardOptions[i];
    }
    // Fallback (nunca atinge se pesos somam 100).
    return kXpPerCorrect;
  }

  /// Marca a palavra atual como "dominada" se nao houve nenhum erro
  /// neste exercicio. SDT-Competencia.
  void _maybeMarkMastered() {
    if (!_hadErrorInCurrentStep) {
      _masteredInSession.add(current.target.id);
    }
  }

  // ── Acoes ───────────────────────────────────────────────────────────

  /// Carrega licao + palavras do modulo e monta a sequencia de passos.
  /// Se ja foi chamado uma vez com sucesso, vira no-op (idempotente).
  ///
  /// [stageIndex] (opcional): quando a sessao vem da trilha (ESP-005),
  /// roda so as palavras daquela etapa. [moduleOrder] escolhe a divisao
  /// curada do TrailBuilder. Sem [stageIndex], roda a licao inteira
  /// (comportamento original).
  Future<void> load(
    String moduleId, {
    int? stageIndex,
    int moduleOrder = 0,
  }) async {
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

    // Recorte da etapa da trilha (ESP-005): a sessao roda so as
    // palavras da etapa pedida. Os DISTRATORES continuam vindo da
    // licao inteira — variedade sem crescer o numero de alternativas
    // (cap de 4 no builder, ESP-004).
    var sessionWords = audioWords;
    if (stageIndex != null) {
      final stages = TrailBuilder.build(allWords, moduleOrder: moduleOrder);
      if (stageIndex >= 0 && stageIndex < stages.length) {
        sessionWords = stages[stageIndex]
            .words
            .where((w) => w.hasAudio)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
      }
    }

    final List<LessonStep> steps;

    if (sessionWords.isNotEmpty) {
      // Modo misto: preload audio + speech init (so da etapa atual).
      await _player.preload(sessionWords.map((w) => w.audioUrl).toList());
      _speechAvailable = await _speech.init();
      if (_speechAvailable) {
        _speech.onStatus = _onSpeechStatus;
      }

      final audioExercises =
          AudioExerciseBuilder.build(sessionWords, pool: allWords);
      final quizQuestions = QuizBuilder.build(
        targets: sessionWords,
        pool: allWords,
      );

      // Pra cada palavra: APRESENTACAO (palavra nova, ESP-008) +
      // 3 exercicios de audio + 1 quiz intercalado. A apresentacao
      // mostra traducao/pronuncia/curiosidade ANTES de cobrar.
      steps = <LessonStep>[];
      for (var i = 0; i < sessionWords.length; i++) {
        steps.add(IntroStep(sessionWords[i]));
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
  /// e no botao play). Apresentacao de palavra nova tambem toca — a
  /// pessoa OUVE a palavra junto com a ficha (pedagogia oral, D1).
  void _maybeAutoPlay() {
    final step = current;
    if (step is AudioStep || step is IntroStep) {
      _player.play(step.target.audioUrl);
    }
  }

  /// Tocar o audio do passo atual manualmente (botao de play).
  void playCurrentAudio() {
    final step = current;
    if (step is AudioStep || step is IntroStep) {
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
      _lastXpGained = _drawXpReward();
      _xpEarned += _lastXpGained;
      _maybeMarkMastered();
      _answered = true;
      _wasCorrect = true;
      _feedbackMessage = '';
      notifyListeners();
    } else {
      _selectedOption = index;
      _hadErrorInCurrentStep = true;
      _feedbackMessage = 'Quase! Tenta outra — você consegue.';
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
      _lastXpGained = _drawXpReward();
      _xpEarned += _lastXpGained;
      _maybeMarkMastered();
      _answered = true;
      _wasCorrect = true;
      _feedbackMessage = '';
      notifyListeners();
      return;
    }

    _audioAttempts++;
    _hadErrorInCurrentStep = true;
    if (_audioAttempts >= kMaxAudioAttempts) {
      _selectedOption = index;
      _answered = true;
      _wasCorrect = false;
      _feedbackMessage = 'Quase lá! A resposta certa é:';
    } else {
      _selectedOption = index;
      _feedbackMessage = 'Quase! Ouve mais uma vez e tenta de novo.';
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
          'Microfone indisponível neste aparelho. Vamos seguir.';
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
    _feedbackMessage = 'A resposta era:';
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
      _lastXpGained = _drawXpReward();
      _xpEarned += _lastXpGained;
      _speechCorrectCount++;
      _maybeMarkMastered();
      _answered = true;
      _wasCorrect = true;
      _feedbackMessage = '';
      notifyListeners();
      return;
    }

    _audioAttempts++;
    _hadErrorInCurrentStep = true;
    if (_audioAttempts >= kMaxAudioAttempts) {
      _answered = true;
      _wasCorrect = false;
      _feedbackMessage = 'Quase lá! A resposta certa é:';
    } else {
      _feedbackMessage = 'Quase! Ouve de novo e tenta mais uma vez.';
    }
    notifyListeners();
  }

  // ── Avancar ─────────────────────────────────────────────────────────

  /// Vai pro proximo passo OU finaliza a licao.
  void next() {
    // Saindo da apresentacao de palavra nova: a curiosidade ja foi
    // exibida na ficha — nao repetir no feedback dos exercicios.
    if (_steps.isNotEmpty && current is IntroStep) {
      _shownCuriosities.add(current.target.id);
    }
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
    _hadErrorInCurrentStep = false;
    _lastXpGained = 0;
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
