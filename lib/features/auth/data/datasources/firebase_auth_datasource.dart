// lib/features/auth/data/datasources/firebase_auth_datasource.dart
// Camada: Data (Auth).
//
// Wrapper concreto sobre FirebaseAuth. Resiliente a Firebase ausente
// (ex.: rodando no Chrome sem config) — vira no-op nesse caso, em vez
// de quebrar o app.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

abstract class FirebaseAuthDataSource {
  /// `true` se o FirebaseAuth.instance foi obtido com sucesso no boot.
  bool get isAvailable;

  Stream<User?> authStateChanges();

  User? get currentUser;

  Future<User> signIn(String email, String password);

  /// [displayName] opcional: gravado no perfil do Firebase logo apos a
  /// criacao da conta (aparece no Perfil do app).
  Future<User> register(String email, String password, {String? displayName});

  Future<void> signOut();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuth? _auth;

  FirebaseAuthDataSourceImpl() {
    try {
      _auth = FirebaseAuth.instance;
    } catch (e) {
      // Firebase nao inicializado (web sem config, por exemplo).
      // App segue funcionando — login/registro ficam indisponiveis.
      _auth = null;
      debugPrint('[Tekoha] FirebaseAuthDataSource: Firebase indisponivel — $e');
    }
  }

  @override
  bool get isAvailable => _auth != null;

  @override
  Stream<User?> authStateChanges() =>
      _auth?.authStateChanges() ?? const Stream<User?>.empty();

  @override
  User? get currentUser => _auth?.currentUser;

  /// Throws [FirebaseAuthException] em caso de credenciais invalidas;
  /// o repository converte em [AuthFailure] tipada.
  @override
  Future<User> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'auth-unavailable',
        message: 'FirebaseAuth nao inicializado.',
      );
    }
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user!;
  }

  @override
  Future<User> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw FirebaseAuthException(
        code: 'auth-unavailable',
        message: 'FirebaseAuth nao inicializado.',
      );
    }
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    // Grava o nome no perfil do Firebase. Se falhar, nao derruba o
    // cadastro — o nome pode ser preenchido depois.
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      try {
        await user.updateDisplayName(name);
        await user.reload();
      } catch (e) {
        debugPrint('[Tekoha] Falha ao gravar displayName: $e');
      }
    }
    return auth.currentUser ?? user;
  }

  @override
  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
