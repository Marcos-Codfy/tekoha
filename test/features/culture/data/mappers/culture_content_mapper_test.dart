// test/features/culture/data/mappers/culture_content_mapper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/culture/data/dtos/airtable_culture_content_dto.dart';
import 'package:tekoha/features/culture/data/mappers/culture_content_mapper.dart';
import 'package:tekoha/features/culture/domain/entities/culture_content.dart';

void main() {
  group('CultureContentMapper', () {
    test('toEntity preserva todos os campos', () {
      const dto = AirtableCultureContentDto(
        id: 'r',
        language: 'nheengatu',
        category: 'history',
        title: 'T',
        body: 'B',
        order: 1,
        isActive: true,
      );
      expect(
        CultureContentMapper.toEntity(dto),
        const CultureContent(
          id: 'r',
          language: 'nheengatu',
          category: 'history',
          title: 'T',
          body: 'B',
          order: 1,
          isActive: true,
        ),
      );
    });
  });
}
