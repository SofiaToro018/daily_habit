/// Modelo de datos para un hábito
///
/// Representa un hábito que el usuario desea rastrear.
/// Incluye información sobre su estado de completado y marca de tiempo.
class Habit {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime updatedAt;
  final bool deleted;
  final DateTime? lastCompletedAt;
  final int streak; // Racha de días consecutivos

  Habit({
    required this.id,
    required this.title,
    this.description,
    required this.completed,
    required this.updatedAt,
    this.deleted = false,
    this.lastCompletedAt,
    this.streak = 0,
  });

  /// Crea un Habit desde un Map (usado para SQLite)
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      completed: (map['completed'] as int) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      deleted: (map['deleted'] as int) == 1,
      lastCompletedAt: map['last_completed_at'] != null
          ? DateTime.parse(map['last_completed_at'] as String)
          : null,
      streak: map['streak'] as int? ?? 0,
    );
  }

  /// Convierte el Habit a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
      'deleted': deleted ? 1 : 0,
      'last_completed_at': lastCompletedAt?.toIso8601String(),
      'streak': streak,
    };
  }

  /// Crea un Habit desde JSON (usado para API)
  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deleted: json['deleted'] as bool? ?? false,
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.parse(json['lastCompletedAt'] as String)
          : null,
      streak: json['streak'] as int? ?? 0,
    );
  }

  /// Convierte el Habit a JSON (para API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'updatedAt': updatedAt.toIso8601String(),
      'deleted': deleted,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'streak': streak,
    };
  }

  /// Crea una copia del Habit con campos modificados
  Habit copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? updatedAt,
    bool? deleted,
    DateTime? lastCompletedAt,
    int? streak,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      streak: streak ?? this.streak,
    );
  }

  @override
  String toString() {
    return 'Habit(id: $id, title: $title, completed: $completed, streak: $streak)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Habit && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
