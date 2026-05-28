// lib/data/models/word_model.dart
// Representa uma palavra do Nheengatu vinda da tabela Words do Airtable.
// Cada Word vira exercicio (Quiz tradicional + exercicios de audio quando
// `audio_url` esta preenchido).
// Responsavel: Marcos (gerado por Claude na Sprint 3)

class WordModel {
  final String id;
  final String nheengatu;       // palavra ou expressao em Nheengatu (ex: "Puranga ara")
  final String translation;     // traducao em portugues (ex: "Bom dia")
  final String pronunciation;   // pronuncia aportuguesada (ex: "pu-RAN-ga A-ra")
  final String culturalNote;    // curiosidade cultural (so aparece quando o usuario acerta)
  final String lessonId;        // ID da licao no Airtable (chave estrangeira)
  final int order;              // ordem da palavra dentro da licao (1 a 10)
  final String audioUrl;        // URL publica do MP3 (GitHub raw). Vazio = sem audio.

  WordModel({
    required this.id,
    required this.nheengatu,
    required this.translation,
    required this.pronunciation,
    required this.culturalNote,
    required this.lessonId,
    required this.order,
    this.audioUrl = '', // opcional: a maioria das palavras nao tem audio
  });

  /// Cria um WordModel a partir do JSON que o Airtable devolve.
  /// [id] vem do nivel raiz do record do Airtable (ex: "recABC123").
  /// [fields] vem do objeto `fields` do mesmo record.
  factory WordModel.fromAirtable(String id, Map<String, dynamic> fields) {
    // Campo `lesson` no Airtable e Linked Record -> devolve array de IDs.
    // Mesmo pattern do LessonModel (consistencia entre os models).
    return WordModel(
      id: id,
      nheengatu:     (fields['nheengatu']     ?? '').toString(),
      translation:   (fields['translation']   ?? '').toString(),
      pronunciation: (fields['pronunciation'] ?? '').toString(),
      culturalNote:  (fields['cultural_note'] ?? '').toString(),
      lessonId:      (fields['lesson'] as List<dynamic>?)?.first?.toString() ?? '',
      order:         (fields['order'] ?? 0).toInt(),
      audioUrl:      (fields['audio_url'] ?? '').toString(),
    );
  }

  /// `true` se a palavra tem audio cadastrado. Usado pra decidir se a
  /// licao mostra exercicios de audio ou cai no fluxo de quiz puro.
  bool get hasAudio => audioUrl.trim().isNotEmpty;
}
