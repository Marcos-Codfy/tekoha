// lib/features/practice/data/dtos/airtable_module_dto.dart
// Camada: Data (Practice).
//
// DTO (Data Transfer Object) que ESPELHA a estrutura do record do
// Airtable. O dominio nao deveria ter campos `record['fields']` —
// isolamos isso aqui.
//
// O DTO nao tem regras de negocio; so converte o JSON em campos
// fortemente tipados. A traducao DTO -> Entity acontece no Mapper.

class AirtableModuleDto {
  final String id;
  final String name;
  final String description;
  final String language;
  final int order;

  const AirtableModuleDto({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.order,
  });

  /// Constroi a DTO a partir do shape `{id, fields: {...}}` que vem do
  /// Airtable. Fallbacks defensivos: campo ausente vira string vazia ou 0.
  factory AirtableModuleDto.fromAirtable(Map<String, dynamic> record) {
    final id = (record['id'] ?? '').toString();
    // Map<String, dynamic>.from absorve `Map<dynamic, dynamic>` (que aparece
    // em literais Dart fora de json.decode) sem explodir o cast.
    final fieldsRaw = record['fields'];
    final fields = fieldsRaw is Map
        ? Map<String, dynamic>.from(fieldsRaw)
        : <String, dynamic>{};
    return AirtableModuleDto(
      id: id,
      name: (fields['name'] ?? '').toString(),
      description: (fields['description'] ?? '').toString(),
      language: (fields['language'] ?? '').toString(),
      // Airtable pode mandar order como int OU double — `num` cobre os dois.
      order: (fields['order'] is num) ? (fields['order'] as num).toInt() : 0,
    );
  }
}
