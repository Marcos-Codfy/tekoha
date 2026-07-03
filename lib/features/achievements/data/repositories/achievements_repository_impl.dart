// lib/features/achievements/data/repositories/achievements_repository_impl.dart
// Camada: Data (Achievements). Impl com cache em memoria (definicoes
// mudam raramente — evita bater no Airtable a cada tela).

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_remote_datasource.dart';
import '../mappers/achievement_mapper.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  final AchievementsRemoteDataSource _dataSource;

  AchievementsRepositoryImpl(this._dataSource);

  List<Achievement>? _cache;

  @override
  Future<Result<List<Achievement>, Failure>> getAchievements({
    bool forceRefresh = false,
  }) async {
    final cached = _cache;
    if (!forceRefresh && cached != null) return Success(cached);

    final result = await _dataSource.fetchAchievements();
    return result.fold(
      onSuccess: (dtos) {
        final entities = dtos.map(AchievementMapper.toEntity).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        _cache = entities;
        return Success(entities);
      },
      onFailure: (f) => FailureResult(f),
    );
  }
}
