// lib/features/progress/data/mappers/user_progress_mapper.dart
// Camada: Data (Progress).
//
// Converte DTO (forma do Firestore) <-> Entity (conceito puro).

import '../../domain/entities/user_progress.dart';
import '../dtos/user_progress_dto.dart';

class UserProgressMapper {
  UserProgressMapper._();

  static UserProgress toEntity(UserProgressDto dto) => UserProgress(
        xp: dto.xp,
        streakDays: dto.streakDays,
        lastPracticeAt: dto.lastPracticeAtIso == null
            ? null
            : DateTime.tryParse(dto.lastPracticeAtIso!),
        stagesDoneByModule: {
          for (final entry in dto.stagesDone.entries)
            entry.key: entry.value.toSet(),
        },
        modulesDone: dto.modulesDone.toSet(),
        masteredWordIds: dto.masteredWordIds.toSet(),
        speechCorrectTotal: dto.speechCorrectTotal,
        unlockedAchievements: {
          for (final entry in dto.achievementsUnlocked.entries)
            if (DateTime.tryParse(entry.value) != null)
              entry.key: DateTime.parse(entry.value),
        },
      );

  static UserProgressDto toDto(UserProgress entity) => UserProgressDto(
        xp: entity.xp,
        streakDays: entity.streakDays,
        lastPracticeAtIso: entity.lastPracticeAt?.toIso8601String(),
        stagesDone: {
          for (final entry in entity.stagesDoneByModule.entries)
            entry.key: entry.value.toList()..sort(),
        },
        modulesDone: entity.modulesDone.toList()..sort(),
        masteredWordIds: entity.masteredWordIds.toList()..sort(),
        speechCorrectTotal: entity.speechCorrectTotal,
        achievementsUnlocked: {
          for (final entry in entity.unlockedAchievements.entries)
            entry.key: entry.value.toIso8601String(),
        },
      );
}
