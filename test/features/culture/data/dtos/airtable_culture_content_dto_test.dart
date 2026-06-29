// test/features/culture/data/dtos/airtable_culture_content_dto_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/culture/data/dtos/airtable_culture_content_dto.dart';

void main() {
  group('AirtableCultureContentDto.fromAirtable', () {
    test('campos completos sao convertidos', () {
      final dto = AirtableCultureContentDto.fromAirtable({
        'id': 'recC1',
        'fields': {
          'language': 'nheengatu',
          'category': 'history',
          'title': 'Origem do Nheengatu',
          'body': 'Texto...',
          'order': 1,
          'is_active': true,
        },
      });
      expect(dto.id, 'recC1');
      expect(dto.language, 'nheengatu');
      expect(dto.category, 'history');
      expect(dto.title, 'Origem do Nheengatu');
      expect(dto.body, 'Texto...');
      expect(dto.order, 1);
      expect(dto.isActive, true);
    });

    test('is_active ausente vira false (default seguro)', () {
      final dto = AirtableCultureContentDto.fromAirtable({
        'id': 'r',
        'fields': {},
      });
      expect(dto.isActive, false);
    });

    test('is_active false explicito e respeitado', () {
      final dto = AirtableCultureContentDto.fromAirtable({
        'id': 'r',
        'fields': {'is_active': false},
      });
      expect(dto.isActive, false);
    });

    test('campos textuais ausentes viram string vazia', () {
      final dto = AirtableCultureContentDto.fromAirtable({
        'id': 'r',
        'fields': {},
      });
      expect(dto.language, '');
      expect(dto.category, '');
      expect(dto.title, '');
      expect(dto.body, '');
    });
  });
}
