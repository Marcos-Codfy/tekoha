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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/badges/tekoha_xp_badge.dart';
import '../../../../core/components/buttons/tekoha_primary_button.dart';
import '../../../../core/components/loaders/tekoha_loader.dart';
import '../../../../core/components/texts/tekoha_encouragement_text.dart';
import '../../../../core/components/texts/tekoha_purpose_text.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/audio_exercise.dart';
import '../../domain/usecases/get_lessons_by_module.dart';
import '../../domain/usecases/get_words_by_lesson.dart';
import '../controllers/lesson_runner.dart';
import '../controllers/lesson_step.dart';

class LessonScreen extends StatelessWidget {
  final String moduleId;
  final String moduleName;

  /// Etapa da trilha a executar (ESP-005). Null = licao inteira.
  final int? stageIndex;

  /// Titulo da etapa (exibido na AppBar no lugar do nome do modulo).
  final String? stageTitle;

  /// `Module.order` — escolhe a divisao curada do TrailBuilder.
  final int moduleOrder;

  const LessonScreen({
    super.key,
    required this.moduleId,
    required this.moduleName,
    this.stageIndex,
    this.stageTitle,
    this.moduleOrder = 0,
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
      )..load(moduleId, stageIndex: stageIndex, moduleOrder: moduleOrder),
      child: _LessonScreenBody(title: stageTitle ?? moduleName),
    );
  }
}

class _LessonScreenBody extends StatelessWidget {
  final String title;
  const _LessonScreenBody({required this.title});

