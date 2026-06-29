// lib/features/culture/domain/entities/culture_content.dart
// Camada: Domain (Culture).
//
// Card de conteudo cultural exibido na aba Cultura.
// Pertence a um idioma e uma categoria (history, cosmology, habits,
// curiosities).

class CultureContent {
  final String id;
  final String language;
  final String category;
  final String title;
  final String body;
  final int order;
  final bool isActive;

  const CultureContent({
    required this.id,
    required this.language,
    required this.category,
    required this.title,
    required this.body,
    required this.order,
    required this.isActive,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CultureContent &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          language == other.language &&
          category == other.category &&
          title == other.title &&
          body == other.body &&
          order == other.order &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      Object.hash(id, language, category, title, body, order, isActive);

  @override
  String toString() =>
      'CultureContent(id: $id, language: $language, category: $category, title: $title)';
}
