// lib/features/achievements/data/mappers/achievement_mapper.dart
// Camada: Data (Achievements). Converte DTO (Airtable) -> Entity.

import '../../domain/entities/achievement.dart';
import '../dtos/airtable_achievement_dto.dart';

class AchievementMapper {
  AchievementMapper._();

  static Achievement toEntity(AirtableAchievementDto dto) => Achievement(
        id: dto.id,
        code: dto.code,
        title: dto.title,
        description: dto.description,
        lockedHint: dto.lockedHint,
        criterionType: AchievementCriterionType.fromCode(dto.criterionType),
        criterionValue: dto.criterionValue,
        iconUrl: dto.iconUrl,
        order: dto.order,
        isActive: dto.isActive,
      );
}
