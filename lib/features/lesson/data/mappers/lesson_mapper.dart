// lib/features/lesson/data/mappers/lesson_mapper.dart

import '../../domain/entities/lesson.dart';
import '../dtos/airtable_lesson_dto.dart';

class LessonMapper {
  LessonMapper._();

  static Lesson toEntity(AirtableLessonDto dto) {
    return Lesson(
      id: dto.id,
      title: dto.title,
      moduleId: dto.moduleId,
      order: dto.order,
      xpReward: dto.xpReward,
    );
  }

  static List<Lesson> toEntityList(List<AirtableLessonDto> dtos) =>
      dtos.map(toEntity).toList(growable: false);
}
