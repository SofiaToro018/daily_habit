import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/habit.dart';
import '../../core/models/queue_operation.dart';
import '../local/habit_dao.dart';
import '../local/queue_dao.dart';
import '../remote/habit_api_service.dart';

/// Repositorio de hábitos con estrategia offline-first
///
/// Implementa la lógica de negocio para gestionar hábitos,
/// coordinando entre la base de datos local y la API remota.
class HabitRepository {
  final HabitDao _habitDao;
  final QueueDao _queueDao;
  final HabitApiService _apiService;
  final Connectivity _connectivity;
  final Uuid _uuid;

  HabitRepository({
    HabitDao? habitDao,
    QueueDao? queueDao,
    HabitApiService? apiService,
    Connectivity? connectivity,
  }) : _habitDao = habitDao ?? HabitDao(),
       _queueDao = queueDao ?? QueueDao(),
       _apiService = apiService ?? HabitApiService(),
       _connectivity = connectivity ?? Connectivity(),
       _uuid = const Uuid();

  /// Obtiene todos los hábitos (offline-first)
  ///
  /// 1. Devuelve datos locales inmediatamente
  /// 2. Si hay conexión, sincroniza en segundo plano
  Future<List<Habit>> getAllHabits({bool forceRefresh = false}) async {
    // Primero devolver datos locales
    final localHabits = await _habitDao.getAllHabits();

    // Si hay conexión y se solicita refresh, sincronizar
    if (forceRefresh && await _isConnected()) {
      try {
        await _syncFromServer();
      } catch (e) {
        // Silenciosamente fallar - ya tenemos datos locales
        // ignore: avoid_print
        print('Error sincronizando: $e');
      }
      // Devolver datos actualizados
      return await _habitDao.getAllHabits();
    }

    return localHabits;
  }

  /// Obtiene hábitos filtrados por estado
  Future<List<Habit>> getHabitsByStatus({required bool completed}) async {
    return await _habitDao.getHabitsByStatus(completed: completed);
  }

  /// Obtiene un hábito por ID
  Future<Habit?> getHabitById(String id) async {
    return await _habitDao.getHabitById(id);
  }

  /// Crea un nuevo hábito
  Future<Habit> createHabit(String title, {String? description}) async {
    final habit = Habit(
      id: _uuid.v4(),
      title: title,
      description: description,
      completed: false,
      updatedAt: DateTime.now(),
    );

    // Guardar localmente primero
    await _habitDao.insertHabit(habit);

    // Encolar operación para sincronización
    await _enqueueOperation(
      entityId: habit.id,
      operation: OperationType.create,
      payload: habit.toJson(),
    );

    // Intentar sincronizar inmediatamente si hay conexión
    if (await _isConnected()) {
      _trySyncOperation(habit.id, OperationType.create);
    }

    return habit;
  }

  /// Actualiza un hábito existente
  Future<void> updateHabit(Habit habit) async {
    final updatedHabit = habit.copyWith(updatedAt: DateTime.now());

    // Guardar localmente
    await _habitDao.updateHabit(updatedHabit);

    // Encolar operación
    await _enqueueOperation(
      entityId: updatedHabit.id,
      operation: OperationType.update,
      payload: updatedHabit.toJson(),
    );

    // Intentar sincronizar
    if (await _isConnected()) {
      _trySyncOperation(updatedHabit.id, OperationType.update);
    }
  }

  /// Alterna el estado de completado de un hábito
  Future<void> toggleHabitCompletion(String id) async {
    await _habitDao.toggleHabitCompletion(id);

    final habit = await _habitDao.getHabitById(id);
    if (habit != null) {
      await _enqueueOperation(
        entityId: id,
        operation: OperationType.update,
        payload: habit.toJson(),
      );

      if (await _isConnected()) {
        _trySyncOperation(id, OperationType.update);
      }
    }
  }

  /// Elimina un hábito (soft delete)
  Future<void> deleteHabit(String id) async {
    // Marcar como eliminado localmente
    await _habitDao.deleteHabit(id);

    // Encolar operación
    await _enqueueOperation(
      entityId: id,
      operation: OperationType.delete,
      payload: {},
    );

    // Intentar sincronizar
    if (await _isConnected()) {
      _trySyncOperation(id, OperationType.delete);
    }
  }

  /// Obtiene hábitos con racha activa
  Future<List<Habit>> getHabitsWithStreak() async {
    return await _habitDao.getHabitsWithStreak();
  }

  /// Sincroniza datos desde el servidor
  Future<void> _syncFromServer() async {
    try {
      final remoteHabits = await _apiService.fetchAllHabits();

      for (final remoteHabit in remoteHabits) {
        final localHabit = await _habitDao.getHabitById(remoteHabit.id);

        if (localHabit == null) {
          // Nuevo hábito del servidor
          await _habitDao.insertHabit(remoteHabit);
        } else {
          // Resolver conflictos usando Last-Write-Wins
          if (remoteHabit.updatedAt.isAfter(localHabit.updatedAt)) {
            await _habitDao.updateHabit(remoteHabit);
          }
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error sincronizando desde servidor: $e');
      rethrow;
    }
  }

  /// Encola una operación para sincronización posterior
  Future<void> _enqueueOperation({
    required String entityId,
    required OperationType operation,
    required Map<String, dynamic> payload,
  }) async {
    final queueOp = QueueOperation(
      id: _uuid.v4(),
      entity: 'habit',
      entityId: entityId,
      operation: operation,
      payload: json.encode(payload),
      createdAt: DateTime.now(),
    );

    await _queueDao.insertOperation(queueOp);
  }

  /// Intenta sincronizar una operación específica
  Future<void> _trySyncOperation(String entityId, OperationType opType) async {
    // Esta función se ejecuta de forma asíncrona sin bloquear
    try {
      final operations = await _queueDao.getPendingOperations();
      final operation = operations.firstWhere(
        (op) => op.entityId == entityId && op.operation == opType,
        orElse: () => throw Exception('Operación no encontrada'),
      );

      await _executeSyncOperation(operation);
      await _queueDao.deleteOperation(operation.id);
    } catch (e) {
      // Silenciosamente fallar - se reintentará más tarde
      // ignore: avoid_print
      print('Error sincronizando operación: $e');
    }
  }

  /// Ejecuta una operación de sincronización
  Future<void> _executeSyncOperation(QueueOperation operation) async {
    final payload = json.decode(operation.payload);

    switch (operation.operation) {
      case OperationType.create:
        final habit = Habit.fromJson(payload);
        await _apiService.createHabit(habit, idempotencyKey: operation.id);
        break;

      case OperationType.update:
        final habit = Habit.fromJson(payload);
        await _apiService.updateHabit(habit, idempotencyKey: operation.id);
        break;

      case OperationType.delete:
        await _apiService.deleteHabit(operation.entityId);
        break;
    }
  }

  /// Verifica si hay conexión a Internet
  Future<bool> _isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }

  /// Obtiene el conteo de operaciones pendientes
  Future<int> getPendingOperationsCount() async {
    return await _queueDao.getPendingOperationsCount();
  }
}
