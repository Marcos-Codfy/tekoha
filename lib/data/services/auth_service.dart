// lib/data/services/auth_service.dart
// ServiÃ§o de autenticaÃ§Ã£o usando Firebase Auth
// ResponsÃ¡vel: Marcos
// TODO Sprint 2: Implementar os mÃ©todos de login e cadastro

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Singleton: uma Ãºnica instÃ¢ncia do FirebaseAuth para o app todo
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna o usuÃ¡rio logado atualmente (null se nÃ£o estiver logado)
  User? get currentUser => _auth.currentUser;

  /// Stream que notifica o app quando o estado de login muda
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Faz login com e-mail e senha
  Future<User?> signInWithEmail(String email, String password) async {
    // TODO: implementar no Sprint 2
    throw UnimplementedError('signInWithEmail ainda nao implementado');
  }

  /// Cria uma nova conta com e-mail e senha
  Future<User?> registerWithEmail(String email, String password) async {
    // TODO: implementar no Sprint 2
    throw UnimplementedError('registerWithEmail ainda nao implementado');
  }

  /// Faz logout do usuÃ¡rio
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
