// lib/data/models/audio_exercise.dart
// Modelo de um exercicio de audio das saudacoes.
// Tres tipos progressivos (do mais facil ao mais dificil):
//   1. listenChooseTranslation -> ouve Nheengatu, escolhe a traducao PT
//   2. listenChooseWord        -> ouve Nheengatu, escolhe a palavra Nheengatu
//   3. listenAndRepeat         -> ouve e repete falando (microfone)
// Responsavel: Marcos (gerado por Claude)

import 'word_model.dart';

enum AudioExerciseType {
  listenChooseTranslation,
  listenChooseWord,
  listenAndRepeat,
}

class AudioExercise {
  /// A palavra-alvo deste exercicio (a saudacao que toca no audio).
  final WordModel target;

  /// Tipo do exercicio.
  final AudioExerciseType type;

  /// Opcoes mostradas ao usuario (so pros tipos de escolha).
  /// - listenChooseTranslation: lista de traducoes PT (uma correta)
  /// - listenChooseWord: lista de palavras Nheengatu (uma correta)
  /// - listenAndRepeat: vazia (nao tem opcoes)
  final List<String> options;

  /// Indice da opcao correta dentro de [options].
  /// -1 quando o tipo nao usa opcoes (listenAndRepeat).
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
