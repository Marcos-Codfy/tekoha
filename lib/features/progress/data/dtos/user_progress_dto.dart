// lib/features/progress/data/dtos/user_progress_dto.dart
// Camada: Data (Progress).
//
// DTO que espelha o documento `user_progress/{uid}` do Firestore.
// Campos do documento (snake_case, padrao do projeto):
//   xp               -> int
//   streak_days      -> int
//   last_practice_at -> String ISO-8601 (ou ausente)
//   stages_done      -> { moduleId: [0, 1, 2] }
//
// Data ISO-8601 como String (e nao Timestamp nativo) de proposito:
// mantem o DTO puro/testavel sem importar o plugin do Firestore e
// facilita inspecao manual no console.

class UserProgressDto {
  final int xp;
  final int streakDays;
  final String? lastPracticeAtIso;
  final Map<String, List<int>> stagesDone;
  final List<String> modulesDone;
  final List<String> masteredWordIds;
  final int speechCorrectTotal;

  /// code da conquista -> ISO-8601 do desbloqueio.
  final Map<String, String> achievementsUnlocked;

  const UserProgressDto({
    required this.xp,
    required this.streakDays,
    required this.lastPracticeAtIso,
    required this.stagesDone,
    this.modulesDone = const [],
    this.masteredWordIds = const [],
    this.speechCorrectTotal = 0,
    this.achievementsUnlocked = const {},
  });

  /// Parse TOLERANTE: documento ausente/parcial (usuario novo, campo
  /// adicionado depois) vira default zerado em vez de crash.
  factory UserProgressDto.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const UserProgressDto(
        xp: 0,
        streakDays: 0,
        lastPracticeAtIso: null,
        stagesDone: {},
      );
    }

    final rawStages = map['stages_done'];
    final stages = <String, List<int>>{};
    if (rawStages is Map) {
      for (final entry in rawStages.entries) {
        final value = entry.value;
        if (value is List) {
          stages['${entry.key}'] =
              value.whereType<num>().map((n) => n.toInt()).toList();
        }
      }
    }

    final rawUnlocked = map['achievements_unlocked'];
    final unlocked = <String, String>{};
    if (rawUnlocked is Map) {
      for (final entry in rawUnlocked.entries) {
        if (entry.value is String) {
          unlocked['${entry.key}'] = entry.value as String;
        }
      }
    }

    return UserProgressDto(
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      streakDays: (map['streak_days'] as num?)?.toInt() ?? 0,
      lastPracticeAtIso: map['last_practice_at'] as String?,
      stagesDone: stages,
      modulesDone: _stringList(map['modules_done']),
      masteredWordIds: _stringList(map['mastered_word_ids']),
      speechCorrectTotal: (map['speech_correct_total'] as num?)?.toInt() ?? 0,
      achievementsUnlocked: unlocked,
    );
  }

  static List<String> _stringList(dynamic raw) =>
      raw is List ? raw.whereType<String>().toList() : const [];

  Map<String, dynamic> toMap() => {
        'xp': xp,
        'streak_days': streakDays,
        if (lastPracticeAtIso != null) 'last_practice_at': lastPracticeAtIso,
        'stages_done': stagesDone,
        'modules_done': modulesDone,
        'mastered_word_ids': masteredWordIds,
        'speech_correct_total': speechCorrectTotal,
        'achievements_unlocked': achievementsUnlocked,
      };
}
