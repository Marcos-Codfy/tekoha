// lib/features/auth/data/mappers/firebase_user_mapper.dart
//
// Converte FirebaseAuth User -> AuthUser (entity).

import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_user.dart';

class FirebaseUserMapper {
  FirebaseUserMapper._();

  static AuthUser toEntity(User user) {
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }
}
