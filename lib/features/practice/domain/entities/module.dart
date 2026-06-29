// lib/features/practice/domain/entities/module.dart
// Camada: Domain (Practice).
//
// Entidade de DOMINIO de um modulo de ensino. Difere de uma DTO porque
// nao sabe NADA de Airtable, JSON ou rede — e o conceito puro que o
// resto do app usa.
//
// Por que separar Entity de DTO?
//   - Trocar Airtable por Firestore amanha = trocar so o DataSource e
//     o Mapper. Entity NAO MUDA.
//   - UseCases recebem/retornam Entity, nao DTO. Tem zero acoplamento
//     com a fonte.
//   - Testes de UseCase nao precisam montar JSON de Airtable, so Module.

class Module {
  final String id;
  final String name;
  final String description;

  /// Codigo do idioma (ex.: 'nheengatu').
  final String language;

  /// Posicao do modulo na trilha (1, 2, 3...).
  final int order;

  const Module({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    required this.order,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Module &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          language == other.language &&
          order == other.order;

  @override
  int get hashCode => Object.hash(id, name, description, language, order);

  @override
  String toString() =>
      'Module(id: $id, name: $name, language: $language, order: $order)';
}
