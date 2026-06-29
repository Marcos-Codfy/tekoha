// lib/features/lesson/domain/entities/lesson.dart
// Camada: Domain (Lesson).
//
// Entidade pura de uma licao dentro de um modulo.

class Lesson {
  final String id;
  final String title;
  final String moduleId;
  final int order;
  final int xpReward;

  const Lesson({
    required this.id,
    required this.title,
    required this.moduleId,
    required this.order,
    required this.xpReward,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          moduleId == other.moduleId &&
          order == other.order &&
          xpReward == other.xpReward;

  @override
  int get hashCode => Object.hash(id, title, moduleId, order, xpReward);

  @override
  String toString() =>
      'Lesson(id: $id, title: $title, moduleId: $moduleId, order: $order)';
}
