// lib/presentation/screens/lesson/lesson_screen.dart
// Tela de execucao de uma licao. Tem DOIS modos, decididos automaticamente
// a partir do conteudo da licao:
//
//   ┌─ MODO MISTO (audio + quiz) ─ se a licao tem palavras com audio_url ──
//   │  Pra cada saudacao com audio, gera 4 exercicios em sequencia:
//   │    1. Ouve Nheengatu -> escolhe a traducao PT
//   │    2. Ouve Nheengatu -> escolhe a palavra Nheengatu
//   │    3. Ouve e repete falando (microfone)
//   │    4. Quiz tradicional PT -> Nheengatu
//   │  Com as 3 saudacoes do Airtable -> 12 exercicios, max 120 XP.
//   └────────────────────────────────────────────────────────────────────
//
//   ┌─ MODO QUIZ PURO (legacy) ─ se nenhuma palavra tem audio ───────────
//   │  Mantem o fluxo original do MVP: 4 perguntas de quiz com as 4
//   │  primeiras palavras como targets e todas como pool de distratores.
//   │  Cobre os modulos 2 e 3 quando forem desbloqueados.
//   └────────────────────────────────────────────────────────────────────
//
// REGRAS DE UX (alinhadas com o Marcos):
//   - Acerto    = +10 XP, mostra feedback positivo + curiosidade cultural
//                 (so na 1a vez de cada saudacao na sessao).
//   - Erro quiz = mostra mensagem encorajadora ("Quase. Tenta outra.") e
//                 libera nova tentativa ATE acertar.
//   - Erro audio= 1a tentativa mostra "Ouve de novo" e libera; 2a tentativa
//                 avanca sem XP com mensagem positiva ("Boa tentativa! A
//                 resposta era: X.") — nao acusa o usuario de errar.
//   - Pular fala= avanca sem XP, igual a 2a tentativa esgotada.
//
// XP e LOCAL (nao persiste). Sprint 5 conecta no Firestore.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/audio_exercise_builder.dart';
import '../../../core/utils/quiz_builder.dart';
import '../../../data/models/audio_exercise.dart';
import '../../../data/models/word_model.dart';
import '../../../data/services/audio_player_service.dart';
import '../../../data/services/speech_service.dart';
import '../../providers/content_provider.dart';
import '../../widgets/error_view.dart';

const int _kXpPerCorrect = 10;
const int _kMaxAudioAttempts = 2;

/// Quantas perguntas de quiz no modo "quiz puro" (modulos sem audio).
const int _kQuizCountLegacy = 4;

class LessonScreen extends StatefulWidget {
  final String moduleId;
  final String moduleName;

  const LessonScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

// ── Modelo interno de exercicio (sealed pra match exaustivo) ────────────
// Privado a esta tela porque ninguem fora precisa saber. Aglutina os dois
// tipos (audio e quiz) numa sequencia unica que a tela percorre linearmente.

sealed class _Step {
  WordModel get target;
}

class _AudioStep extends _Step {
  final AudioExercise data;
  _AudioStep(this.data);
  @override
  WordModel get target => data.target;
}

class _QuizStep extends _Step {
  final QuizQuestion data;
  _QuizStep(this.data);
  @override
  WordModel get target => data.word;
}

enum _ScreenState { loading, error, exercising, done }

class _LessonScreenState extends State<LessonScreen> {
  // ── Fluxo geral da tela ─────────────────────────────────────────────
  _ScreenState _state = _ScreenState.loading;
  String? _errorMessage;

  List<_Step> _steps = const [];
  int _index = 0;
  int _xpEarned = 0;

  /// IDs de saudacoes cuja curiosidade ja foi exibida nesta sessao.
  /// Garante que [cultural_note] aparece UMA vez por saudacao, mesmo
  /// que ela apareca em varios exercicios seguidos.
  final Set<String> _shownCuriosities = {};

  // ── Estado do exercicio atual ───────────────────────────────────────
  int? _selectedOption;       // opcao tocada (tipos de escolha)
  bool _answered = false;     // exercicio "resolvido" (acertou ou esgotou)
  bool _wasCorrect = false;   // marcou XP?
  String _feedbackMessage = ''; // mensagem encorajadora (pos-erro)

  /// Quantas tentativas o usuario gastou no exercicio atual de audio.
  /// Quiz nao usa (no quiz ele pode tentar infinitas vezes).
  int _audioAttempts = 0;

  // Estado especifico do exercicio de fala.
  String _spokenText = '';
  bool _listening = false;
  bool _speechAvailable = true;

