// lib/features/culture/data/mappers/culture_content_mapper.dart

import '../../domain/entities/culture_content.dart';
import '../dtos/airtable_culture_content_dto.dart';

class CultureContentMapper {
  CultureContentMapper._();

  static CultureContent toEntity(AirtableCultureContentDto dto) {
    return CultureContent(
      id: dto.id,
      language: dto.language,
      category: dto.category,
      title: dto.title,
      body: dto.body,
      order: dto.order,
      isActive: dto.isActive,
    );
  }

  static List<CultureContent> toEntityList(
    List<AirtableCultureContentDto> dtos,
  ) =>
      dtos.map(toEntity).toList(growable: false);
}
