// lib/features/lesson/presentation/screens/lesson_screen.dart
// Camada: Presentation (Lesson).
//
// Tela de execucao de uma licao. Diferente do legado, NAO contem logica
// de negocio — toda a maquina de estado (XP, tentativas, mic, etc) vive
// no [LessonRunner]. Esta tela so:
//   - Cria o Runner via ChangeNotifierProvider (auto-disposed no pop)
//   - Escuta mudancas via Consumer
//   - Renderiza widget apropriado por status
//   - Dispara acoes (botoes -> metodos do runner)
//   - Gerencia timers visuais (delay pra desmarcar opcao errada)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../di/injection.dart';
import '../../../../presentation/widgets/error_view.dart';
import '../../../../data/services/audio_player_service.dart';
import '../../../../data/services/speech_service.dart';
import '../../domain/entities/audio_exercise.dart';
import '../../domain/usecases/get_lessons_by_module.dart';
import '../../domain/usecases/get_words_by_lesson.dart';
import '../controllers/lesson_runner.dart';
import '../controllers/lesson_step.dart';

class LessonScreen extends StatelessWidget {
  final String moduleId;
  final String moduleName;

  const LessonScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  Widget build(BuildContext context) {
    // Cria o Runner uma vez por instancia desta screen. ChangeNotifier
    // sera disposed automaticamente quando esta tela sair da arvore.
    return ChangeNotifierProvider(
      create: (_) => LessonRunner(
        getLessons: sl<GetLessonsByModuleUseCase>(),
        getWords: sl<GetWordsByLessonUseCase>(),
        player: sl<AudioPlayerService>(),
        speech: sl<SpeechService>(),
      )..load(moduleId),
      child: _LessonScreenBody(moduleName: moduleName),
    );
  }
}

class _LessonScreenBody extends StatelessWidget {
  final String moduleName;
  const _LessonScreenBody({required this.moduleName});

  @override
  Widget build(BuildContext context) {
    final runner = context.watch<LessonRunner>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(moduleName),
        actions: [
          if (runner.isExercising) _XpBadge(xp: runner.xpEarned),
        ],
      ),
      body: () {
        if (runner.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (runner.hasError) {
          return ErrorView(
            message: runner.errorMessage ?? 'Erro inesperado.',
            onRetry: () => Navigator.of(context).pop(),
            retryLabel: 'Voltar',
            icon: Icons.error_outline,
          );
        }
        if (runner.isDone) {
          return _DoneView(
            xpEarned: runner.xpEarned,
            totalPossible: runner.totalPossibleXp,
            onBack: () => Navigator.of(context).pop(),
          );
        }
        return _ExerciseScaffold(runner: runner);
      }(),
    );
  }
}

// ── XP badge no AppBar ──────────────────────────────────────────────────

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+$xp XP',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scaffold do exercicio (barra de progresso + body + feedback) ────────

class _ExerciseScaffold extends StatefulWidget {
  final LessonRunner runner;
  const _ExerciseScaffold({required this.runner});

  @override
  State<_ExerciseScaffold> createState() => _ExerciseScaffoldState();
}

class _ExerciseScaffoldState extends State<_ExerciseScaffold> {
  /// Apos 900ms desmarcamos a opcao errada e liberamos nova tentativa.
  /// Mantemos isso na Screen (timing visual) em vez do Runner.
  void _scheduleClearWrongSelection({required bool isAudio}) {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (isAudio) {
        widget.runner.clearWrongAudioSelection();
      } else {
        widget.runner.clearWrongQuizSelection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final runner = widget.runner;
    final step = runner.current;

    return SafeArea(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: runner.progress,
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
                  'Exercicio ${runner.currentIndex + 1} de ${runner.steps.length}',
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
                AudioStep s => _AudioStepView(
                    step: s,
                    runner: runner,
                    onWrongTap: () =>
                        _scheduleClearWrongSelection(isAudio: true),
                  ),
                QuizStep s => _QuizStepView(
                    step: s,
                    runner: runner,
                    onWrongTap: () =>
                        _scheduleClearWrongSelection(isAudio: false),
                  ),
              },
            ),
          ),
          if (runner.answered) _FeedbackBar(runner: runner),
        ],
      ),
    );
  }
}

// ── Step de audio (3 variantes) ─────────────────────────────────────────

class _AudioStepView extends StatelessWidget {
  final AudioStep step;
  final LessonRunner runner;
  final VoidCallback onWrongTap;

  const _AudioStepView({
    required this.step,
    required this.runner,
    required this.onWrongTap,
  });

  @override
  Widget build(BuildContext context) {
    final ex = step.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _instructionFor(ex.type),
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
        _PlayButton(onTap: runner.playCurrentAudio),
        const SizedBox(height: 28),
        if (ex.type == AudioExerciseType.listenAndRepeat)
          _SpeechBody(runner: runner)
        else
          _AudioOptions(
            ex: ex,
            runner: runner,
            onWrongTap: onWrongTap,
          ),
        if (runner.feedbackMessage.isNotEmpty && !runner.answered) ...[
          const SizedBox(height: 16),
          _EncouragementText(text: runner.feedbackMessage),
        ],
      ],
    );
  }

  String _instructionFor(AudioExerciseType type) {
    switch (type) {
      case AudioExerciseType.listenChooseTranslation:
        return 'Ouca e escolha a traducao';
      case AudioExerciseType.listenChooseWord:
        return 'Ouca e escolha a palavra que voce ouviu';
      case AudioExerciseType.listenAndRepeat:
        return 'Ouca e repita em voz alta';
    }
  }
}

