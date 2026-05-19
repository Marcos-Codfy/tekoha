// lib/presentation/providers/auth_provider.dart
// Gerencia o estado de autenticacao globalmente no app.
// Responsavel: Marcos
//
// Resiliencia: o construtor envolve o acesso ao FirebaseAuth.instance em
// try/catch. Se o Firebase nao tiver sido inicializado (ex.: rodando no
// Chrome sem config web), o provider vira um stub no-op em vez de quebrar
// o app. signIn/register devolvem erro amigavel nesse caso.

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  /// Pode ser null se o Firebase nao foi inicializado neste ambiente.
  FirebaseAuth? _auth;

  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _user;

  /// `true` se o Firebase Auth foi inicializado com sucesso. UI pode usar
  /// pra esconder/desabilitar login quando o ambiente nao suporta.
  bool get isAvailable => _auth != null;

  AuthProvider() {
    try {
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen((User? user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      // Firebase nao inicializado (provavelmente web sem config).
      // App segue funcionando — so login/registro ficam indisponiveis.
      _isLoading = false;
      debugPrint('[Tekoha] AuthProvider: Firebase indisponivel — $e');
    }
  }

  /// Limpa a mensagem de erro (chamado ao entrar nas telas de auth).
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (_auth == null) {
      _errorMessage = 'Login indisponível neste ambiente.';
      notifyListeners();
      return false;
    }
    try {
      _errorMessage = null;
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    if (_auth == null) {
      _errorMessage = 'Cadastro indisponível neste ambiente.';
      notifyListeners();
      return false;
    }
    try {
      _errorMessage = null;
      await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateError(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    if (_auth == null) return;
    await _auth!.signOut();
  }

  String _translateError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns minutos.';
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      default:
        return 'Erro ao autenticar. Tente novamente.';
    }
  }
}
