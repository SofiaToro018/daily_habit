import 'package:sqflite/sqflite.dart';
import '../../core/models/queue_operation.dart';
import 'database_helper.dart';

/// Data Access Object para operaciones en cola
///
/// Gestiona la cola de sincronización para modo offline
class QueueDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserta una nueva operación en la cola
  Future<void> insertOperation(QueueOperation operation) async {
    final db = await _dbHelper.database;
    await db.insert(
      'queue_operations',
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todas las operaciones pendientes ordenadas por fecha
  Future<List<QueueOperation>> getPendingOperations() async {
    final db = await _dbHelper.database;
    final maps = await db.query('queue_operations', orderBy: 'created_at ASC');
    return maps.map((map) => QueueOperation.fromMap(map)).toList();
  }

  /// Obtiene una operación específica por ID
  Future<QueueOperation?> getOperationById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'queue_operations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return QueueOperation.fromMap(maps.first);
  }

  /// Actualiza una operación (útil para incrementar intentos)
  Future<void> updateOperation(QueueOperation operation) async {
    final db = await _dbHelper.database;
    await db.update(
      'queue_operations',
      operation.toMap(),
      where: 'id = ?',
      whereArgs: [operation.id],
    );
  }

  /// Elimina una operación de la cola (cuando se sincroniza exitosamente)
  Future<void> deleteOperation(String id) async {
    final db = await _dbHelper.database;
    await db.delete('queue_operations', where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina todas las operaciones de la cola
  Future<void> deleteAllOperations() async {
    final db = await _dbHelper.database;
    await db.delete('queue_operations');
  }

  /// Incrementa el contador de intentos de una operación
  Future<void> incrementAttemptCount(String id, String error) async {
    final db = await _dbHelper.database;
    final operation = await getOperationById(id);

    if (operation == null) return;

    await db.update(
      'queue_operations',
      {'attempt_count': operation.attemptCount + 1, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene el conteo de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM queue_operations',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Elimina operaciones con demasiados intentos fallidos
  Future<void> deleteFailedOperations({int maxAttempts = 5}) async {
    final db = await _dbHelper.database;
    await db.delete(
      'queue_operations',
      where: 'attempt_count >= ?',
      whereArgs: [maxAttempts],
    );
  }
}
