// lib/features/culture/presentation/widgets/culture_language_card.dart
// Card grande de selecao de lingua/povo na CulturesListScreen.
// Dois estados:
//   - ATIVO  -> onTap != null. Fundo branco, sombra sutil, chevron, ripple.
//   - INATIVO -> onTap == null. Cinza claro, sem sombra/chevron/ripple.

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Fundo neutro pros placeholders desativados.
const Color _disabledBackground = Color(0xFFF5F5F5);

class CultureLanguageCard extends StatelessWidget {
  final String title;
  final String? subtitle;
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
    const subtitleColor = AppColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _enabled
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: _enabled ? AppColors.surface : _disabledBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
