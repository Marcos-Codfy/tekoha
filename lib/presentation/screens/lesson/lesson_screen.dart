// lib/presentation/screens/lesson/lesson_screen.dart
// Tela de execucao de uma licao no formato Quiz (PT -> Nheengatu).
// Versao MVP: 4 exercicios, 1 unico tipo (Quiz), XP local (sem persistencia).
//
// Logica de geracao de perguntas mora em [QuizBuilder] (core/utils).
// Estado de erro usa o [ErrorView] reutilizavel.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/quiz_builder.dart';
import '../../providers/content_provider.dart';
import '../../widgets/error_view.dart';

/// Numero de exercicios desta licao de teste.
const int _kQuizCount = 4;

/// XP ganho por acerto.
const int _kXpPerCorrect = 10;

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

/// Estados possiveis da tela.
enum _ScreenState { loading, error, quiz, done }

class _LessonScreenState extends State<LessonScreen> {
  _ScreenState _state = _ScreenState.loading;
  String? _errorMessage;
  List<QuizQuestion> _questions = [];

  int _currentIndex = 0;
  int _xpEarned = 0;
  int? _selectedOption;   // null = nenhuma opcao tocada ainda
  bool _isLastWrong = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final content = context.read<ContentProvider>();

    try {
      // 1. Carrega as licoes deste modulo e pega a primeira.
      final lessons = await content.loadLessonsForModule(widget.moduleId);
      if (lessons.isEmpty) {
        _showError('Nenhuma lição encontrada para este módulo.');
        return;
      }
      final lesson = lessons.first;

      // 2. Carrega TODAS as palavras dessa licao (sao 10 no MVP).
      final allWords = await content.loadWordsForLesson(lesson.id);
      if (allWords.length < 4) {
        _showError(
          'Esta lição precisa de pelo menos 4 palavras pra gerar o quiz '
          '(achei ${allWords.length}).',
        );
        return;
      }

      // 3. Gera 4 perguntas. Usa as 4 primeiras palavras como alvo e TODAS
      //    como pool de distratores -> mais variedade.
      _questions = QuizBuilder.build(
        targets: allWords.take(_kQuizCount).toList(),
        pool: allWords,
      );

      if (!mounted) return;
      setState(() => _state = _ScreenState.quiz);
    } catch (e) {
      _showError('Erro ao carregar a lição. Verifique sua conexão.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() {
      _state = _ScreenState.error;
      _errorMessage = msg;
    });
  }

  void _onOptionTap(int index) {
    final q = _questions[_currentIndex];

    if (index == q.correctIndex) {
      setState(() {
        _selectedOption = index;
        _xpEarned += _kXpPerCorrect;
        _isLastWrong = false;
      });
    } else {
      setState(() {
        _selectedOption = index;
        _isLastWrong = true;
      });
      // Apos 800ms libera pra tentar de novo.
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _selectedOption = null;
          _isLastWrong = false;
        });
      });
    }
  }

  void _onNext() {
    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
        _selectedOption = null;
        _isLastWrong = false;
      } else {
        _state = _ScreenState.done;
      }
    });
  }

  bool get _isAnsweredCorrectly =>
      _selectedOption != null &&
      _selectedOption == _questions[_currentIndex].correctIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.moduleName),
        actions: [
          if (_state == _ScreenState.quiz)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary,
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
        _ScreenState.quiz => _buildQuiz(),
        _ScreenState.done => _buildResult(),
      },
    );
  }

  Widget _buildQuiz() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          color: AppColors.primary,
          backgroundColor: AppColors.border,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pergunta ${_currentIndex + 1} de ${_questions.length}',
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
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
                  _OptionButton(
                    text: q.options[i],
                    state: _stateForOption(i, q.correctIndex),
                    onTap: _isAnsweredCorrectly ? null : () => _onOptionTap(i),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_isLastWrong) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Errou! Tente outra opção.',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (_isAnsweredCorrectly) ...[
                  const SizedBox(height: 8),
                  _CorrectFeedbackCard(question: q),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      _currentIndex < _questions.length - 1
                          ? 'Próximo'
                          : 'Ver resultado',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  _OptionState _stateForOption(int index, int correctIndex) {
    if (_selectedOption == null) return _OptionState.idle;
    if (index == _selectedOption && index == correctIndex) return _OptionState.correct;
    if (index == _selectedOption && index != correctIndex) return _OptionState.wrong;
    if (_isAnsweredCorrectly && index == correctIndex) return _OptionState.correct;
    return _OptionState.idle;
  }

  Widget _buildResult() {
    final totalPossible = _questions.length * _kXpPerCorrect;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 96, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Lição concluída!',
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
              'de $totalPossible XP possíveis',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            const Text(
              'XP ainda não é salvo no servidor.\n'
              'Persistência no Firestore entra na Sprint 5.',
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
                label: const Text('Voltar para a Prática'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card de feedback positivo (pronuncia + curiosidade cultural) ──────
class _CorrectFeedbackCard extends StatelessWidget {
  final QuizQuestion question;
  const _CorrectFeedbackCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final word = question.word;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.correct.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.correct.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.correct, size: 22),
              SizedBox(width: 8),
              Text(
                'Correto! +10 XP',
                style: TextStyle(
                  color: AppColors.correct,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (word.pronunciation.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Pronúncia: ${word.pronunciation}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (word.culturalNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      word.culturalNote,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Botao de opcao do quiz ───────────────────────────────────────────
enum _OptionState { idle, correct, wrong }

class _OptionButton extends StatelessWidget {
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  const _OptionButton({
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
      case _OptionState.idle:
        background = AppColors.background;
        foreground = AppColors.textPrimary;
        border = AppColors.primary;
        icon = null;
        break;
      case _OptionState.correct:
        background = AppColors.correct.withOpacity(0.15);
        foreground = AppColors.correct;
        border = AppColors.correct;
        icon = Icons.check_circle;
        break;
      case _OptionState.wrong:
        background = Colors.red.shade50;
        foreground = Colors.red.shade700;
        border = Colors.red.shade700;
        icon = Icons.cancel;
        break;
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
