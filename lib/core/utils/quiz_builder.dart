// lib/core/utils/quiz_builder.dart
// Gera perguntas de Quiz (PT -> Nheengatu) a partir de uma lista de palavras.
// Pura funcao — nao depende de Flutter, facil de testar isoladamente.

import 'dart:math';
import '../../data/models/word_model.dart';

/// Estrutura imutavel de uma pergunta de Quiz.
/// - [word]: a palavra correta (pra pegar pronuncia e curiosidade depois).
/// - [options]: 4 opcoes (1 correta + 3 distratores) ja embaralhadas.
/// - [correctIndex]: indice da opcao correta dentro de [options].
class QuizQuestion {
  final WordModel word;
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

  /// Gera uma lista de [QuizQuestion] a partir de:
  /// - [targets]: palavras que viram perguntas (uma pergunta por palavra).
  /// - [pool]: pool de onde tirar distratores (geralmente todas as palavras da licao).
  /// - [random]: fonte de aleatoriedade. Default = `Random()`. Em testes,
  ///   passe um Random com seed pra resultado determinístico.
  ///
  /// Para cada palavra alvo:
  ///   pergunta      = `translation` (portugues)
  ///   correta       = `nheengatu`
  ///   distratores   = 3 outras `nheengatu` aleatorias do pool (sem repetir a correta)
  ///   posicao final = embaralhada (a correta nao fica sempre no mesmo lugar)
  ///
  /// Requer [pool].length >= 4 pra ter distratores suficientes.
  static List<QuizQuestion> build({
    required List<WordModel> targets,
    required List<WordModel> pool,
    Random? random,
  }) {
    final rng = random ?? Random();
    return targets.map((w) => _buildSingle(w, pool, rng)).toList();
  }

  static QuizQuestion _buildSingle(WordModel correct, List<WordModel> pool, Random rng) {
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
