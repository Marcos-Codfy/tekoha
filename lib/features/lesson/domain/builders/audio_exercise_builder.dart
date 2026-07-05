// lib/features/lesson/domain/builders/audio_exercise_builder.dart
// Camada: Domain (Lesson). Funcao pura — sem Flutter.
//
// Monta a sequencia de exercicios de audio a partir das saudacoes.
//
// ORDEM INTERCALADA POR SAUDACAO (decisao de produto):
//   Pra cada saudacao em [words], gera 3 tipos em sequencia:
//     1. listenChooseTranslation (mais facil)
//     2. listenChooseWord
//     3. listenAndRepeat (mais dificil)
//
// Exemplo com [ara, karuka, pituna]:
//   [ara/trad, ara/word, ara/repeat,
//    karuka/trad, karuka/word, karuka/repeat,
//    pituna/trad, pituna/word, pituna/repeat]

import 'dart:math';

import '../entities/audio_exercise.dart';
import '../entities/word.dart';

class AudioExerciseBuilder {
  AudioExerciseBuilder._();

  /// Maximo de alternativas por exercicio de escolha (1 correta + 3
  /// distratores). Mesmo limite do QuizBuilder — consistencia entre
  /// exercicios (Nielsen H4) e carga cognitiva controlada (Hick-Hyman;
  /// Sweller, 1988). Sem esse teto, o numero de botoes cresceria junto
  /// com o numero de palavras com audio da licao.
  static const int kMaxOptions = 4;

  /// [words] deve conter APENAS palavras com audio (as saudacoes).
  /// Filtra defensivamente caso venha algo sem audio.
  /// [pool] opcional: fonte dos distratores (ex.: TODAS as palavras da
  /// licao quando [words] e so o recorte de uma etapa da trilha —
  /// ESP-005). Default: as proprias [words].
  /// [random] opcional pra embaralhar opcoes deterministicamente em teste.
  ///
  /// As opcoes (correta + distratores) respeitam o teto de [kMaxOptions].
  static List<AudioExercise> build(
    List<Word> words, {
    List<Word>? pool,
    Random? random,
  }) {
    final rng = random ?? Random();

    final audioWords = words.where((w) => w.hasAudio).toList();
    if (audioWords.isEmpty) return const [];

    final optionPool =
        (pool == null || pool.isEmpty) ? audioWords : pool;

    final exercises = <AudioExercise>[];

    for (final target in audioWords) {
      // Tipo 1: ouve Nheengatu -> escolhe traducao PT.
      final translationOptions = _shuffledOptions(
        correct: target.translation,
        pool: optionPool.map((w) => w.translation).toList(),
        rng: rng,
      );
      exercises.add(AudioExercise(
        target: target,
        type: AudioExerciseType.listenChooseTranslation,
        options: translationOptions,
        correctIndex: translationOptions.indexOf(target.translation),
      ));

      // Tipo 2: ouve Nheengatu -> escolhe palavra Nheengatu.
      final wordOptions = _shuffledOptions(
        correct: target.nheengatu,
        pool: optionPool.map((w) => w.nheengatu).toList(),
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

  /// Lista de opcoes embaralhada (correta + ate 3 distratores unicos
  /// sorteados do pool). Nunca passa de [kMaxOptions] alternativas.
  static List<String> _shuffledOptions({
    required String correct,
    required List<String> pool,
    required Random rng,
  }) {
    final distractors = pool.toSet().where((o) => o != correct).toList()
      ..shuffle(rng);
    final options = <String>[correct, ...distractors.take(kMaxOptions - 1)];
    options.shuffle(rng);
    return options;
  }
}
