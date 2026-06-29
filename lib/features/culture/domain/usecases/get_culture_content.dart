// lib/features/culture/domain/usecases/get_culture_content.dart
// Camada: Domain (Culture).

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/culture_content.dart';
import '../repositories/culture_repository.dart';

class GetCultureContentUseCase {
  final CultureRepository _repository;

  const GetCultureContentUseCase(this._repository);

  Future<Result<List<CultureContent>, Failure>> call({
    required String category,
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) =>
      _repository.getContent(
        language: language,
        category: category,
        forceRefresh: forceRefresh,
      );
}
