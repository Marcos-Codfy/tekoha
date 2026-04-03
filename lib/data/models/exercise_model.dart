// lib/data/models/exercise_model.dart
// Representa um ExercÃ­cio (flashcard, quiz ou traduÃ§Ã£o)
// ResponsÃ¡vel: Marcos
// Os dados vÃªm do Airtable (tabela Exercises)

// Define os tipos de exercÃ­cio disponÃ­veis no app
enum ExerciseType { flashcard, quiz, translate }

class ExerciseModel {
  final String id;
  final String lessonId;
  final ExerciseType type;
  final String question;
  final String answer;
  final List<String> options; // Usado apenas no quiz (alternativas)
  final String language;

  ExerciseModel({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.question,
    required this.answer,
    required this.options,
    required this.language,
  });

  /// Factory Method: cria o tipo certo de exercÃ­cio automaticamente
  /// baseado no campo 'type' que vem do Airtable
  factory ExerciseModel.fromAirtable(String id, Map<String, dynamic> fields) {
    // Converte a string do Airtable para o enum ExerciseType
    ExerciseType exerciseType;
    switch (fields['type']) {
      case 'quiz':      exerciseType = ExerciseType.quiz; break;
      case 'translate': exerciseType = ExerciseType.translate; break;
      default:          exerciseType = ExerciseType.flashcard;
    }

    // As opÃ§Ãµes do quiz vÃªm como "opcao1,opcao2,opcao3" â€” separamos pela vÃ­rgula
    List<String> optionsList = [];
    if (fields['options'] != null && fields['options'].toString().isNotEmpty) {
      optionsList = fields['options'].toString().split(',').map((o) => o.trim()).toList();
    }

    return ExerciseModel(
      id: id,
      lessonId: fields['lesson_id'] ?? '',
      type: exerciseType,
      question: fields['question'] ?? '',
      answer: fields['answer'] ?? '',
      options: optionsList,
      language: fields['language'] ?? 'nheengatu',
    );
  }
}
