// lib/features/lesson/domain/entities/word.dart
// Camada: Domain (Lesson).
//
// Entidade pura de uma palavra/expressao do Nheengatu. Cada Word vira
// pelo menos um exercicio (quiz tradicional + audio quando `audioUrl`
// existe).

class Word {
  final String id;

  /// Palavra ou expressao em Nheengatu (ex.: "Puranga ara").
  final String nheengatu;

  /// Traducao em portugues (ex.: "Bom dia").
  final String translation;

  /// Pronuncia aportuguesada (ex.: "pu-RAN-ga A-ra").
  final String pronunciation;

  /// Nota cultural exibida apos acerto (so na 1a vez na sessao).
  final String culturalNote;

  /// FK para a Lesson dona.
  final String lessonId;

  /// Posicao da palavra dentro da licao.
  final int order;

  /// URL publica do MP3 (vazio = palavra sem audio, fluxo de quiz puro).
  final String audioUrl;

  const Word({
    required this.id,
    required this.nheengatu,
    required this.translation,
    required this.pronunciation,
    required this.culturalNote,
    required this.lessonId,
    required this.order,
    this.audioUrl = '',
  });

  /// `true` se a palavra tem audio cadastrado.
  /// Usado pra decidir entre fluxo misto (audio + quiz) ou quiz puro.
  bool get hasAudio => audioUrl.trim().isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Word &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nheengatu == other.nheengatu &&
          translation == other.translation &&
          pronunciation == other.pronunciation &&
          culturalNote == other.culturalNote &&
          lessonId == other.lessonId &&
          order == other.order &&
          audioUrl == other.audioUrl;

  @override
  int get hashCode => Object.hash(
        id,
        nheengatu,
        translation,
        pronunciation,
        culturalNote,
        lessonId,
        order,
        audioUrl,
      );

  @override
  String toString() =>
      'Word(id: $id, nheengatu: $nheengatu, translation: $translation, order: $order)';
}
