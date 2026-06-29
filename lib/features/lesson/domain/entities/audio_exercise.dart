// lib/features/lesson/domain/entities/audio_exercise.dart
// Camada: Domain (Lesson).
//
// Tres tipos progressivos de exercicio de audio (mais facil -> mais
// dificil):
//   1. listenChooseTranslation -> ouve Nheengatu, escolhe a traducao PT
//   2. listenChooseWord        -> ouve Nheengatu, escolhe a palavra Nheengatu
//   3. listenAndRepeat         -> ouve e repete falando (microfone)

import 'word.dart';

enum AudioExerciseType {
  listenChooseTranslation,
  listenChooseWord,
  listenAndRepeat,
}

class AudioExercise {
  /// Palavra-alvo do exercicio (saudacao que toca no audio).
  final Word target;
  final AudioExerciseType type;

  /// Opcoes mostradas ao usuario (vazio em [listenAndRepeat]).
  final List<String> options;

  /// Indice da opcao correta em [options]. -1 quando nao se aplica.
  final int correctIndex;

  const AudioExercise({
    required this.target,
    required this.type,
    this.options = const [],
    this.correctIndex = -1,
  });

  /// Texto da resposta correta (conveniencia pra UI/validacao).
  String get correctAnswer =>
      (correctIndex >= 0 && correctIndex < options.length)
          ? options[correctIndex]
          : '';
}
