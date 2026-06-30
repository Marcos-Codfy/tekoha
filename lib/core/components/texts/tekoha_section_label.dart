// lib/core/components/texts/tekoha_section_label.dart
//
// Label de secao — usado pra cabecalhos de grupos de informacao
// (ex.: "Seu progresso" no Home/Profile).
//
// Tipografia hierarquica: menor, peso medio, cor secundaria. Sinaliza
// "rotulo de bloco" sem competir com o conteudo proprio.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaSectionLabel extends StatelessWidget {
  final String text;

  const TekohaSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
