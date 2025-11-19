/// Modelo para operaciones en cola de sincronización
///
/// Representa una operación pendiente que debe sincronizarse
/// con el servidor cuando haya conexión disponible.
class QueueOperation {
  final String id;
  final String entity; // 'habit'
  final String entityId;
  final OperationType operation;
  final String payload; // JSON string
  final DateTime createdAt;
  final int attemptCount;
  final String? lastError;

  QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
  });

  /// Crea un QueueOperation desde un Map (SQLite)
  factory QueueOperation.fromMap(Map<String, dynamic> map) {
    return QueueOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      operation: OperationType.fromString(map['op'] as String),
      payload: map['payload'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      attemptCount: map['attempt_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  /// Convierte el QueueOperation a Map (SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': operation.value,
      'payload': payload,
      'created_at': createdAt.millisecondsSinceEpoch,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  /// Crea una copia con campos modificados
  QueueOperation copyWith({
    String? id,
    String? entity,
    String? entityId,
    OperationType? operation,
    String? payload,
    DateTime? createdAt,
    int? attemptCount,
    String? lastError,
  }) {
    return QueueOperation(
      id: id ?? this.id,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  String toString() {
    return 'QueueOperation(id: $id, entity: $entity, op: ${operation.value}, attempts: $attemptCount)';
  }
}

/// Tipos de operaciones soportadas
enum OperationType {
  create('CREATE'),
  update('UPDATE'),
  delete('DELETE');

  final String value;
  const OperationType(this.value);

  static OperationType fromString(String value) {
    return OperationType.values.firstWhere(
      (op) => op.value == value,
      orElse: () => throw ArgumentError('Invalid operation type: $value'),
    );
  }
}
