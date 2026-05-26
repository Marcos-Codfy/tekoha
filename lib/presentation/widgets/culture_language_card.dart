// lib/presentation/widgets/culture_language_card.dart
// Card grande usado na CulturesListScreen pra escolher um povo/lingua.
//
// Tem dois estados:
//   - ATIVO    -> [onTap] != null. Fundo branco, sombra sutil, chevron
//                 Urucum, ripple no toque.
//   - INATIVO  -> [onTap] == null. Fundo cinza claro, sem sombra, sem
//                 chevron, sem ripple. Usado pros placeholders "Em breve".

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Fundo neutro pros placeholders desativados. Mais claro que `border`
/// pra não competir visualmente com a borda do card.
const Color _disabledBackground = Color(0xFFF5F5F5);

class CultureLanguageCard extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Quando `null`, o card vai pro estado INATIVO (cinza, sem ripple).
  /// Quando setado, dispara ao toque.
  final VoidCallback? onTap;

  const CultureLanguageCard({
    super.key,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  bool get _enabled => onTap != null;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        _enabled ? AppColors.textPrimary : AppColors.textSecondary;
    final subtitleColor = AppColors.textSecondary;

    return DecoratedBox(
      // Sombra externa so aparece no card ativo. No inativo, fica flat
      // pra reforcar a sensacao de "indisponivel".
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _enabled
            ? const [
                BoxShadow(
                  color: Color(0x14000000), // preto 8% — sombra muito sutil
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        // Material desenha o fundo e recebe o ripple do InkWell por cima.
        color: _enabled ? AppColors.surface : _disabledBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap, // null = sem ripple e sem callback
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Chevron so aparece no card ativo — sinaliza "navegavel".
                if (_enabled)
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
