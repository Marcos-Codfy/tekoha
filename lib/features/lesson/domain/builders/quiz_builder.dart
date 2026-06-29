// lib/features/lesson/domain/builders/quiz_builder.dart
// Camada: Domain (Lesson). Funcao pura — sem Flutter.
//
// Gera perguntas de Quiz (PT -> Nheengatu) a partir de uma lista de
// palavras. Mantem o algoritmo original do MVP — comportamento
// preservado a risca.

import 'dart:math';

import '../entities/word.dart';

/// Pergunta de Quiz imutavel.
/// - [word]: palavra correta (pra UI pegar pronuncia/curiosidade depois)
/// - [options]: 4 opcoes embaralhadas (1 correta + 3 distratores)
/// - [correctIndex]: posicao da opcao correta em [options]
class QuizQuestion {
  final Word word;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.word,
    required this.options,
    required this.correctIndex,
  });
}

class QuizBuilder {
  QuizBuilder._();

  /// Gera lista de [QuizQuestion]. Requer `pool.length >= 4` pra ter
  /// distratores suficientes (a lesson_screen valida isso antes).
  ///
  /// - [targets]: palavras que viram perguntas (1 pergunta por palavra)
  /// - [pool]: pool de distratores (geralmente todas as palavras da licao)
  /// - [random]: opcional, pra teste determinístico (Random com seed)
  static List<QuizQuestion> build({
    required List<Word> targets,
    required List<Word> pool,
    Random? random,
  }) {
    final rng = random ?? Random();
    return targets.map((w) => _buildSingle(w, pool, rng)).toList();
  }

  static QuizQuestion _buildSingle(Word correct, List<Word> pool, Random rng) {
    final others = pool.where((w) => w.id != correct.id).toList()..shuffle(rng);
    final distractors = others.take(3).map((w) => w.nheengatu).toList();
    final options = <String>[...distractors, correct.nheengatu]..shuffle(rng);
    return QuizQuestion(
      word: correct,
      options: options,
      correctIndex: options.indexOf(correct.nheengatu),
    );
  }
}
