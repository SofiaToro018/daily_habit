import 'package:sqflite/sqflite.dart';
import '../../core/models/habit.dart';
import 'database_helper.dart';

/// Data Access Object para hábitos
///
/// Gestiona todas las operaciones CRUD de hábitos en SQLite
class HabitDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Obtiene todos los hábitos no eliminados
  Future<List<Habit>> getAllHabits() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'habits',
      where: 'deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  /// Obtiene hábitos filtrados por estado de completado
  Future<List<Habit>> getHabitsByStatus({required bool completed}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'habits',
      where: 'deleted = ? AND completed = ?',
      whereArgs: [0, completed ? 1 : 0],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  /// Obtiene un hábito por ID
  Future<Habit?> getHabitById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'habits',
      where: 'id = ? AND deleted = ?',
      whereArgs: [id, 0],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  /// Inserta un nuevo hábito
  Future<void> insertHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Actualiza un hábito existente
  Future<void> updateHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  /// Marca un hábito como eliminado (soft delete)
  Future<void> deleteHabit(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'habits',
      {'deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Elimina permanentemente un hábito
  Future<void> hardDeleteHabit(String id) async {
    final db = await _dbHelper.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  /// Elimina todos los hábitos (útil para limpieza)
  Future<void> deleteAllHabits() async {
    final db = await _dbHelper.database;
    await db.delete('habits');
  }

  /// Actualiza el estado de completado de un hábito
  Future<void> toggleHabitCompletion(String id) async {
    final db = await _dbHelper.database;
    final habit = await getHabitById(id);

    if (habit == null) return;

    final now = DateTime.now();
    int newStreak = habit.streak;

    // Calcular racha
    if (!habit.completed) {
      // Marcar como completado
      if (habit.lastCompletedAt != null) {
        final daysDifference = now.difference(habit.lastCompletedAt!).inDays;
        if (daysDifference == 1) {
          // Continuar racha
          newStreak = habit.streak + 1;
        } else {
          // Reiniciar racha
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
    } else {
      // Desmarcar - resetear racha
      newStreak = 0;
    }

    await db.update(
      'habits',
      {
        'completed': habit.completed ? 0 : 1,
        'updated_at': now.toIso8601String(),
        'last_completed_at': !habit.completed ? now.toIso8601String() : null,
        'streak': newStreak,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene hábitos con racha activa
  Future<List<Habit>> getHabitsWithStreak() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'habits',
      where: 'deleted = ? AND streak > ?',
      whereArgs: [0, 0],
      orderBy: 'streak DESC',
    );
    return maps.map((map) => Habit.fromMap(map)).toList();
  }
}
