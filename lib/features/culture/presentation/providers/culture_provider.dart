// lib/features/culture/presentation/providers/culture_provider.dart
//
// Provider dedicado a Cultura. Mantem categoria atual + lista atual.

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/culture_content.dart';
import '../../domain/usecases/get_culture_content.dart';

enum CultureStatus { idle, loading, loaded, error }

class CultureProvider extends ChangeNotifier {
  final GetCultureContentUseCase _getContent;

  CultureProvider(this._getContent);

  String _currentCategory = '';
  List<CultureContent> _items = const [];
  CultureStatus _status = CultureStatus.idle;
  Failure? _failure;

  String get currentCategory => _currentCategory;
  List<CultureContent> get items => List.unmodifiable(_items);
  CultureStatus get status => _status;
  Failure? get failure => _failure;
  String? get errorMessage => _failure?.userMessage;

  bool get isLoading => _status == CultureStatus.loading;
  bool get hasError => _status == CultureStatus.error;
  bool get isLoaded => _status == CultureStatus.loaded;

  Future<void> load({
    required String category,
    String language = 'nheengatu',
    bool forceRefresh = false,
  }) async {
    _currentCategory = category;
    _status = CultureStatus.loading;
    _failure = null;
    _items = const [];
    notifyListeners();

    final result = await _getContent(
      category: category,
      language: language,
      forceRefresh: forceRefresh,
    );

    result.fold(
      onSuccess: (list) {
        _items = list;
        _status = CultureStatus.loaded;
        _failure = null;
      },
      onFailure: (failure) {
        _items = const [];
        _status = CultureStatus.error;
        _failure = failure;
      },
    );
    notifyListeners();
  }
}
