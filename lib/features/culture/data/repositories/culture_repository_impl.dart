// lib/features/culture/data/repositories/culture_repository_impl.dart
//
// Cache em memoria por chave composta `language::category` — alternar
// entre chips ja visitados e instantaneo.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/culture_content.dart';
import '../../domain/repositories/culture_repository.dart';
import '../datasources/culture_remote_datasource.dart';
import '../mappers/culture_content_mapper.dart';

class CultureRepositoryImpl implements CultureRepository {
  final CultureRemoteDataSource _remote;

  final Map<String, List<CultureContent>> _cache = {};

  CultureRepositoryImpl(this._remote);

  String _cacheKey(String language, String category) =>
      '$language::$category';

  @override
  Future<Result<List<CultureContent>, Failure>> getContent({
    required String language,
    required String category,
    bool forceRefresh = false,
  }) async {
    final key = _cacheKey(language, category);
    if (!forceRefresh && _cache.containsKey(key)) {
      return Success(_cache[key]!);
    }

    final dtoResult = await _remote.fetchContent(
      language: language,
      category: category,
    );

    return dtoResult.fold(
      onSuccess: (dtos) {
        final items = CultureContentMapper.toEntityList(dtos);
        _cache[key] = items;
        return Success(items);
      },
      onFailure: (f) => FailureResult(f),
    );
  }
}
