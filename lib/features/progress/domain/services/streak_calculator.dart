// lib/features/progress/domain/services/streak_calculator.dart
// Camada: Domain (Progress). Funcao pura — sem Flutter, sem Firebase.
//
// Calcula a sequencia de dias consecutivos de pratica (streak).
// Regras (ESP-006):
//   - Primeira pratica da vida       -> streak = 1
//   - Praticou de novo no MESMO dia  -> streak nao muda (nao infla)
//   - Praticou no dia SEGUINTE       -> streak + 1
//   - Pulou 1+ dias                  -> streak volta pra 1 (recomeca,
//     sem punicao alem do reinicio — tom encorajador, Pekrun 2006)
//
// Comparacao e por DIA DE CALENDARIO (ano/mes/dia), nao por janela de
// 24h — praticar 23h50 e depois 00h10 conta como dois dias seguidos.

class StreakCalculator {
  StreakCalculator._();

  /// Novo valor do streak apos uma pratica concluida em [now].
  static int nextStreak({
    required int currentStreak,
    required DateTime? lastPracticeAt,
    required DateTime now,
  }) {
    if (lastPracticeAt == null) return 1;

    final last = DateTime(
      lastPracticeAt.year,
      lastPracticeAt.month,
      lastPracticeAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final gapInDays = today.difference(last).inDays;

    // Mesmo dia (ou relogio andou pra tras): mantem, garantindo minimo 1.
    if (gapInDays <= 0) return currentStreak < 1 ? 1 : currentStreak;
    // Dia seguinte: sequencia continua.
    if (gapInDays == 1) return currentStreak + 1;
    // Quebrou a sequencia: recomeca do 1 (a pratica de hoje ja conta).
    return 1;
  }
}
