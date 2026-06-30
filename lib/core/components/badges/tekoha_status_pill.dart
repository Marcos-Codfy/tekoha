// lib/core/components/badges/tekoha_status_pill.dart
//
// Pill informativa com icone + texto, fundo urucum-suave. Usada pra
// estados meta do app (ex.: "Modo de demonstração", futuro "Modo offline").
//
// Substitui o Container inline que se repetia em Home e Profile.

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class TekohaStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const TekohaStatusPill({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
