import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/habit.dart';
import '../data/repositories/habit_repository.dart';
import '../services/sync_service.dart';

/// Provider del repositorio de hábitos
final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return HabitRepository();
});

/// Provider del servicio de sincronización
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  service.startMonitoring();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider para la lista de todos los hábitos
final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  return await repository.getAllHabits();
});

/// Provider para hábitos filtrados por estado
final habitsByStatusProvider = FutureProvider.family<List<Habit>, bool>((
  ref,
  completed,
) async {
  final repository = ref.watch(habitRepositoryProvider);
  return await repository.getHabitsByStatus(completed: completed);
});

/// Provider para hábitos pendientes
final pendingHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  return await repository.getHabitsByStatus(completed: false);
});

/// Provider para hábitos completados
final completedHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  return await repository.getHabitsByStatus(completed: true);
});

/// Provider para hábitos con racha activa
final streakHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  return await repository.getHabitsWithStreak();
});

/// Provider para el conteo de operaciones pendientes
final pendingOperationsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(habitRepositoryProvider);
  return await repository.getPendingOperationsCount();
});

/// StateNotifier para gestionar el filtro activo
enum HabitFilter { all, pending, completed, streak }

class HabitFilterNotifier extends StateNotifier<HabitFilter> {
  HabitFilterNotifier() : super(HabitFilter.all);

  void setFilter(HabitFilter filter) {
    state = filter;
  }
}

final habitFilterProvider =
    StateNotifierProvider<HabitFilterNotifier, HabitFilter>(
      (ref) => HabitFilterNotifier(),
    );

/// Provider para hábitos filtrados según el filtro activo
final filteredHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final filter = ref.watch(habitFilterProvider);
  final repository = ref.watch(habitRepositoryProvider);

  switch (filter) {
    case HabitFilter.all:
      return await repository.getAllHabits();
    case HabitFilter.pending:
      return await repository.getHabitsByStatus(completed: false);
    case HabitFilter.completed:
      return await repository.getHabitsByStatus(completed: true);
    case HabitFilter.streak:
      return await repository.getHabitsWithStreak();
  }
});

/// StateNotifier para controlar el estado de sincronización
class SyncState {
  final bool isSyncing;
  final String? message;
  final bool hasError;

  SyncState({this.isSyncing = false, this.message, this.hasError = false});

  SyncState copyWith({bool? isSyncing, String? message, bool? hasError}) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      message: message ?? this.message,
      hasError: hasError ?? this.hasError,
    );
  }
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncStateNotifier(this._syncService) : super(SyncState());

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true, message: 'Sincronizando...');

    try {
      final result = await _syncService.forceSyncNow();
      state = state.copyWith(
        isSyncing: false,
        message: result.message,
        hasError: !result.success,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        message: 'Error al sincronizar: $e',
        hasError: true,
      );
    }
  }

  void clearMessage() {
    state = state.copyWith(message: null, hasError: false);
  }
}

final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((
  ref,
) {
  final syncService = ref.watch(syncServiceProvider);
  return SyncStateNotifier(syncService);
});
