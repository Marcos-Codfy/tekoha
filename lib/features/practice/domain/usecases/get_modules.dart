// lib/features/practice/domain/usecases/get_modules.dart
// Camada: Domain (Practice).
//
// UseCase: encapsula UMA acao de negocio. Aqui e simples (so chama o
// repo), mas a estrutura ja existe pra quando entrar regra (ex.:
// "modulo so e visivel se tiver pelo menos 1 licao publicada", "ordenar
// por progresso do usuario", etc).
//
// Provider chama UseCase, UseCase chama Repository. O Provider nao
// conhece o Repository diretamente — ganho: testar Provider so precisa
// mockar o UseCase, e testar UseCase so precisa mockar o Repository.

import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/module.dart';
import '../repositories/practice_repository.dart';

class GetModulesUseCase {
  final PracticeRepository _repository;

  const GetModulesUseCase(this._repository);

  /// Default language = `nheengatu` (so idioma atualmente suportado).
  /// Quando suportarmos mais, o Provider passa via parametro.
  Future<Result<List<Module>, Failure>> call({
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) {
    return _repository.getModules(
      language: language,
      forceRefresh: forceRefresh,
    );
  }
}
