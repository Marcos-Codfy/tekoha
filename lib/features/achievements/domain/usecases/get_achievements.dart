// lib/features/achievements/domain/usecases/get_achievements.dart

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/achievement.dart';
import '../repositories/achievements_repository.dart';

class GetAchievementsUseCase {
  final AchievementsRepository _repository;

  const GetAchievementsUseCase(this._repository);

  Future<Result<List<Achievement>, Failure>> call({
    bool forceRefresh = false,
  }) =>
      _repository.getAchievements(forceRefresh: forceRefresh);
}
