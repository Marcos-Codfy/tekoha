// lib/features/lesson/domain/builders/trail_builder.dart
// Camada: Domain (Lesson). Funcao pura — sem Flutter.
//
// Divide as palavras de uma licao em ETAPAS da trilha de aprendizado
// (ESP-005). A divisao respeita a progressao pedagogica "raiz antes do
// composto" ja aplicada no campo `order` do banco (ESP-002/D7): cada
// etapa agrupa palavras por afinidade semantica, com no maximo 3
// palavras (12 exercicios) pra nao saturar.
//
// Fundamentacao (ver 05_Registro_Decisoes_Cientificas.md):
//   - Chunking (Miller, 1956)
//   - Carga cognitiva (Sweller, 1988)
//   - Scaffolding (Wood, Bruner & Ross, 1976)
//   - Goal-Gradient na trilha (Kivetz et al., 2006)

import '../entities/trail_stage.dart';
import '../entities/word.dart';

/// Especificacao estatica de uma etapa: titulo + quantas palavras pega.
class TrailStageSpec {
  final String title;
  final int wordCount;

  const TrailStageSpec(this.title, this.wordCount);
}

class TrailBuilder {
  TrailBuilder._();

  /// Maximo de palavras por etapa no fallback generico (3 palavras =
  /// 12 exercicios, teto definido na ESP-005).
  static const int kMaxWordsPerStage = 3;

  /// Divisao curada por modulo (chave = `Module.order`). Titulos e
  /// agrupamentos aprovados pelo autor em 02/07/2026 (ESP-005).
  /// A soma dos wordCount de cada lista deve bater com o total de
  /// palavras da licao — se nao bater (conteudo mudou no Airtable),
  /// o [build] cai no fallback generico automaticamente.
  static const Map<int, List<TrailStageSpec>> kSpecsByModuleOrder = {
    // Modulo 1 — Cumprimentos: raiz "puranga" primeiro, depois o arco
    // da conversa (perguntar -> responder -> agradecer -> despedir).
    1: [
      TrailStageSpec('A palavra curinga', 3),
      TrailStageSpec('O encontro', 3),
      TrailStageSpec('Sim e não', 2),
      TrailStageSpec('Gratidão e despedida', 2),
    ],
    // Modulo 2 — Apresentacao: pronomes -> identidade -> derivacao
    // kunha/kunhatai -> lacos sociais.
    2: [
      TrailStageSpec('Eu, você, ele', 3),
      TrailStageSpec('Quem é quem', 3),
      TrailStageSpec('Os pequenos', 2),
      TrailStageSpec('Laços', 2),
    ],
    // Modulo 3 — Natureza: agua -> ceu -> mata -> quem vive nela.
    3: [
      TrailStageSpec('O mundo das águas', 3),
      TrailStageSpec('Os donos do céu', 2),
      TrailStageSpec('Dentro da mata', 3),
      TrailStageSpec('Os que vivem nela', 2),
    ],
  };

  /// Especificacao das etapas pra um modulo com [totalWords] palavras.
  /// Usa a divisao curada quando existe e o total confere; senao gera
  /// fallback generico com etapas de ate [kMaxWordsPerStage] palavras.
  static List<TrailStageSpec> specsFor(int moduleOrder, int totalWords) {
    final curated = kSpecsByModuleOrder[moduleOrder];
    if (curated != null) {
      final sum = curated.fold(0, (t, s) => t + s.wordCount);
      if (sum == totalWords) return curated;
    }
    return _genericSpecs(totalWords);
  }

  /// Quantidade de etapas da trilha de um modulo. Pra modulos sem
  /// divisao curada assume o fallback generico com [totalWords].
  static int stageCountFor(int moduleOrder, int totalWords) =>
      specsFor(moduleOrder, totalWords).length;

  /// Monta as etapas: ordena [words] por `order` e fatia conforme a
  /// especificacao do modulo.
  static List<TrailStage> build(
    List<Word> words, {
    required int moduleOrder,
  }) {
    if (words.isEmpty) return const [];

    final sorted = [...words]..sort((a, b) => a.order.compareTo(b.order));
    final specs = specsFor(moduleOrder, sorted.length);

    final stages = <TrailStage>[];
    var cursor = 0;
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final end = (cursor + spec.wordCount).clamp(0, sorted.length);
      stages.add(TrailStage(
        index: i,
        title: spec.title,
        words: sorted.sublist(cursor, end),
      ));
      cursor = end;
    }
    return stages;
  }

  /// Fallback: divide [totalWords] em etapas de ate 3 palavras, o mais
  /// uniforme possivel (10 -> 3/3/2/2). Titulos genericos "Etapa N".
  static List<TrailStageSpec> _genericSpecs(int totalWords) {
    if (totalWords <= 0) return const [];
    final stageCount = (totalWords / kMaxWordsPerStage).ceil();
    final base = totalWords ~/ stageCount;
    final remainder = totalWords % stageCount;
    return List.generate(stageCount, (i) {
      final count = i < remainder ? base + 1 : base;
      return TrailStageSpec('Etapa ${i + 1}', count);
    });
  }
}
