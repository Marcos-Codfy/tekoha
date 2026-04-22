// lib/core/constants/app_colors.dart
// Paleta Tekoha — Urucum · Branco · Preto
// Responsável: Marcos / Jeovanna

import 'package:flutter/material.dart';

class AppColors {
  // ── Paleta principal ───────────────────────────────────────────────
  static const Color primary    = Color(0xFFB5451B); // Urucum
  static const Color background = Color(0xFFFFFFFF); // Branco puro
  static const Color surface    = Color(0xFFFFFFFF); // Branco puro

  // ── Texto ──────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A); // Preto suave
  static const Color textSecondary = Color(0xFF6B6B6B); // Cinza médio
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Branco s/ urucum

  // ── Campos ────────────────────────────────────────────────────────
  static const Color border        = Color(0xFFE0E0E0); // Borda idle
  static const Color borderFocused = Color(0xFFB5451B); // Borda focada

  // ── Feedback ──────────────────────────────────────────────────────
  static const Color correct = Color(0xFF2E7D32); // Verde (acerto)
  static const Color wrong   = Color(0xFFB5451B); // Urucum (erro)

  // ── Aliases mantidos para não quebrar outros arquivos ─────────────
  static const Color secondary = Color(0xFF2D6A4F);
  static const Color accent    = Color(0xFFE9C46A);
  static const Color xpGold    = Color(0xFFE9C46A);
}
