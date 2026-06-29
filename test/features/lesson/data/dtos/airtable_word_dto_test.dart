// test/features/lesson/data/dtos/airtable_word_dto_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/data/dtos/airtable_word_dto.dart';

void main() {
  group('AirtableWordDto.fromAirtable', () {
    test('campos completos sao convertidos', () {
      final dto = AirtableWordDto.fromAirtable({
        'id': 'recW1',
        'fields': {
          'nheengatu': 'Puranga ara',
          'translation': 'Bom dia',
          'pronunciation': 'pu-RAN-ga A-ra',
          'cultural_note': 'curiosidade...',
          'lesson': ['recL1'],
          'order': 1,
          'audio_url': 'https://x/a.mp3',
        },
      });
      expect(dto.id, 'recW1');
      expect(dto.nheengatu, 'Puranga ara');
      expect(dto.translation, 'Bom dia');
      expect(dto.pronunciation, 'pu-RAN-ga A-ra');
      expect(dto.culturalNote, 'curiosidade...');
      expect(dto.lessonId, 'recL1');
      expect(dto.order, 1);
      expect(dto.audioUrl, 'https://x/a.mp3');
    });

    test('audio_url ausente vira string vazia', () {
      final dto =
          AirtableWordDto.fromAirtable({'id': 'r', 'fields': {}});
      expect(dto.audioUrl, '');
    });

    test('lesson ausente vira lessonId vazio', () {
      final dto = AirtableWordDto.fromAirtable({
        'id': 'r',
        'fields': {'nheengatu': 'a'},
      });
      expect(dto.lessonId, '');
    });

    test('lesson com array vazio vira lessonId vazio', () {
      final dto = AirtableWordDto.fromAirtable({
        'id': 'r',
        'fields': {'lesson': []},
      });
      expect(dto.lessonId, '');
    });
  });
}
