// lib/features/auth/domain/entities/auth_user.dart
// Camada: Domain (Auth).
//
// Entidade pura de usuario autenticado. NAO depende de Firebase.
// Quem implementa o AuthRepository pode mapear de FirebaseUser, ou
// de qualquer outra fonte de identidade.

class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);

  @override
  String toString() => 'AuthUser(uid: $uid, email: $email)';
}
