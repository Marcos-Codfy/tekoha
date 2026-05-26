// lib/data/models/module_model.dart
// Representa um modulo de ensino (Cumprimentos, Apresentacao, Natureza, etc).
// Dados vem da tabela Modules do Airtable.

class ModuleModel {
  final String id;
  final String name;
  final String description;
  final String language;
  final int order;

  const ModuleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.order,
  });

  /// Cria um ModuleModel a partir do JSON do Airtable.
  /// [id] vem do nivel raiz do record; [fields] vem do objeto `fields`.
  factory ModuleModel.fromAirtable(String id, Map<String, dynamic> fields) {
    return ModuleModel(
      id: id,
      name:        (fields['name']        ?? '').toString(),
      description: (fields['description'] ?? '').toString(),
      language:    (fields['language']    ?? '').toString(),
      order:       (fields['order'] ?? 0).toInt(),
    );
  }
}