  @override
  Widget build(BuildContext context) {
    final runner = context.watch<LessonRunner>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (runner.isExercising)
            TekohaXpBadge(
              xp: runner.xpEarned,
              mastered: runner.masteredWordsCount,
            ),
        ],
      ),
      body: () {
        if (runner.isLoading) {
          return const TekohaLoader();
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
            // Devolve o resultado da sessao pra ModuleTrailScreen
            // persistir (XP, streak, dominadas, falas, conquistas).
            onBack: () => Navigator.of(context).pop(runner.outcome),
          );
        }
        return _ExerciseScaffold(runner: runner);
      }(),
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
  /// Label do progresso da licao com efeito Goal-Gradient (Kivetz et al.,
  /// 2006). Apresentacoes de palavra nova nao contam como exercicio —
  /// o numerador/denominador consideram so os passos pontuaveis.
  String _progressLabel(LessonRunner r) {
    if (r.current is IntroStep) return 'Palavra nova!';

    final exercisesTotal =
        r.steps.where((s) => s is! IntroStep).length;
    final exercisesDone = r.steps
        .take(r.currentIndex + 1)
        .where((s) => s is! IntroStep)
        .length;
    final remaining = exercisesTotal - exercisesDone;
    if (remaining == 0) return 'Último exercício!';
    if (remaining <= 2) return 'Faltam $remaining — você está quase lá!';
    return 'Exercício $exercisesDone de $exercisesTotal';
  }

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

    // Endowed Progress Effect (Nunes & Drèze, 2006): a barra comeca em
    // ~5% no primeiro exercicio em vez de 0. Sinal visual de "voce ja
    // comecou". So muda a REPRESENTACAO — o dominio (XP, contagem) nao
    // e afetado.
    final endowedProgress = 0.05 + (runner.progress * 0.95);

    return SafeArea(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: LinearProgressIndicator(
              value: endowedProgress,
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
                  _progressLabel(runner),
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
                IntroStep s => _IntroStepView(
                    step: s,
                    runner: runner,
                  ),
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

// ── Step de apresentacao (palavra nova — ESP-008) ───────────────────────

/// Ficha da palavra ANTES dos exercicios dela: grafia, audio, pronuncia,
/// traducao e curiosidade. Teach-then-test (Krashen, 1982): sem ver a
/// traducao antes, o 1o exercicio seria adivinhacao, nao aprendizado.
class _IntroStepView extends StatelessWidget {
  final IntroStep step;
  final LessonRunner runner;

  const _IntroStepView({required this.step, required this.runner});

  @override
  Widget build(BuildContext context) {
    final word = step.word;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pill "palavra nova" — sinaliza que AQUI nao ha cobranca.
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.jenipapo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.jenipapo.withValues(alpha: 0.25),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 14, color: AppColors.jenipapo),
                  SizedBox(width: 6),
                  Text(
                    'Palavra nova',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.jenipapo,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          word.nheengatu,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          word.translation,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        _PlayButton(onTap: runner.playCurrentAudio),
        const SizedBox(height: 8),
        const Text(
          'Toque pra ouvir de novo',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        if (word.pronunciation.isNotEmpty)
          Center(child: _PronunciationHint(text: word.pronunciation)),
        if (word.culturalNote.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _CuriosityCard(text: word.culturalNote),
        ],
        const SizedBox(height: 24),
        TekohaPrimaryButton(
          label: 'Vamos praticar',
          icon: Icons.arrow_forward,
          onPressed: runner.next,
        ),
      ],
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
          TekohaEncouragementText(runner.feedbackMessage),
        ],
      ],
    );
  }

  String _instructionFor(AudioExerciseType type) {
    switch (type) {
      case AudioExerciseType.listenChooseTranslation:
        return 'Ouça e escolha a tradução';
      case AudioExerciseType.listenChooseWord:
        return 'Ouça e escolha a palavra que você ouviu';
      case AudioExerciseType.listenAndRepeat:
        return 'Ouça e repita em voz alta';
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
    // Estado "checando": parou de ouvir, tem fala capturada e o motor
    // ainda nao devolveu o veredito — sem este feedback o usuario acha
    // que o app travou (Nielsen H1: visibilidade do status).
    final checking =
        !runner.listening && runner.spokenText.isNotEmpty && !runner.answered;

    return Column(
      children: [
        _Pulse(
          active: runner.listening,
          child: GestureDetector(
            onTap: runner.toggleMic,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    runner.listening ? AppColors.wrong : AppColors.primary,
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
        ),
        const SizedBox(height: 16),
        if (checking)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Checando sua pronúncia...',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        else
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
            child: const Text('Não consegui / Pular'),
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
          TekohaEncouragementText(runner.feedbackMessage),
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
                    ? 'Boa! +${runner.lastXpGained} XP'
                    : (runner.feedbackMessage.isNotEmpty
                        ? runner.feedbackMessage
                        : 'Vamos seguir.'),
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
              'Pronúncia: ${word.pronunciation}',
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
          TekohaPrimaryButton(
            label: runner.isLastStep ? 'Ver resultado' : 'Continuar',
            onPressed: runner.next,
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
    // Caulim (branco-osso terroso) diferencia visualmente o card de
    // conteudo cultural do fluxo normal de exercicio. Reforca o frame
    // "saber tradicional" sem competir com a paleta urucum.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.caulim,
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
    // Peak-End Rule (Kahneman et al., 1993): essa tela e o "end" que o
    // usuario lembra da sessao. Investimos em mensagem positiva e propo-
    // sito, removemos qualquer aviso tecnico (CLT — Sweller, 1988).
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
              'Você praticou Nheengatu hoje.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.2,
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
              'de até $totalPossible XP',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            // SDT-Relacionamento (Deci & Ryan, 2000): cada palavra
            // praticada vira contribuicao concreta a revitalizacao da
            // lingua. Substitui o aviso tecnico anterior.
            const TekohaPurposeText(
              text:
                  'Cada palavra que continua sendo falada\né uma palavra que não se perde.',
            ),
            const SizedBox(height: 24),
            TekohaPrimaryButton(
              label: 'Voltar pra trilha',
              icon: Icons.arrow_back,
              onPressed: onBack,
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

class _PlayButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _playing = false;
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    // Escuta o estado REAL do player (inclui autoplay ao entrar no
    // passo) — o pulso so anima enquanto o som esta saindo de fato.
    _subscription = sl<AudioPlayerService>().playingStream.listen((playing) {
      if (mounted) setState(() => _playing = playing);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cor "rio" (azul Amazonas) — reforca semioticamente que audio e
    // "fluxo" / som, diferenciando do urucum (acao/CTA da marca).
    return Center(
      child: _Pulse(
        active: _playing,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.rio,
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
      ),
    );
  }
}

/// Pulso continuo bem simples (escala 1.0 <-> 1.08) enquanto [active].
/// Reutilizado pelo botao de audio (som tocando) e pelo microfone
/// (escutando) — feedback de processo em andamento (Nielsen H1).
class _Pulse extends StatefulWidget {
  final bool active;
  final Widget child;

  const _Pulse({required this.active, required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _Pulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.animateTo(0, duration: const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

