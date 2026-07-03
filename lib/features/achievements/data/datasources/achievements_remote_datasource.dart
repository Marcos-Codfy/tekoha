// lib/features/achievements/data/datasources/achievements_remote_datasource.dart
// Camada: Data (Achievements). Fala com o Airtable via AirtableClient.

import '../../../../core/errors/failures.dart';
import '../../../../core/network/airtable_client.dart';
import '../../../../core/result/result.dart';
import '../dtos/airtable_achievement_dto.dart';

abstract class AchievementsRemoteDataSource {
  Future<Result<List<AirtableAchievementDto>, Failure>> fetchAchievements();
}

class AchievementsRemoteDataSourceImpl implements AchievementsRemoteDataSource {
  final AirtableClient _client;
  final String tableName;

  const AchievementsRemoteDataSourceImpl(
    this._client, {
    this.tableName = 'Achievements',
  });

  @override
  Future<Result<List<AirtableAchievementDto>, Failure>>
      fetchAchievements() async {
    final result = await _client.getRecords(
      tableName,
      queryParams: {
        'filterByFormula': '{is_active}=TRUE()',
        'sort[0][field]': 'order',
        'sort[0][direction]': 'asc',
      },
    );

    return result.fold(
      onSuccess: (records) => Success(
        records.map(AirtableAchievementDto.fromAirtable).toList(),
      ),
      onFailure: (f) => FailureResult(f),
    );
  }
}
