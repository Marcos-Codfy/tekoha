// test/features/progress/domain/services/streak_calculator_test.dart
//
// Estrategia: particionamento dos cenarios de calendario (primeira vez,
// mesmo dia, dia seguinte, quebra) + boundaries de virada de mes/ano e
// janela de 24h vs dia de calendario.

import 'package:flutter_test/flutter_test.dart';
import 'package:tekoha/features/progress/domain/services/streak_calculator.dart';

void main() {
  group('StreakCalculator.nextStreak', () {
    test('primeira pratica da vida comeca streak em 1', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 0,
          lastPracticeAt: null,
          now: DateTime(2026, 7, 2, 10),
        ),
        1,
      );
    });

    test('praticar de novo no mesmo dia NAO infla o streak', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 3,
          lastPracticeAt: DateTime(2026, 7, 2, 8),
          now: DateTime(2026, 7, 2, 22),
        ),
        3,
      );
    });

    test('mesmo dia com streak zerado corrige pra 1 (boundary)', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 0,
          lastPracticeAt: DateTime(2026, 7, 2, 8),
          now: DateTime(2026, 7, 2, 9),
        ),
        1,
      );
    });

    test('dia seguinte incrementa o streak', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 3,
          lastPracticeAt: DateTime(2026, 7, 2, 23, 50),
          now: DateTime(2026, 7, 3, 0, 10),
        ),
        4,
      );
    });

    test('dia de calendario vale mais que janela de 24h: 23h50 -> 00h10 '
        'do dia seguinte conta como sequencia', () {
      // Menos de 1h de intervalo real, mas mudou o dia -> incrementa.
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 1,
          lastPracticeAt: DateTime(2026, 7, 2, 23, 50),
          now: DateTime(2026, 7, 3, 0, 10),
        ),
        2,
      );
    });

    test('pular um dia quebra a sequencia e recomeca em 1', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 9,
          lastPracticeAt: DateTime(2026, 7, 1),
          now: DateTime(2026, 7, 3),
        ),
        1,
      );
    });

    test('virada de mes conta como dia seguinte (boundary)', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 5,
          lastPracticeAt: DateTime(2026, 6, 30, 21),
          now: DateTime(2026, 7, 1, 7),
        ),
        6,
      );
    });

    test('virada de ano conta como dia seguinte (boundary)', () {
      expect(
        StreakCalculator.nextStreak(
          currentStreak: 5,
          lastPracticeAt: DateTime(2025, 12, 31),
          now: DateTime(2026, 1, 1),
        ),
        6,
      );
    });
  });
}
