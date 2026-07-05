// lib/features/achievements/domain/entities/achievement.dart
// Camada: Domain (Achievements).
//
// Entidade pura de UMA conquista (ESP-006). As DEFINICOES vem do
// Airtable (tabela Achievements — conteudo editorial); o ESTADO de
// desbloqueio por usuario vive no UserProgress (Firestore).
//
// Fundamentacao do sistema: Antin & Churchill (2011) — funcoes sociais
// dos badges; SDT-Competencia (Deci & Ryan, 2000). Ver Material Base
// 07_Conquistas_Design_e_Fundamentacao.md.

/// Tipos de criterio que o app sabe avaliar. `unknown` protege o app
/// de valores novos criados no Airtable antes do codigo suporta-los
/// (conquista fica invisivel em vez de quebrar).
enum AchievementCriterionType {
  stagesDone,
  modulesDone,
  xpTotal,
  streakDays,
  wordsMastered,
  speechCorrect,
  unknown;

  /// Converte o valor do single select do Airtable (snake_case).
  static AchievementCriterionType fromCode(String code) {
    switch (code) {
      case 'stages_done':
        return AchievementCriterionType.stagesDone;
      case 'modules_done':
        return AchievementCriterionType.modulesDone;
      case 'xp_total':
        return AchievementCriterionType.xpTotal;
      case 'streak_days':
        return AchievementCriterionType.streakDays;
      case 'words_mastered':
        return AchievementCriterionType.wordsMastered;
      case 'speech_correct':
        return AchievementCriterionType.speechCorrect;
      default:
        return AchievementCriterionType.unknown;
    }
  }
}

class Achievement {
  final String id;

  /// Chave estavel usada pelo codigo e pelo Firestore (ex.: `streak_7`).
  final String code;

  /// Nome exibido (ex.: "Guardiao da Chama").
  final String title;

  /// Microcopy de celebracao, exibido quando desbloqueada.
  final String description;

  /// Dica exibida enquanto travada (goal setting — Antin & Churchill).
  final String lockedHint;

  final AchievementCriterionType criterionType;
  final int criterionValue;

  /// PNG no CDN (tekoha-assets). Vazio = sem icone (UI usa fallback).
  final String iconUrl;

  final int order;
  final bool isActive;

  const Achievement({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.lockedHint,
    required this.criterionType,
    required this.criterionValue,
    required this.iconUrl,
    required this.order,
    required this.isActive,
  });

  @override
  String toString() =>
      'Achievement(code: $code, title: $title, '
      'criterio: $criterionType>=$criterionValue)';
}
