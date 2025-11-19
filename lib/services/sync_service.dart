import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/models/queue_operation.dart';
import '../core/models/habit.dart';
import '../data/local/queue_dao.dart';
import '../data/remote/habit_api_service.dart';

/// Resultado de una operación de sincronización
class SyncResult {
  final bool success;
  final String message;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.message,
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
  });

  @override
  String toString() {
    return 'SyncResult(success: $success, '
        'successCount: $successCount, '
        'failureCount: $failureCount, '
        'message: $message)';
  }
}

/// Servicio de sincronización con backoff exponencial
///
/// Gestiona la sincronización de operaciones pendientes
/// cuando se recupera la conectividad.
class SyncService {
  final QueueDao _queueDao;
  final HabitApiService _apiService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  // Configuración de reintentos
  static const int maxAttempts = 5;
  static const int baseDelayMs = 1000; // 1 segundo

  SyncService({
    QueueDao? queueDao,
    HabitApiService? apiService,
    Connectivity? connectivity,
  }) : _queueDao = queueDao ?? QueueDao(),
       _apiService = apiService ?? HabitApiService(),
       _connectivity = connectivity ?? Connectivity();

  /// Inicia el monitoreo de conectividad
  void startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (_hasConnection(results) && !_isSyncing) {
        syncPendingOperations();
      }
    });
  }

  /// Detiene el monitoreo de conectividad
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Verifica si hay conexión en los resultados
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
  }

  /// Sincroniza todas las operaciones pendientes
  Future<SyncResult> syncPendingOperations() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sincronización ya en progreso',
      );
    }

    _isSyncing = true;
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    try {
      // Verificar conectividad
      final connectivityResult = await _connectivity.checkConnectivity();
      if (!_hasConnection(connectivityResult)) {
        return SyncResult(success: false, message: 'Sin conexión a Internet');
      }

      // Obtener operaciones pendientes
      final operations = await _queueDao.getPendingOperations();

      if (operations.isEmpty) {
        return SyncResult(
          success: true,
          message: 'No hay operaciones pendientes',
          successCount: 0,
        );
      }

      // Procesar cada operación
      for (final operation in operations) {
        try {
          await _syncOperation(operation);
          await _queueDao.deleteOperation(operation.id);
          successCount++;
        } catch (e) {
          failureCount++;
          final error = e.toString();
          errors.add('${operation.id}: $error');

          // Incrementar contador de intentos
          await _queueDao.incrementAttemptCount(operation.id, error);

          // Si excede el máximo de intentos, eliminar
          if (operation.attemptCount + 1 >= maxAttempts) {
            await _queueDao.deleteOperation(operation.id);
            // ignore: avoid_print
            print(
              'Operación ${operation.id} eliminada tras $maxAttempts intentos',
            );
          }
        }

        // Backoff entre operaciones para no saturar
        if (operations.indexOf(operation) < operations.length - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      return SyncResult(
        success: failureCount == 0,
        message: failureCount == 0
            ? 'Sincronización completada exitosamente'
            : 'Sincronización completada con errores',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Sincroniza una operación individual con backoff exponencial
  Future<void> _syncOperation(QueueOperation operation) async {
    int attempt = operation.attemptCount;

    while (attempt < maxAttempts) {
      try {
        await _executeOperation(operation);
        return; // Éxito
      } catch (e) {
        attempt++;

        if (attempt >= maxAttempts) {
          rethrow; // Lanzar error en el último intento
        }

        // Calcular delay con backoff exponencial
        final delayMs = baseDelayMs * (1 << attempt); // 2^attempt
        final maxDelay = 30000; // 30 segundos máximo
        final actualDelay = delayMs > maxDelay ? maxDelay : delayMs;

        // ignore: avoid_print
        print(
          'Intento $attempt fallido para ${operation.id}, '
          'reintentando en ${actualDelay}ms...',
        );

        await Future.delayed(Duration(milliseconds: actualDelay));
      }
    }
  }

  /// Ejecuta una operación específica
  Future<void> _executeOperation(QueueOperation operation) async {
    final payload = json.decode(operation.payload) as Map<String, dynamic>;

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

  /// Fuerza una sincronización inmediata
  Future<SyncResult> forceSyncNow() async {
    return await syncPendingOperations();
  }

  /// Limpia operaciones fallidas antiguas
  Future<void> cleanupFailedOperations() async {
    await _queueDao.deleteFailedOperations(maxAttempts: maxAttempts);
  }

  /// Libera recursos
  void dispose() {
    stopMonitoring();
    _apiService.dispose();
  }
}