  // ── Servicos (singletons) ───────────────────────────────────────────
  final _player = AudioPlayerService.instance;
  final _speech = SpeechService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    // Limpa o callback de status antes de qualquer outra coisa, senao o
    // motor pode disparar um evento depois do widget ja desmontado.
    _speech.onStatus = null;
    _player.stop();
    _speech.stop();
    super.dispose();
  }

  /// Callback do SpeechService disparado quando o motor muda de status.
  /// E o que torna a UI responsiva:
  /// - `notListening`: motor parou de capturar audio. Devolvemos o botao
  ///   ao estado normal IMEDIATAMENTE pra o usuario ver que a gravacao
  ///   acabou (o sistema operacional ja tocou o som de fim).
  /// - `done`: sessao terminou de verdade — o resultado final ja chegou
  ///   via onResult. So agora avaliamos pra ter o texto completo.
  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' && _listening) {
      setState(() => _listening = false);
    } else if (status == 'done' && !_answered && !_listening) {
      _evaluateSpeech();
    }
  }

  // ── Carga inicial: decide modo, baixa audios, monta sequencia ───────
  Future<void> _load() async {
    final content = context.read<ContentProvider>();

    try {
      // 1. Pega a primeira licao do modulo.
      final lessons = await content.loadLessonsForModule(widget.moduleId);
      if (lessons.isEmpty) {
        _showError('Nenhuma licao encontrada para este modulo.');
        return;
      }
      final lesson = lessons.first;

      // 2. Carrega palavras da licao.
      final allWords = await content.loadWordsForLesson(lesson.id);
      if (allWords.isEmpty) {
        _showError('Esta licao ainda nao tem palavras cadastradas.');
        return;
      }

      // 3. Separa as palavras COM audio (vao gerar exercicios mistos).
      //    Ordena por `order` pra garantir ara(1), karuka(2), pituna(3).
      final audioWords = allWords.where((w) => w.hasAudio).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      List<_Step> steps;

      if (audioWords.isNotEmpty) {
        // ── MODO MISTO ───────────────────────────────────────────────
        // Pre-baixa os MP3 e pede permissao de microfone.
        await _player.preload(audioWords.map((w) => w.audioUrl).toList());
        _speechAvailable = await _speech.init();
        if (_speechAvailable) {
          // Conecta o callback de status: e quem decide quando o botao
          // do mic volta ao normal (notListening) e quando a avaliacao
          // roda (done).
          _speech.onStatus = _onSpeechStatus;
        }

        // Gera 3 exercicios de audio por palavra (escolha trad, escolha
        // palavra, repetir) — total 3 * N.
        final audioExercises = AudioExerciseBuilder.build(audioWords);

        // Gera 1 quiz por saudacao, usando SOMENTE as proprias saudacoes
        // como pool — quem chega ate aqui ja exercitou as 3.
        final quizQuestions = QuizBuilder.build(
          targets: audioWords,
          pool: audioWords,
        );

        // Intercala: pra cada saudacao i, 3 audios consecutivos + 1 quiz.
        steps = <_Step>[];
        for (var i = 0; i < audioWords.length; i++) {
          steps.add(_AudioStep(audioExercises[i * 3]));     // trad
          steps.add(_AudioStep(audioExercises[i * 3 + 1])); // palavra
          steps.add(_AudioStep(audioExercises[i * 3 + 2])); // repete
          steps.add(_QuizStep(quizQuestions[i]));
        }
      } else {
        // ── MODO QUIZ PURO (modulos 2 e 3) ───────────────────────────
        if (allWords.length < 4) {
          _showError(
            'Esta licao precisa de pelo menos 4 palavras pra gerar o quiz '
            '(achei ${allWords.length}).',
          );
          return;
        }
        final quizQuestions = QuizBuilder.build(
          targets: allWords.take(_kQuizCountLegacy).toList(),
          pool: allWords,
        );
        steps = quizQuestions.map((q) => _QuizStep(q)).toList();
      }

      if (!mounted) return;
      setState(() {
        _steps = steps;
        _state = _ScreenState.exercising;
      });

      // Se o primeiro exercicio e de audio, ja toca pra dar o tom.
      _maybeAutoPlay();
    } catch (_) {
      _showError('Erro ao carregar a licao. Verifique sua conexao.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() {
      _state = _ScreenState.error;
      _errorMessage = msg;
    });
  }

  _Step get _current => _steps[_index];

  void _maybeAutoPlay() {
    final step = _current;
    if (step is _AudioStep) {
      _player.play(step.target.audioUrl);
    }
  }

  // ── Acoes do usuario ────────────────────────────────────────────────

  void _playCurrentAudio() {
    final step = _current;
    if (step is _AudioStep) {
      _player.play(step.target.audioUrl);
    }
  }

  /// Quiz: comportamento "tenta ate acertar" com encorajamento.
  void _onQuizOptionTap(int index) {
    if (_answered) return;
    final q = (_current as _QuizStep).data;

    if (index == q.correctIndex) {
      setState(() {
        _selectedOption = index;
        _xpEarned += _kXpPerCorrect;
        _answered = true;
        _wasCorrect = true;
        _feedbackMessage = '';
      });
    } else {
      setState(() {
        _selectedOption = index;
        _feedbackMessage = 'Quase. Tenta outra — voce consegue.';
      });
      // Apos 900ms desmarca a opcao errada e libera nova tentativa.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _answered) return;
        setState(() {
          _selectedOption = null;
        });
      });
    }
  }

  /// Audio (escolha): 1a errada -> incentiva e libera; 2a errada -> avanca.
  void _onAudioOptionTap(int index) {
    if (_answered) return;
    final ex = (_current as _AudioStep).data;

    if (index == ex.correctIndex) {
      setState(() {
        _selectedOption = index;
        _xpEarned += _kXpPerCorrect;
        _answered = true;
        _wasCorrect = true;
        _feedbackMessage = '';
      });
      return;
    }

    // Errou.
    _audioAttempts++;
    if (_audioAttempts >= _kMaxAudioAttempts) {
      // Esgotou: avanca sem XP, sem dizer "errou".
      setState(() {
        _selectedOption = index;
        _answered = true;
        _wasCorrect = false;
        _feedbackMessage = 'Boa tentativa! A resposta era:';
      });
    } else {
      // Tem mais uma chance.
      setState(() {
        _selectedOption = index;
        _feedbackMessage = 'Quase. Ouve mais uma vez e tenta de novo.';
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        if (!mounted || _answered) return;
        setState(() {
          _selectedOption = null;
        });
      });
    }
  }

  /// Audio repete (microfone): liga/desliga e avalia ao parar.
  Future<void> _toggleMic() async {
    if (_answered) return;
    if (!_speechAvailable) {
      // Microfone indisponivel no aparelho: avanca sem XP, com aviso gentil.
      setState(() {
        _answered = true;
        _wasCorrect = false;
        _spokenText = '';
        _feedbackMessage =
            'Microfone indisponivel neste aparelho. Vamos seguindo.';
      });
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _listening = true;
      _spokenText = '';
    });
    await _speech.listen(onResult: (text) {
      if (!mounted) return;
      setState(() => _spokenText = text);
    });
    // A avaliacao agora e disparada pelo callback de status do motor de
    // voz (_onSpeechStatus), nao por um delay fixo. Isso deixa o botao
    // responsivo: vira "mic" assim que o motor para de capturar
    // (notListening) e a avaliacao roda quando a sessao termina (done).
  }

  void _evaluateSpeech() {
    if (!mounted || _answered) return;
    setState(() => _listening = false);
    final ex = (_current as _AudioStep).data;
    final ok = _speech.matches(
      _spokenText,
      [ex.target.pronunciation, ex.target.nheengatu],
    );

    if (ok) {
      setState(() {
        _xpEarned += _kXpPerCorrect;
        _answered = true;
        _wasCorrect = true;
        _feedbackMessage = '';
      });
      return;
    }

    _audioAttempts++;
    if (_audioAttempts >= _kMaxAudioAttempts) {
      setState(() {
        _answered = true;
        _wasCorrect = false;
        _feedbackMessage = 'Boa tentativa! Era:';
      });
    } else {
      setState(() {
        _feedbackMessage = 'Quase. Ouve de novo e tenta mais uma vez.';
      });
    }
  }

  /// Pular fala: avanca sem XP, com mensagem neutra.
  void _skipSpeech() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _wasCorrect = false;
      _spokenText = '';
      _feedbackMessage = 'Vamos seguindo. Era:';
    });
  }

  void _next() {
    if (_index + 1 >= _steps.length) {
      setState(() => _state = _ScreenState.done);
      return;
    }
    setState(() {
      _index++;
      _selectedOption = null;
      _answered = false;
      _wasCorrect = false;
      _feedbackMessage = '';
      _audioAttempts = 0;
      _spokenText = '';
      _listening = false;
    });
    _maybeAutoPlay();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.moduleName),
        actions: [
          if (_state == _ScreenState.exercising)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+$_xpEarned XP',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: switch (_state) {
        _ScreenState.loading => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        _ScreenState.error => ErrorView(
            message: _errorMessage ?? 'Erro inesperado.',
            onRetry: () => Navigator.of(context).pop(),
            retryLabel: 'Voltar',
            icon: Icons.error_outline,
          ),
        _ScreenState.exercising => _buildExerciseScaffold(),
        _ScreenState.done => _buildDone(),
      },
    );
  }

  Widget _buildExerciseScaffold() {
    final progress = (_index + 1) / _steps.length;
    final step = _current;

    return SafeArea(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Text(
                  'Exercicio ${_index + 1} de ${_steps.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: switch (step) {
                _AudioStep s => _buildAudioStep(s),
                _QuizStep s => _buildQuizStep(s),
              },
            ),
          ),
          if (_answered) _buildFeedbackBar(step),
        ],
      ),
    );
  }

  // ── AUDIO STEP ──────────────────────────────────────────────────────
  Widget _buildAudioStep(_AudioStep step) {
    final ex = step.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _audioInstruction(ex.type),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (ex.target.pronunciation.isNotEmpty)
          _PronunciationHint(text: ex.target.pronunciation),
        const SizedBox(height: 20),
        _PlayButton(onTap: _playCurrentAudio),
        const SizedBox(height: 28),
        if (ex.type == AudioExerciseType.listenAndRepeat)
          _buildSpeechBody(ex)
        else
          _buildAudioOptions(ex),
        // Mensagem encorajadora flutua acima do feedback bar quando o
        // usuario errou mas ainda tem tentativas (nao "answered" ainda).
        if (_feedbackMessage.isNotEmpty && !_answered) ...[
          const SizedBox(height: 16),
          _EncouragementText(text: _feedbackMessage),
        ],
      ],
    );
  }

  String _audioInstruction(AudioExerciseType type) {
    switch (type) {
      case AudioExerciseType.listenChooseTranslation:
        return 'Ouca e escolha a traducao';
      case AudioExerciseType.listenChooseWord:
        return 'Ouca e escolha a palavra que voce ouviu';
      case AudioExerciseType.listenAndRepeat:
        return 'Ouca e repita em voz alta';
    }
  }

  Widget _buildAudioOptions(AudioExercise ex) {
    return Column(
      children: List.generate(ex.options.length, (i) {
        final isSelected = _selectedOption == i;
        final isCorrect = i == ex.correctIndex;
        Color borderColor = AppColors.border;
        Color bgColor = AppColors.surface;
        if (_answered && isCorrect) {
          borderColor = AppColors.correct;
          bgColor = const Color(0x1A2E7D32);
        } else if (_answered && isSelected && !isCorrect) {
          borderColor = AppColors.wrong;
          bgColor = const Color(0x1AB5451B);
        } else if (!_answered && isSelected) {
          // Feedback de "errou, libera de novo" — destaca a opcao errada
          // brevemente em vermelho-suave.
          borderColor = AppColors.wrong;
          bgColor = const Color(0x14B5451B);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _answered ? null : () => _onAudioOptionTap(i),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.8),
                ),
                child: Text(
                  ex.options[i],
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpeechBody(AudioExercise ex) {
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleMic,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening ? AppColors.wrong : AppColors.primary,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _listening ? Icons.stop_rounded : Icons.mic_rounded,
              color: AppColors.textOnPrimary,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Nao expomos a transcricao porque o motor de voz nunca acerta 100%
        // o Nheengatu (usa locale pt_BR como aproximacao). Ver a transcricao
        // crua deixa o usuario ansioso pra refazer ate ficar "fiel", o que
        // nao e o ponto do exercicio. Mantemos so o estado da escuta.
        Text(
          _listening ? 'Ouvindo... fale agora' : 'Toque no microfone e repita',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (!_answered)
          TextButton(
            onPressed: _skipSpeech,
            child: const Text('Nao consegui / Pular'),
          ),
      ],
    );
  }

  // ── QUIZ STEP ───────────────────────────────────────────────────────
  Widget _buildQuizStep(_QuizStep step) {
    final q = step.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Como se diz em Nheengatu...',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '"${q.word.translation}"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
        for (int i = 0; i < q.options.length; i++) ...[
          _QuizOptionButton(
            text: q.options[i],
            state: _stateForQuizOption(i, q.correctIndex),
            onTap: _answered ? null : () => _onQuizOptionTap(i),
          ),
          const SizedBox(height: 12),
        ],
        if (_feedbackMessage.isNotEmpty && !_answered) ...[
          const SizedBox(height: 4),
          _EncouragementText(text: _feedbackMessage),
        ],
      ],
    );
  }

  _QuizOptionState _stateForQuizOption(int index, int correctIndex) {
    if (_selectedOption == null) return _QuizOptionState.idle;
    if (index == _selectedOption && index == correctIndex) {
      return _QuizOptionState.correct;
    }
    if (index == _selectedOption && index != correctIndex) {
      return _QuizOptionState.wrong;
    }
    if (_answered && index == correctIndex) {
      return _QuizOptionState.correct;
    }
    return _QuizOptionState.idle;
  }

  // ── BARRA DE FEEDBACK (apos respondido) ─────────────────────────────
  Widget _buildFeedbackBar(_Step step) {
    final word = step.target;
    final showCuriosity = _wasCorrect &&
        word.culturalNote.trim().isNotEmpty &&
        !_shownCuriosities.contains(word.id);
    if (showCuriosity) {
      _shownCuriosities.add(word.id);
    }

    // Texto da resposta correta (mostrada quando esgotou tentativas no audio).
    String? correctAnswerText;
    if (!_wasCorrect) {
      if (step is _AudioStep) {
        correctAnswerText = step.data.type == AudioExerciseType.listenAndRepeat
            ? step.data.target.nheengatu
            : step.data.correctAnswer;
      } else if (step is _QuizStep) {
        correctAnswerText = step.data.word.nheengatu;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: _wasCorrect
            ? const Color(0x1A2E7D32) // verde 10%
            : const Color(0x14B5451B), // urucum 8%
        border: Border(
          top: BorderSide(
            color: _wasCorrect
                ? AppColors.correct.withOpacity(0.25)
                : AppColors.primary.withOpacity(0.25),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _wasCorrect ? Icons.check_circle : Icons.favorite,
                color:
                    _wasCorrect ? AppColors.correct : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                _wasCorrect
                    ? 'Boa! +$_kXpPerCorrect XP'
                    : (_feedbackMessage.isNotEmpty
                        ? _feedbackMessage
                        : 'Vamos seguindo.'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _wasCorrect
                      ? AppColors.correct
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          if (!_wasCorrect && correctAnswerText != null) ...[
            const SizedBox(height: 6),
            Text(
              correctAnswerText,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_wasCorrect && word.pronunciation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Pronuncia: ${word.pronunciation}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (showCuriosity) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      word.culturalNote,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(
                _index + 1 >= _steps.length ? 'Ver resultado' : 'Continuar',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TELA FINAL ──────────────────────────────────────────────────────
  Widget _buildDone() {
    final totalPossible = _steps.length * _kXpPerCorrect;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 96, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Licao concluida!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '+$_xpEarned XP',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            Text(
              'de $totalPossible XP possiveis',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'XP ainda nao e salvo no servidor.\n'
              'Persistencia no Firestore entra na Sprint 5.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para a Pratica'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets privados ─────────────────────────────────────────────────

enum _QuizOptionState { idle, correct, wrong }

class _QuizOptionButton extends StatelessWidget {
  final String text;
  final _QuizOptionState state;
  final VoidCallback? onTap;

  const _QuizOptionButton({
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    final IconData? icon;

    switch (state) {
      case _QuizOptionState.idle:
        background = AppColors.surface;
        foreground = AppColors.textPrimary;
        border = AppColors.primary;
        icon = null;
      case _QuizOptionState.correct:
        background = AppColors.correct.withOpacity(0.15);
        foreground = AppColors.correct;
        border = AppColors.correct;
        icon = Icons.check_circle;
      case _QuizOptionState.wrong:
        background = const Color(0x1AB5451B);
        foreground = AppColors.wrong;
        border = AppColors.wrong;
        icon = Icons.refresh;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: foreground, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Balao com a pronuncia aportuguesada (dica visual estilo Duolingo).
class _PronunciationHint extends StatelessWidget {
  final String text;
  const _PronunciationHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x14B5451B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.record_voice_over,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botao circular grande de tocar o audio.
class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.volume_up_rounded,
            color: AppColors.textOnPrimary,
            size: 40,
          ),
        ),
      ),
    );
  }
}

/// Linha de texto encorajador exibido apos erro (antes de responder).
class _EncouragementText extends StatelessWidget {
  final String text;
  const _EncouragementText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