class _AudioOptions extends StatelessWidget {
  final AudioExercise ex;
  final LessonRunner runner;
  final VoidCallback onWrongTap;

  const _AudioOptions({
    required this.ex,
    required this.runner,
    required this.onWrongTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(ex.options.length, (i) {
        final isSelected = runner.selectedOption == i;
        final isCorrect = i == ex.correctIndex;
        Color borderColor = AppColors.border;
        Color bgColor = AppColors.surface;
        if (runner.answered && isCorrect) {
          borderColor = AppColors.correct;
          bgColor = const Color(0x1A2E7D32);
        } else if (runner.answered && isSelected && !isCorrect) {
          borderColor = AppColors.wrong;
          bgColor = const Color(0x1AB5451B);
        } else if (!runner.answered && isSelected) {
          borderColor = AppColors.wrong;
          bgColor = const Color(0x14B5451B);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: runner.answered
                  ? null
                  : () {
                      runner.onAudioOptionTap(i);
                      if (i != ex.correctIndex && !runner.answered) {
                        onWrongTap();
                      }
                    },
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
}

class _SpeechBody extends StatelessWidget {
  final LessonRunner runner;
  const _SpeechBody({required this.runner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: runner.toggleMic,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: runner.listening ? AppColors.wrong : AppColors.primary,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              runner.listening ? Icons.stop_rounded : Icons.mic_rounded,
              color: AppColors.textOnPrimary,
              size: 44,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          runner.listening
              ? 'Ouvindo... fale agora'
              : 'Toque no microfone e repita',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (!runner.answered)
          TextButton(
            onPressed: runner.skipSpeech,
            child: const Text('Nao consegui / Pular'),
          ),
      ],
    );
  }
}

// ── Quiz step ───────────────────────────────────────────────────────────

class _QuizStepView extends StatelessWidget {
  final QuizStep step;
  final LessonRunner runner;
  final VoidCallback onWrongTap;

  const _QuizStepView({
    required this.step,
    required this.runner,
    required this.onWrongTap,
  });

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.primary.withValues(alpha: 0.08),
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
            state: _stateForQuizOption(i, q.correctIndex, runner),
            onTap: runner.answered
                ? null
                : () {
                    runner.onQuizOptionTap(i);
                    if (i != q.correctIndex && !runner.answered) {
                      onWrongTap();
                    }
                  },
          ),
          const SizedBox(height: 12),
        ],
        if (runner.feedbackMessage.isNotEmpty && !runner.answered) ...[
          const SizedBox(height: 4),
          _EncouragementText(text: runner.feedbackMessage),
        ],
      ],
    );
  }

  _QuizOptionState _stateForQuizOption(
    int index,
    int correctIndex,
    LessonRunner runner,
  ) {
    if (runner.selectedOption == null) return _QuizOptionState.idle;
    if (index == runner.selectedOption && index == correctIndex) {
      return _QuizOptionState.correct;
    }
    if (index == runner.selectedOption && index != correctIndex) {
      return _QuizOptionState.wrong;
    }
    if (runner.answered && index == correctIndex) {
      return _QuizOptionState.correct;
    }
    return _QuizOptionState.idle;
  }
}

// ── Feedback bar (apos respondido) ──────────────────────────────────────

class _FeedbackBar extends StatelessWidget {
  final LessonRunner runner;
  const _FeedbackBar({required this.runner});

  @override
  Widget build(BuildContext context) {
    final word = runner.current.target;
    final showCuriosity = runner.consumeShouldShowCuriosity();
    final correctText = runner.correctAnswerText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: runner.wasCorrect
            ? const Color(0x1A2E7D32)
            : const Color(0x14B5451B),
        border: Border(
          top: BorderSide(
            color: runner.wasCorrect
                ? AppColors.correct.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.25),
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
                runner.wasCorrect ? Icons.check_circle : Icons.favorite,
                color: runner.wasCorrect
                    ? AppColors.correct
                    : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                runner.wasCorrect
                    ? 'Boa! +$kXpPerCorrect XP'
                    : (runner.feedbackMessage.isNotEmpty
                        ? runner.feedbackMessage
                        : 'Vamos seguindo.'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: runner.wasCorrect
                      ? AppColors.correct
                      : AppColors.primary,
                ),
              ),
            ],
          ),
          if (!runner.wasCorrect && correctText != null) ...[
            const SizedBox(height: 6),
            Text(
              correctText,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (runner.wasCorrect && word.pronunciation.isNotEmpty) ...[
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
            _CuriosityCard(text: word.culturalNote),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: runner.next,
              child: Text(
                runner.isLastStep ? 'Ver resultado' : 'Continuar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CuriosityCard extends StatelessWidget {
  final String text;
  const _CuriosityCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tela final (parabens + XP) ──────────────────────────────────────────

class _DoneView extends StatelessWidget {
  final int xpEarned;
  final int totalPossible;
  final VoidCallback onBack;

  const _DoneView({
    required this.xpEarned,
    required this.totalPossible,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events,
                size: 96, color: AppColors.primary),
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
              '+$xpEarned XP',
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
              'Persistencia entra numa sprint futura.',
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
                onPressed: onBack,
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

// ── Widgets privados de UI (visual igual ao legado) ─────────────────────

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
        background = AppColors.correct.withValues(alpha: 0.15);
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
