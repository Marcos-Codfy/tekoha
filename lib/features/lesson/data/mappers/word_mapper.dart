// lib/features/lesson/data/mappers/word_mapper.dart

import '../../domain/entities/word.dart';
import '../dtos/airtable_word_dto.dart';

class WordMapper {
  WordMapper._();

  static Word toEntity(AirtableWordDto dto) {
    return Word(
      id: dto.id,
      nheengatu: dto.nheengatu,
      translation: dto.translation,
      pronunciation: dto.pronunciation,
      culturalNote: dto.culturalNote,
      lessonId: dto.lessonId,
      order: dto.order,
      audioUrl: dto.audioUrl,
    );
  }

  static List<Word> toEntityList(List<AirtableWordDto> dtos) =>
      dtos.map(toEntity).toList(growable: false);
}
