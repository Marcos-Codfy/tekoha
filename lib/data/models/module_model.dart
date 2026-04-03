// lib/data/models/module_model.dart
// Representa um MÃ³dulo de ensino (ex: Cumprimentos, Natureza, FamÃ­lia)
// ResponsÃ¡vel: Marcos
// Os dados vÃªm do Airtable (tabela Modules)

class ModuleModel {
  final String id;
  final String name;
  final String language;
  final String description;
  final int order;
  final String? iconUrl;

  ModuleModel({
    required this.id,
    required this.name,
    required this.language,
    required this.description,
    required this.order,
    this.iconUrl,
  });

  /// Cria um ModuleModel a partir dos dados que chegam do Airtable (JSON)
  factory ModuleModel.fromAirtable(String id, Map<String, dynamic> fields) {
    return ModuleModel(
      id: id,
      name: fields['name'] ?? '',
      language: fields['language'] ?? '',
      description: fields['description'] ?? '',
      order: (fields['order'] ?? 0).toInt(),
      iconUrl: fields['icon_url'],
    );
  }
}
