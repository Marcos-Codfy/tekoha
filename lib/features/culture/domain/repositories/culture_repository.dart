// lib/features/culture/domain/repositories/culture_repository.dart
// Camada: Domain (Culture).

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/culture_content.dart';

abstract class CultureRepository {
  /// Busca cards da Cultura filtrados por idioma e categoria. So
  /// retorna `is_active = true`. Ordenado por `order`.
  /// Cache em memoria por (language, category).
  Future<Result<List<CultureContent>, Failure>> getContent({
    required String language,
    required String category,
    bool forceRefresh = false,
  });
}
