// lib/features/lesson/presentation/controllers/lesson_step.dart
// Camada: Presentation (Lesson).
//
// Sealed class que representa UM passo da licao na sequencia exibida.
// Pode ser um exercicio de audio (3 variantes) ou um quiz tradicional.
//
// Centralizar aqui (ao inves de privado dentro da screen) permite
// LessonRunner E LessonScreen compartilharem o mesmo tipo.

import '../../domain/builders/quiz_builder.dart';
import '../../domain/entities/audio_exercise.dart';
import '../../domain/entities/word.dart';

sealed class LessonStep {
  /// Palavra alvo do passo — usada pra mostrar pronuncia e curiosidade.
  Word get target;

  const LessonStep();
}

/// Apresentacao de PALAVRA NOVA antes dos exercicios dela (ESP-008):
/// mostra grafia, pronuncia, traducao e curiosidade ANTES de cobrar.
/// Teach-then-test: sem input compreensivel primeiro (Krashen, 1982),
/// o primeiro exercicio vira adivinhacao — nao avaliacao.
/// Nao pontua XP e nao conta como exercicio.
class IntroStep extends LessonStep {
  final Word word;
  const IntroStep(this.word);

  @override
  Word get target => word;
}

class AudioStep extends LessonStep {
  final AudioExercise data;
  const AudioStep(this.data);

  @override
  Word get target => data.target;
}

class QuizStep extends LessonStep {
  final QuizQuestion data;
  const QuizStep(this.data);

  @override
  Word get target => data.word;
}
