// lib/features/culture/data/datasources/culture_remote_datasource.dart

import '../../../../core/errors/failures.dart';
import '../../../../core/network/airtable_client.dart';
import '../../../../core/result/result.dart';
import '../dtos/airtable_culture_content_dto.dart';

abstract class CultureRemoteDataSource {
  Future<Result<List<AirtableCultureContentDto>, Failure>> fetchContent({
    required String language,
    required String category,
  });
}

class CultureRemoteDataSourceImpl implements CultureRemoteDataSource {
  final AirtableClient _client;
  final String tableName;

  const CultureRemoteDataSourceImpl(
    this._client, {
    this.tableName = 'CultureContent',
  });

  @override
  Future<Result<List<AirtableCultureContentDto>, Failure>> fetchContent({
    required String language,
    required String category,
  }) async {
    // language e category sao campos diretos (nao linked records) — a
    // formula no servidor funciona sem o problema dos Linked Records.
    final formula =
        "AND({is_active}=TRUE(), {language}='$language', {category}='$category')";

    final result = await _client.getRecords(
      tableName,
      queryParams: {
        'filterByFormula': formula,
        'sort[0][field]': 'order',
        'sort[0][direction]': 'asc',
      },
    );

    return result.fold(
      onSuccess: (records) {
        final dtos = records
            .map(AirtableCultureContentDto.fromAirtable)
            .toList();
        return Success(dtos);
      },
      onFailure: (f) => FailureResult(f),
    );
  }
}
