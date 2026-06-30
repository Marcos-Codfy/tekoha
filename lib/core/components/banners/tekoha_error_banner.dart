// lib/core/components/banners/tekoha_error_banner.dart
//
// Banner inline de erro. Usado em forms (auth) ou em qualquer tela que
// precise comunicar erro sem ocupar espaco com ErrorView.
//
// Substitui o antigo AuthErrorBanner — generalizado pra uso em qualquer
// feature.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaErrorBanner extends StatelessWidget {
  final String message;

  /// Quando true, adiciona uma margem superior pequena (padrao em forms).
  final bool withTopMargin;

  const TekohaErrorBanner({
    super.key,
    required this.message,
    this.withTopMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: withTopMargin ? const EdgeInsets.only(top: 4) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.wrong.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.wrong.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.wrong, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.wrong,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
