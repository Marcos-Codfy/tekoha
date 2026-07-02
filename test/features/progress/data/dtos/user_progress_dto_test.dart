// test/features/progress/data/dtos/user_progress_dto_test.dart
//
// Estrategia: parse tolerante (null, mapa vazio, campos parciais,
// tipos inesperados) + round-trip toMap/fromMap.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/progress/data/dtos/user_progress_dto.dart';

void main() {
  group('UserProgressDto.fromMap', () {
    test('mapa null (documento inexistente) vira DTO zerado', () {
      final dto = UserProgressDto.fromMap(null);

      expect(dto.xp, 0);
      expect(dto.streakDays, 0);
      expect(dto.lastPracticeAtIso, isNull);
      expect(dto.stagesDone, isEmpty);
    });

    test('mapa vazio vira DTO zerado (campos ausentes tolerados)', () {
      final dto = UserProgressDto.fromMap(const {});

      expect(dto.xp, 0);
      expect(dto.streakDays, 0);
    });

    test('mapa completo e parseado com stages_done por modulo', () {
      final dto = UserProgressDto.fromMap(const {
        'xp': 320,
        'streak_days': 5,
        'last_practice_at': '2026-07-02T10:30:00.000',
        'stages_done': {
          'm1': [0, 1, 2],
          'm2': [0],
        },
      });

      expect(dto.xp, 320);
      expect(dto.streakDays, 5);
      expect(dto.lastPracticeAtIso, '2026-07-02T10:30:00.000');
      expect(dto.stagesDone['m1'], [0, 1, 2]);
      expect(dto.stagesDone['m2'], [0]);
    });

    test('numeros vindos como double (JSON) sao convertidos pra int', () {
      final dto = UserProgressDto.fromMap(const {
        'xp': 320.0,
        'streak_days': 5.0,
        'stages_done': {
          'm1': [0.0, 1.0],
        },
      });

      expect(dto.xp, 320);
      expect(dto.streakDays, 5);
      expect(dto.stagesDone['m1'], [0, 1]);
    });

    test('valores de tipos inesperados em stages_done sao ignorados', () {
      final dto = UserProgressDto.fromMap(const {
        'stages_done': {
          'm1': 'nao-e-lista',
          'm2': [0, 'x', 1],
        },
      });

      expect(dto.stagesDone.containsKey('m1'), isFalse);
      expect(dto.stagesDone['m2'], [0, 1]);
    });
  });

  group('round-trip', () {
    test('toMap seguido de fromMap preserva todos os campos', () {
      const original = UserProgressDto(
        xp: 150,
        streakDays: 3,
        lastPracticeAtIso: '2026-07-02T09:00:00.000',
        stagesDone: {
          'm1': [0, 1],
        },
      );

      final restored = UserProgressDto.fromMap(original.toMap());

      expect(restored.xp, original.xp);
      expect(restored.streakDays, original.streakDays);
      expect(restored.lastPracticeAtIso, original.lastPracticeAtIso);
      expect(restored.stagesDone, original.stagesDone);
    });

    test('lastPracticeAt null nao entra no mapa (merge nao apaga)', () {
      const dto = UserProgressDto(
        xp: 0,
        streakDays: 0,
        lastPracticeAtIso: null,
        stagesDone: {},
      );

      expect(dto.toMap().containsKey('last_practice_at'), isFalse);
    });
  });
}
