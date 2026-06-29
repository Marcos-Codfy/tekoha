// lib/features/lesson/data/dtos/airtable_lesson_dto.dart
// Camada: Data (Lesson).
//
// DTO de uma licao no Airtable. Campo `module` e Linked Record =>
// array de IDs.

class AirtableLessonDto {
  final String id;
  final String title;
  final String moduleId;
  final int order;
  final int xpReward;

  const AirtableLessonDto({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.order,
    required this.xpReward,
  });

  factory AirtableLessonDto.fromAirtable(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    final fieldsRaw = record['fields'];
    final fields = fieldsRaw is Map
        ? Map<String, dynamic>.from(fieldsRaw)
        : <String, dynamic>{};

    // Linked Record: array de IDs. Pegamos o primeiro com null-aware.
    final moduleLink = fields['module'];
    final moduleId = (moduleLink is List && moduleLink.isNotEmpty)
        ? moduleLink.first.toString()
        : '';

    return AirtableLessonDto(
      id: id,
      title: (fields['title'] ?? '').toString(),
      moduleId: moduleId,
      order: (fields['order'] is num) ? (fields['order'] as num).toInt() : 0,
      xpReward: (fields['xp_reward'] is num)
          ? (fields['xp_reward'] as num).toInt()
          : 0,
    );
  }
}
