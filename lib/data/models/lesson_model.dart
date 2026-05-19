// lib/data/models/lesson_model.dart
// Representa uma licao dentro de um modulo.
// Dados vem da tabela Lessons do Airtable.

class LessonModel {
  final String id;
  final String title;
  final String moduleId;
  final int order;
  final int xpReward;

  const LessonModel({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.order,
    required this.xpReward,
  });

  factory LessonModel.fromAirtable(String id, Map<String, dynamic> fields) {
    return LessonModel(
      id: id,
      title: (fields['title'] ?? '').toString(),
      // Campo `module` no Airtable e Linked Record -> array de IDs.
      // Pegamos o primeiro item com null-aware chaining; se vier null ou
      // lista vazia, fallback pra string vazia.
      moduleId: (fields['module'] as List<dynamic>?)?.first?.toString() ?? '',
      order:    (fields['order'] ?? 0).toInt(),
      xpReward: (fields['xp_reward'] ?? 0).toInt(),
    );
  }
}
