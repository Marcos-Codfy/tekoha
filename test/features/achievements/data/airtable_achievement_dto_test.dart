// test/features/achievements/data/airtable_achievement_dto_test.dart
//
// Estrategia: parse do record real do Airtable (campos completos),
// tolerancia a campos ausentes e mapeamento DTO -> Entity (incluindo
// criterion_type desconhecido -> unknown, protecao de forward-compat).

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/achievements/data/dtos/airtable_achievement_dto.dart';
import 'package:tekoha/features/achievements/data/mappers/achievement_mapper.dart';
import 'package:tekoha/features/achievements/domain/entities/achievement.dart';

void main() {
  group('AirtableAchievementDto.fromAirtable', () {
    test('parseia record completo da tabela Achievements', () {
      final dto = AirtableAchievementDto.fromAirtable({
        'id': 'recABC123',
        'fields': {
          'title': 'Guardião da Chama',
          'code': 'streak_7',
          'description': 'Sete dias mantendo a chama acesa.',
          'locked_hint': 'Pratique 7 dias seguidos.',
          'criterion_type': 'streak_days',
          'criterion_value': 7,
          'icon_url': 'https://cdn/x/streak_7.png',
          'order': 6,
          'is_active': true,
        },
      });

      expect(dto.id, 'recABC123');
      expect(dto.code, 'streak_7');
      expect(dto.title, 'Guardião da Chama');
      expect(dto.criterionType, 'streak_days');
      expect(dto.criterionValue, 7);
      expect(dto.order, 6);
      expect(dto.isActive, isTrue);
    });

    test('campos ausentes viram defaults seguros (checkbox falso omitido '
        'pelo Airtable)', () {
      final dto = AirtableAchievementDto.fromAirtable(const {
        'id': 'rec1',
        'fields': {'title': 'X'},
      });

      expect(dto.code, '');
      expect(dto.criterionValue, 0);
      expect(dto.isActive, isFalse);
    });
  });

  group('AchievementMapper.toEntity', () {
    Achievement entityWith(String criterionType) =>
        AchievementMapper.toEntity(AirtableAchievementDto.fromAirtable({
          'id': 'rec1',
          'fields': {
            'title': 'T',
            'code': 'c',
            'criterion_type': criterionType,
            'criterion_value': 5,
            'is_active': true,
          },
        }));

    test('converte todos os criterion_type conhecidos', () {
      expect(entityWith('stages_done').criterionType,
          AchievementCriterionType.stagesDone);
      expect(entityWith('modules_done').criterionType,
          AchievementCriterionType.modulesDone);
      expect(entityWith('xp_total').criterionType,
          AchievementCriterionType.xpTotal);
      expect(entityWith('streak_days').criterionType,
          AchievementCriterionType.streakDays);
      expect(entityWith('words_mastered').criterionType,
          AchievementCriterionType.wordsMastered);
      expect(entityWith('speech_correct').criterionType,
          AchievementCriterionType.speechCorrect);
    });

    test('criterion_type novo/desconhecido vira unknown (nao quebra o app)',
        () {
      expect(entityWith('lunar_phase').criterionType,
          AchievementCriterionType.unknown);
    });
  });
}
