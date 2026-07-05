// lib/features/auth/presentation/providers/auth_provider.dart
// Camada: Presentation (Auth).
//
// Provider de autenticacao. Substitui o AuthProvider legado.
// Diferencas chave:
//   - depende do contrato AuthRepository (nao do FirebaseAuth direto)
//   - erros vem tipados via [Failure] (a UI traduz com `userMessage`)
//   - `isAvailable` espelha o status do backend (Firebase pode estar off)

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  final SignInUseCase _signIn;
  final RegisterUseCase _register;
  final SignOutUseCase _signOut;

  AuthUser? _user;
  bool _isLoading = true;
  Failure? _failure;
  StreamSubscription<AuthUser?>? _subscription;

  AuthProvider({
    required AuthRepository repository,
    required SignInUseCase signIn,
    required RegisterUseCase register,
    required SignOutUseCase signOut,
  })  : _repository = repository,
        _signIn = signIn,
        _register = register,
        _signOut = signOut {
    _user = _repository.currentUser;
    _isLoading = !_repository.isAvailable ? false : (_user == null);
    _subscription = _repository.authStateChanges().listen((user) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  // ── Getters ─────────────────────────────────────────────────────────
  AuthUser? get currentUser => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  /// `true` se o backend de auth foi inicializado com sucesso.
  /// UI pode usar pra desabilitar campos de login em ambientes sem auth.
  bool get isAvailable => _repository.isAvailable;

  Failure? get failure => _failure;
  String? get errorMessage => _failure?.userMessage;

  // ── Acoes ───────────────────────────────────────────────────────────

  /// Limpa o erro (chamado ao entrar nas telas de auth).
  void clearError() {
    if (_failure != null) {
      _failure = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    final result = await _signIn(email: email, password: password);
    return result.fold(
      onSuccess: (_) {
        _failure = null;
        notifyListeners();
        return true;
      },
      onFailure: (Failure failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  Future<bool> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final result = await _register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return result.fold(
      onSuccess: (_) {
        _failure = null;
        notifyListeners();
        return true;
      },
      onFailure: (Failure failure) {
        _failure = failure;
        notifyListeners();
        return false;
      },
    );
  }

  Future<void> signOut() async {
    await _signOut();
    // O stream do authStateChanges vai notificar `_user = null`.
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
