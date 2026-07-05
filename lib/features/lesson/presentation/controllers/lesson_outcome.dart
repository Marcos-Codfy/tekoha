// lib/features/lesson/presentation/controllers/lesson_outcome.dart
// Camada: Presentation (Lesson).
//
// Resultado imutavel de UMA sessao de licao (etapa da trilha), devolvido
// pela LessonScreen no Navigator.pop. A ModuleTrailScreen usa pra
// persistir o progresso do usuario (ESP-006): XP, palavras dominadas e
// falas corretas alimentam streak, totais e criterios de conquistas.

class LessonOutcome {
  /// XP ganho na sessao (soma dos sorteios 8/10/12 por acerto).
  final int xpEarned;

  /// IDs das palavras dominadas na sessao (acertou de primeira).
  final Set<String> masteredWordIds;

  /// Exercicios de ouvir-e-repetir concluidos com acerto na sessao.
  final int speechCorrectCount;

  const LessonOutcome({
    required this.xpEarned,
    required this.masteredWordIds,
    required this.speechCorrectCount,
  });

  @override
  String toString() =>
      'LessonOutcome(xp: $xpEarned, dominadas: ${masteredWordIds.length}, '
      'falas: $speechCorrectCount)';
}
