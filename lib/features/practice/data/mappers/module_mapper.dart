// lib/features/practice/data/mappers/module_mapper.dart
// Camada: Data (Practice).
//
// Funcao pura de conversao DTO -> Entity.
// Ficar separado do DTO permite testar sem montar JSON: passa uma DTO,
// recebe uma Entity, compara.

import '../../domain/entities/module.dart';
import '../dtos/airtable_module_dto.dart';

class ModuleMapper {
  ModuleMapper._();

  static Module toEntity(AirtableModuleDto dto) {
    return Module(
      id: dto.id,
      name: dto.name,
      description: dto.description,
      language: dto.language,
      order: dto.order,
    );
  }

  static List<Module> toEntityList(List<AirtableModuleDto> dtos) {
    return dtos.map(toEntity).toList(growable: false);
  }
}
