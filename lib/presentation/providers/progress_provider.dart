// lib/presentation/providers/progress_provider.dart
// Gerencia o XP e progresso do usuÃ¡rio globalmente
// ResponsÃ¡vel: Marcos
// TODO Sprint 3: Implementar com Provider + FirebaseService

import 'package:flutter/foundation.dart';

class ProgressProvider extends ChangeNotifier {
  int _totalXp = 0;
  int _streak = 0;

  int get totalXp => _totalXp;
  int get streak => _streak;

  // TODO Sprint 3: integrar com FirebaseService
}
