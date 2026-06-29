// test/features/practice/data/dtos/airtable_module_dto_test.dart
//
// Estrategia: cada campo tem partitions — presente, ausente, tipo errado.
// O DTO deve ter fallback defensivo (string vazia / 0) para nao quebrar
// a UI se um campo ainda nao foi preenchido no Airtable.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/practice/data/dtos/airtable_module_dto.dart';

void main() {
  group('AirtableModuleDto.fromAirtable', () {
    test('campos completos sao convertidos certinhos', () {
      final dto = AirtableModuleDto.fromAirtable({
        'id': 'recABC',
        'fields': {
          'name': 'Saudacoes',
          'description': 'Modulo introdutorio',
          'language': 'nheengatu',
          'order': 1,
        },
      });
      expect(dto.id, 'recABC');
      expect(dto.name, 'Saudacoes');
      expect(dto.description, 'Modulo introdutorio');
      expect(dto.language, 'nheengatu');
      expect(dto.order, 1);
    });

    test('id ausente vira string vazia', () {
      final dto = AirtableModuleDto.fromAirtable({'fields': {'name': 'X'}});
      expect(dto.id, '');
    });

    test('fields ausente nao quebra — todos os campos viram default', () {
      final dto = AirtableModuleDto.fromAirtable({'id': 'r1'});
      expect(dto.name, '');
      expect(dto.description, '');
      expect(dto.language, '');
      expect(dto.order, 0);
    });

    test('order como double e convertido pra int (Airtable pode mandar 2.0)',
        () {
      final dto = AirtableModuleDto.fromAirtable({
        'id': 'r2',
        'fields': {'order': 2.0},
      });
      expect(dto.order, 2);
    });

    test('order como string nao quebra — default 0 (entrada invalida)', () {
      final dto = AirtableModuleDto.fromAirtable({
        'id': 'r3',
        'fields': {'order': 'tres'},
      });
      expect(dto.order, 0);
    });

    test('campos null mantem default da string vazia/0', () {
      final dto = AirtableModuleDto.fromAirtable({
        'id': 'r4',
        'fields': {
          'name': null,
          'description': null,
          'language': null,
          'order': null,
        },
      });
      expect(dto.name, '');
      expect(dto.description, '');
      expect(dto.language, '');
      expect(dto.order, 0);
    });
  });
}
