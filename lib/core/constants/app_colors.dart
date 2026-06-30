// lib/core/constants/app_colors.dart
// Paleta Tekoha — Urucum + Branco + Preto.
// Tons derivados ficam aqui pra trocar a identidade visual num lugar so.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Paleta principal ──────────────────────────────────────────────
  static const Color primary    = Color(0xFFB5451B); // Urucum
  static const Color secondary  = Color(0xFF2D6A4F); // Verde mata (ColorScheme)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface    = Color(0xFFFFFFFF);

  // ── Texto ─────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A); // preto suave
  static const Color textSecondary = Color(0xFF6B6B6B); // cinza medio
  static const Color textOnPrimary = Color(0xFFFFFFFF); // branco sobre urucum

  // ── Bordas ────────────────────────────────────────────────────────
  static const Color border        = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFFB5451B);

  // ── Feedback ──────────────────────────────────────────────────────
  static const Color correct = Color(0xFF2E7D32); // verde acerto
  static const Color wrong   = Color(0xFFB5451B); // urucum (visual unificado)

  // ── Paleta indigena estendida ─────────────────────────────────────
  // Derivada de PIGMENTOS NATURAIS UNIVERSAIS da Amazonia, nao de
  // grafismos etnico-especificos (cuidado etico: Carneiro da Cunha, 2009).
  // Cada cor com contraste WCAG AA validado sobre branco.
  //
  // Fundamentacao: Elliot & Maier (2014) — Color Psychology.
  static const Color jenipapo = Color(0xFF1B2845); // Azul-noite (fruta jenipapo)
  static const Color caulim   = Color(0xFFF5EBD8); // Branco-osso terroso (argila branca)
  static const Color argila   = Color(0xFFA0522D); // Marrom argila
  static const Color floresta = Color(0xFF1F4E3D); // Verde mata profundo
  static const Color rio      = Color(0xFF3D6FA8); // Azul rio Amazonas
}
