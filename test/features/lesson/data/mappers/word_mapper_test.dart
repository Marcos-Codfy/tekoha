// test/features/lesson/data/mappers/word_mapper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/lesson/data/dtos/airtable_word_dto.dart';
import 'package:tekoha/features/lesson/data/mappers/word_mapper.dart';

void main() {
  group('WordMapper', () {
    test('toEntity preserva todos os campos', () {
      const dto = AirtableWordDto(
        id: 'r1',
        nheengatu: 'ara',
        translation: 'manha',
        pronunciation: 'A-ra',
        culturalNote: 'nota',
        lessonId: 'L1',
        order: 1,
        audioUrl: 'http://a/a.mp3',
      );
      final word = WordMapper.toEntity(dto);

      expect(word.id, 'r1');
      expect(word.nheengatu, 'ara');
      expect(word.translation, 'manha');
      expect(word.pronunciation, 'A-ra');
      expect(word.culturalNote, 'nota');
      expect(word.lessonId, 'L1');
      expect(word.order, 1);
      expect(word.audioUrl, 'http://a/a.mp3');
      expect(word.hasAudio, true);
    });

    test('hasAudio = false quando audioUrl vazio ou so espaco', () {
      const empty = AirtableWordDto(
        id: 'r',
        nheengatu: '',
        translation: '',
        pronunciation: '',
        culturalNote: '',
        lessonId: '',
        order: 0,
        audioUrl: '',
      );
      const spaces = AirtableWordDto(
        id: 'r',
        nheengatu: '',
        translation: '',
        pronunciation: '',
        culturalNote: '',
        lessonId: '',
        order: 0,
        audioUrl: '   ',
      );

      expect(WordMapper.toEntity(empty).hasAudio, false);
      expect(WordMapper.toEntity(spaces).hasAudio, false);
    });
  });
}
