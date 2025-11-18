import '../../core/models/habit.dart';
import 'api_client.dart';
import 'api_config.dart';

/// Servicio para operaciones remotas de hábitos
///
/// Proporciona métodos para interactuar con la API REST de hábitos
class HabitApiService {
  final ApiClient _apiClient;

  HabitApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Obtiene todos los hábitos desde la API
  Future<List<Habit>> fetchAllHabits() async {
    try {
      final response = await _apiClient.get(ApiConfig.habitsEndpoint);

      if (response is List) {
        return response.map((json) => Habit.fromJson(json)).toList();
      }

      throw ApiException('Formato de respuesta inválido');
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene un hábito específico por ID
  Future<Habit> fetchHabitById(String id) async {
    try {
      final response = await _apiClient.get(ApiConfig.habitByIdEndpoint(id));
      return Habit.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Crea un nuevo hábito en la API
  Future<Habit> createHabit(Habit habit, {String? idempotencyKey}) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.habitsEndpoint,
        habit.toJson(),
        idempotencyKey: idempotencyKey,
      );
      return Habit.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Actualiza un hábito existente
  Future<Habit> updateHabit(Habit habit, {String? idempotencyKey}) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.habitByIdEndpoint(habit.id),
        habit.toJson(),
        idempotencyKey: idempotencyKey,
      );
      return Habit.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Elimina un hábito
  Future<void> deleteHabit(String id) async {
    try {
      await _apiClient.delete(ApiConfig.habitByIdEndpoint(id));
    } catch (e) {
      rethrow;
    }
  }

  /// Cierra el cliente API
  void dispose() {
    _apiClient.close();
  }
}
