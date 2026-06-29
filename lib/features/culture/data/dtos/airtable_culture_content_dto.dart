// lib/features/culture/data/dtos/airtable_culture_content_dto.dart

class AirtableCultureContentDto {
  final String id;
  final String language;
  final String category;
  final String title;
  final String body;
  final int order;
  final bool isActive;

  const AirtableCultureContentDto({
    required this.id,
    required this.language,
    required this.category,
    required this.title,
    required this.body,
    required this.order,
    required this.isActive,
  });

  factory AirtableCultureContentDto.fromAirtable(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    final fieldsRaw = record['fields'];
    final fields = fieldsRaw is Map
        ? Map<String, dynamic>.from(fieldsRaw)
        : <String, dynamic>{};

    return AirtableCultureContentDto(
      id: id,
      language: (fields['language'] ?? '').toString(),
      category: (fields['category'] ?? '').toString(),
      title: (fields['title'] ?? '').toString(),
      body: (fields['body'] ?? '').toString(),
      order: (fields['order'] is num) ? (fields['order'] as num).toInt() : 0,
      isActive: (fields['is_active'] as bool?) ?? false,
    );
  }
}
