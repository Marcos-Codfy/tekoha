// lib/data/services/firebase_service.dart
// ServiÃ§o que salva e busca o progresso do usuÃ¡rio no Firestore
// ResponsÃ¡vel: Marcos
// Implementa o contrato ProgressRepository
// TODO Sprint 3: Implementar os mÃ©todos de progresso

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_progress_model.dart';
import '../repositories/progress_repository.dart';

class FirebaseService implements ProgressRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nome da coleÃ§Ã£o no Firestore onde ficam os progressos
  static const String _collection = 'user_progress';

  @override
  Future<UserProgressModel?> getUserProgress(String userId) async {
    // TODO: implementar no Sprint 3
    throw UnimplementedError('getUserProgress ainda nao implementado');
  }

  @override
  Future<void> saveProgress(UserProgressModel progress) async {
    // TODO: implementar no Sprint 3
    throw UnimplementedError('saveProgress ainda nao implementado');
  }

  @override
  Future<void> addXp(String userId, int xpAmount) async {
    // TODO: implementar no Sprint 3
    throw UnimplementedError('addXp ainda nao implementado');
  }

  @override
  Future<void> markLessonCompleted(String userId, String lessonId) async {
    // TODO: implementar no Sprint 3
    throw UnimplementedError('markLessonCompleted ainda nao implementado');
  }
}
