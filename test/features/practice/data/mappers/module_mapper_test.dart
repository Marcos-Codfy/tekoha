// test/features/practice/data/mappers/module_mapper_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/practice/data/dtos/airtable_module_dto.dart';
import 'package:tekoha/features/practice/data/mappers/module_mapper.dart';
import 'package:tekoha/features/practice/domain/entities/module.dart';

void main() {
  group('ModuleMapper', () {
    test('toEntity preserva todos os campos', () {
      const dto = AirtableModuleDto(
        id: 'r1',
        name: 'Saudacoes',
        description: 'desc',
        language: 'nheengatu',
        order: 1,
      );
      final entity = ModuleMapper.toEntity(dto);
      expect(
        entity,
        const Module(
          id: 'r1',
          name: 'Saudacoes',
          description: 'desc',
          language: 'nheengatu',
          order: 1,
        ),
      );
    });

    test('toEntityList mantem ordem', () {
      const dtos = [
        AirtableModuleDto(
          id: 'r1',
          name: 'A',
          description: '',
          language: 'nheengatu',
          order: 1,
        ),
        AirtableModuleDto(
          id: 'r2',
          name: 'B',
          description: '',
          language: 'nheengatu',
          order: 2,
        ),
      ];
      final entities = ModuleMapper.toEntityList(dtos);
      expect(entities.map((e) => e.id), ['r1', 'r2']);
    });

    test('toEntityList vazia devolve lista vazia', () {
      expect(ModuleMapper.toEntityList(const []), isEmpty);
    });
  });
}
