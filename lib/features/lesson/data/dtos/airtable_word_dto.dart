// lib/features/lesson/data/dtos/airtable_word_dto.dart
// Camada: Data (Lesson).

class AirtableWordDto {
  final String id;
  final String nheengatu;
  final String translation;
  final String pronunciation;
  final String culturalNote;
  final String lessonId;
  final int order;
  final String audioUrl;

  const AirtableWordDto({
    required this.id,
    required this.nheengatu,
    required this.translation,
    required this.pronunciation,
    required this.culturalNote,
    required this.lessonId,
    required this.order,
    required this.audioUrl,
  });

  factory AirtableWordDto.fromAirtable(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    final fieldsRaw = record['fields'];
    final fields = fieldsRaw is Map
        ? Map<String, dynamic>.from(fieldsRaw)
        : <String, dynamic>{};

    final lessonLink = fields['lesson'];
    final lessonId = (lessonLink is List && lessonLink.isNotEmpty)
        ? lessonLink.first.toString()
        : '';

    return AirtableWordDto(
      id: id,
      nheengatu: (fields['nheengatu'] ?? '').toString(),
      translation: (fields['translation'] ?? '').toString(),
      pronunciation: (fields['pronunciation'] ?? '').toString(),
      culturalNote: (fields['cultural_note'] ?? '').toString(),
      lessonId: lessonId,
      order: (fields['order'] is num) ? (fields['order'] as num).toInt() : 0,
      audioUrl: (fields['audio_url'] ?? '').toString(),
    );
  }
}
