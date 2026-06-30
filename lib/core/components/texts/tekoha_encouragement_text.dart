// lib/core/components/texts/tekoha_encouragement_text.dart
//
// Texto encorajador exibido na LessonScreen apos erro (antes do usuario
// responder de novo). Cor urucum, peso medio, centralizado.
//
// Fundamentacao:
//   - Pekrun (2006) Control-Value Theory — preserva o "controle percebido"
//     ("eu consigo") apos um erro. Pequenas frases positivas reduzem
//     ansiedade e mantem o usuario no canal de flow.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaEncouragementText extends StatelessWidget {
  final String text;

  const TekohaEncouragementText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
