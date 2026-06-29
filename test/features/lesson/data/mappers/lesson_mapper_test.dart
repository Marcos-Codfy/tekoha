// test/features/lesson/data/mappers/lesson_mapper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/data/dtos/airtable_lesson_dto.dart';
import 'package:tekoha/features/lesson/data/mappers/lesson_mapper.dart';
import 'package:tekoha/features/lesson/domain/entities/lesson.dart';

void main() {
  group('LessonMapper', () {
    test('toEntity preserva todos os campos', () {
      const dto = AirtableLessonDto(
        id: 'r1',
        title: 'Cumprimentos',
        moduleId: 'm1',
        order: 1,
        xpReward: 100,
      );
      final entity = LessonMapper.toEntity(dto);
      expect(
        entity,
        const Lesson(
          id: 'r1',
          title: 'Cumprimentos',
          moduleId: 'm1',
          order: 1,
          xpReward: 100,
        ),
      );
    });

    test('toEntityList vazia', () {
      expect(LessonMapper.toEntityList(const []), isEmpty);
    });
  });
}
