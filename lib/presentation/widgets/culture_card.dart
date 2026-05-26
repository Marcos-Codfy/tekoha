// lib/presentation/widgets/culture_card.dart
// Card visual de um conteudo da aba Cultura.
// Recebe um CultureContentModel e renderiza titulo + corpo em layout
// otimizado pra LEITURA (fundo claro, alto contraste, espacamento generoso).
// Responsavel: Marcos / Jeovanna (design)

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/culture_content_model.dart';

class CultureCard extends StatelessWidget {
  final CultureContentModel content;

  const CultureCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // preto 8% — sombra muito sutil
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content.body,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.6, // espacamento entre linhas pra leitura confortavel
            ),
          ),
        ],
      ),
    );
  }
}
