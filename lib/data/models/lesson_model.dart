// lib/data/models/lesson_model.dart
// Representa uma LiÃ§Ã£o dentro de um mÃ³dulo
// ResponsÃ¡vel: Marcos
// Os dados vÃªm do Airtable (tabela Lessons)

class LessonModel {
  final String id;
  final String title;
  final String moduleId;
  final int order;
  final int xpReward;

  LessonModel({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.order,
    required this.xpReward,
  });

  /// Cria um LessonModel a partir dos dados do Airtable
  factory LessonModel.fromAirtable(String id, Map<String, dynamic> fields) {
    return LessonModel(
      id: id,
      title: fields['title'] ?? '',
      moduleId: fields['module_id'] ?? '',
      order: (fields['order'] ?? 0).toInt(),
      xpReward: (fields['xp_reward'] ?? 10).toInt(),
    );
  }
}
