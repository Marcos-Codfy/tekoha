// lib/features/lesson/domain/entities/trail_stage.dart
// Camada: Domain (Lesson).
//
// Entidade pura de UMA etapa da trilha de aprendizado de um modulo.
// A trilha divide as palavras da licao em blocos curtos (2-3 palavras)
// pra evitar saturacao — chunking (Miller, 1956) + carga cognitiva
// controlada (Sweller, 1988). Ver ESP-005 no Material Base.

import 'word.dart';

class TrailStage {
  /// Posicao da etapa na trilha (0-based).
  final int index;

  /// Titulo curto exibido no card da etapa (ex.: "A palavra curinga").
  final String title;

  /// Palavras desta etapa, ja ordenadas por `Word.order`.
  final List<Word> words;

  const TrailStage({
    required this.index,
    required this.title,
    required this.words,
  });

  /// Quantos exercicios esta etapa gera no LessonRunner:
  /// palavra com audio = 4 (3 de audio + 1 quiz); sem audio = 1 (quiz).
  int get exerciseCount =>
      words.fold(0, (total, w) => total + (w.hasAudio ? 4 : 1));

  @override
  String toString() =>
      'TrailStage(index: $index, title: $title, words: ${words.length})';
}
