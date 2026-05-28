// lib/core/utils/audio_exercise_builder.dart
// Funcao pura (sem Flutter) que monta a sequencia de exercicios de audio
// a partir das saudacoes. Testavel isolado.
//
// ORDEM INTERCALADA POR SAUDACAO (decisao de produto do Marcos):
//   Pra cada saudacao em [words], gera os 3 tipos em sequencia:
//     1. listenChooseTranslation (mais facil)
//     2. listenChooseWord
//     3. listenAndRepeat (mais dificil)
//
// Exemplo com [ara, karuka, pituna]:
//   [ara/trad, ara/word, ara/repeat,
//    karuka/trad, karuka/word, karuka/repeat,
//    pituna/trad, pituna/word, pituna/repeat]
//
// A LessonScreen entao intercala 1 quiz tradicional ao final de cada
// bloco de 3 (ver lesson_screen.dart).
//
// Responsavel: Marcos (gerado por Claude)

import 'dart:math';

import '../../data/models/audio_exercise.dart';
import '../../data/models/word_model.dart';

class AudioExerciseBuilder {
  AudioExerciseBuilder._();

  /// [words] deve conter APENAS palavras com audio (as saudacoes).
  /// [random] opcional pra embaralhar opcoes de forma deterministica em teste.
  ///
  /// O pool de opcoes (distratores + correta) vem das proprias [words], pra
  /// nao confundir o usuario com palavras que ele nao acabou de exercitar.
  static List<AudioExercise> build(
    List<WordModel> words, {
    Random? random,
  }) {
    final rng = random ?? Random();

    // Defensivo: so usa palavras que realmente tem audio.
    final audioWords = words.where((w) => w.hasAudio).toList();
    if (audioWords.isEmpty) return const [];

    final exercises = <AudioExercise>[];

    for (final target in audioWords) {
      // Tipo 1: ouve Nheengatu -> escolhe a traducao PT.
      final translationOptions = _shuffledOptions(
        correct: target.translation,
        pool: audioWords.map((w) => w.translation).toList(),
        rng: rng,
      );
      exercises.add(AudioExercise(
        target: target,
        type: AudioExerciseType.listenChooseTranslation,
        options: translationOptions,
        correctIndex: translationOptions.indexOf(target.translation),
      ));

      // Tipo 2: ouve Nheengatu -> escolhe a palavra Nheengatu.
      final wordOptions = _shuffledOptions(
        correct: target.nheengatu,
        pool: audioWords.map((w) => w.nheengatu).toList(),
        rng: rng,
      );
      exercises.add(AudioExercise(
        target: target,
        type: AudioExerciseType.listenChooseWord,
        options: wordOptions,
        correctIndex: wordOptions.indexOf(target.nheengatu),
      ));

      // Tipo 3: ouve e repete falando.
      exercises.add(AudioExercise(
        target: target,
        type: AudioExerciseType.listenAndRepeat,
      ));
    }

    return exercises;
  }

  /// Monta lista de opcoes (correta + distratores) embaralhada.
  /// Distratores sao tudo do pool que nao seja a correta, sem duplicar.
  /// Com 3 saudacoes, sai sempre uma lista de 3 opcoes.
  static List<String> _shuffledOptions({
    required String correct,
    required List<String> pool,
    required Random rng,
  }) {
    final distractors = pool.toSet().where((o) => o != correct).toList()
      ..shuffle(rng);
    final options = <String>[correct, ...distractors];
    options.shuffle(rng);
    return options;
  }
}
