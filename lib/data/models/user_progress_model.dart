// lib/data/models/user_progress_model.dart
// Representa o progresso do usuÃ¡rio (XP, streak, liÃ§Ãµes concluÃ­das)
// ResponsÃ¡vel: Marcos
// Os dados ficam no Firestore (banco de dados Firebase)

class UserProgressModel {
  final String userId;
  final int totalXp;
  final int streak;           // Dias consecutivos de estudo
  final List<String> completedLessons; // IDs das liÃ§Ãµes concluÃ­das

  UserProgressModel({
    required this.userId,
    required this.totalXp,
    required this.streak,
    required this.completedLessons,
  });

  /// Cria um UserProgressModel a partir dos dados do Firestore
  factory UserProgressModel.fromFirestore(Map<String, dynamic> data) {
    return UserProgressModel(
      userId: data['userId'] ?? '',
      totalXp: (data['totalXp'] ?? 0).toInt(),
      streak: (data['streak'] ?? 0).toInt(),
      completedLessons: List<String>.from(data['completedLessons'] ?? []),
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalXp': totalXp,
      'streak': streak,
      'completedLessons': completedLessons,
    };
  }
}
