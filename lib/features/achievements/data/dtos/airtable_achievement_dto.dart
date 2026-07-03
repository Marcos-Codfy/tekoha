// lib/features/achievements/data/dtos/airtable_achievement_dto.dart
// Camada: Data (Achievements). Espelha o record da tabela Achievements.

class AirtableAchievementDto {
  final String id;
  final String code;
  final String title;
  final String description;
  final String lockedHint;
  final String criterionType;
  final int criterionValue;
  final String iconUrl;
  final int order;
  final bool isActive;

  const AirtableAchievementDto({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.lockedHint,
    required this.criterionType,
    required this.criterionValue,
    required this.iconUrl,
    required this.order,
    required this.isActive,
  });

  factory AirtableAchievementDto.fromAirtable(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    final fieldsRaw = record['fields'];
    final fields = fieldsRaw is Map
        ? Map<String, dynamic>.from(fieldsRaw)
        : <String, dynamic>{};

    return AirtableAchievementDto(
      id: id,
      code: (fields['code'] ?? '').toString(),
      title: (fields['title'] ?? '').toString(),
      description: (fields['description'] ?? '').toString(),
      lockedHint: (fields['locked_hint'] ?? '').toString(),
      criterionType: (fields['criterion_type'] ?? '').toString(),
      criterionValue: (fields['criterion_value'] is num)
          ? (fields['criterion_value'] as num).toInt()
          : 0,
      iconUrl: (fields['icon_url'] ?? '').toString(),
      order: (fields['order'] is num) ? (fields['order'] as num).toInt() : 0,
      isActive: (fields['is_active'] as bool?) ?? false,
    );
  }
}
