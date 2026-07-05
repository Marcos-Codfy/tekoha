// lib/core/components/badges/tekoha_xp_badge.dart
//
// Badge exibido no AppBar durante a execucao de uma licao. Mostra:
//   - "+XX XP" (total acumulado na sessao)
//   - "Y aprendidas" (palavras acertadas na 1a tentativa — SDT-Competencia;
//     termo "aprendida" em vez de "dominada": linguagem do mundo real,
//     Nielsen H2 — decisao do autor na 2a rodada de teste, ESP-008)
//
// Fundamentacao cientifica:
//   - Deci & Ryan (2000) Self-Determination Theory — necessidade de
//     Competencia: feedback de dominio crescente.
//
// Movido do `lesson_screen.dart` privado pra reuso futuro (qualquer
// tela educacional que precise comunicar progresso).

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaXpBadge extends StatelessWidget {
  final int xp;
  final int mastered;

  const TekohaXpBadge({
    super.key,
    required this.xp,
    this.mastered = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+$xp XP',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
              // SDT-Competencia: visivel so quando o usuario realmente
              // aprendeu alguma palavra (acertou na 1a tentativa).
              if (mastered > 0)
                Text(
                  '$mastered ${mastered == 1 ? "aprendida" : "aprendidas"}',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
