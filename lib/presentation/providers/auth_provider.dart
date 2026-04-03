// lib/presentation/providers/auth_provider.dart
// Gerencia o estado de autenticaÃ§Ã£o globalmente no app
// ResponsÃ¡vel: Marcos
// TODO Sprint 2: Implementar com Provider

import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;

  // TODO Sprint 2: integrar com AuthService
}
