// lib/data/models/culture_content_model.dart
// Representa um card de conteudo cultural vindo da tabela CultureContent.
// Cada card pertence a um idioma e a uma categoria (history, cosmology,
// habits, curiosities). Exibido na CultureScreen.
// Responsavel: Marcos (Sprint 3, gerado por Claude)

class CultureContentModel {
  final String id;
  final String language;
  final String category;
  final String title;
  final String body;
  final int order;
  final bool isActive;

  const CultureContentModel({
    required this.id,
    required this.language,
    required this.category,
    required this.title,
    required this.body,
    required this.order,
    required this.isActive,
  });

  /// Cria um CultureContentModel a partir do JSON do Airtable.
  /// [id] vem do nivel raiz do record; [fields] vem do objeto `fields`.
  ///
  /// Fallbacks defensivos garantem que um campo faltante nao derruba
  /// a UI — o card aparece com texto vazio em vez de quebrar a tela.
  factory CultureContentModel.fromAirtable(
    String id,
    Map<String, dynamic> fields,
  ) {
    return CultureContentModel(
      id: id,
      language: (fields['language'] ?? '').toString(),
      category: (fields['category'] ?? '').toString(),
      title:    (fields['title']    ?? '').toString(),
      body:     (fields['body']     ?? '').toString(),
      order:    (fields['order']    ?? 0).toInt(),
      isActive: (fields['is_active'] as bool?) ?? false,
    );
  }
}
