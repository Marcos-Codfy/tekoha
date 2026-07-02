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
      );

  static UserProgressDto toDto(UserProgress entity) => UserProgressDto(
        xp: entity.xp,
        streakDays: entity.streakDays,
        lastPracticeAtIso: entity.lastPracticeAt?.toIso8601String(),
        stagesDone: {
          for (final entry in entity.stagesDoneByModule.entries)
            entry.key: entry.value.toList()..sort(),
        },
      );
}
