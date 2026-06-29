// test/features/lesson/data/dtos/airtable_lesson_dto_test.dart
//
// Foco: campo `module` e Linked Record do Airtable, vem como ARRAY DE
// IDS. Testar varios formatos: ausente, vazio, com 1+ id.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/data/dtos/airtable_lesson_dto.dart';

void main() {
  group('AirtableLessonDto.fromAirtable', () {
    test('campos completos sao convertidos', () {
      final dto = AirtableLessonDto.fromAirtable({
        'id': 'recL1',
        'fields': {
          'title': 'Cumprimentos',
          'module': ['recM1'],
          'order': 1,
          'xp_reward': 100,
        },
      });
      expect(dto.id, 'recL1');
      expect(dto.title, 'Cumprimentos');
      expect(dto.moduleId, 'recM1');
      expect(dto.order, 1);
      expect(dto.xpReward, 100);
    });

    test('module ausente vira moduleId vazio', () {
      final dto =
          AirtableLessonDto.fromAirtable({'id': 'recL1', 'fields': {}});
      expect(dto.moduleId, '');
    });

    test('module com array vazio vira moduleId vazio', () {
      final dto = AirtableLessonDto.fromAirtable({
        'id': 'recL1',
        'fields': {'module': []},
      });
      expect(dto.moduleId, '');
    });

    test('module com multiplos ids pega o primeiro', () {
      final dto = AirtableLessonDto.fromAirtable({
        'id': 'recL1',
        'fields': {
          'module': ['recA', 'recB'],
        },
      });
      expect(dto.moduleId, 'recA');
    });

    test('xp_reward ausente vira 0', () {
      final dto =
          AirtableLessonDto.fromAirtable({'id': 'recL', 'fields': {}});
      expect(dto.xpReward, 0);
    });

    test('xp_reward como double vira int', () {
      final dto = AirtableLessonDto.fromAirtable({
        'id': 'recL',
        'fields': {'xp_reward': 75.0},
      });
      expect(dto.xpReward, 75);
    });
  });
}
