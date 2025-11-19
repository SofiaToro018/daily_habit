import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Helper para gestionar la base de datos SQLite
///
/// Singleton que maneja la inicialización y actualización
/// de la base de datos local de la aplicación.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Obtiene la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('habits.db');
    return _database!;
  }

  /// Inicializa la base de datos
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Crea las tablas iniciales
  Future<void> _createDB(Database db, int version) async {
    // Tabla de hábitos
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0,
        last_completed_at TEXT,
        streak INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Tabla de cola de operaciones para sincronización
    await db.execute('''
      CREATE TABLE queue_operations (
        id TEXT PRIMARY KEY,
        entity TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        op TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Índices para mejorar rendimiento
    await db.execute('''
      CREATE INDEX idx_habits_deleted ON habits(deleted)
    ''');

    await db.execute('''
      CREATE INDEX idx_habits_completed ON habits(completed)
    ''');

    await db.execute('''
      CREATE INDEX idx_queue_created_at ON queue_operations(created_at)
    ''');
  }

  /// Maneja actualizaciones de versión de la base de datos
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Implementar migraciones aquí cuando sea necesario
    if (oldVersion < 2) {
      // Ejemplo de migración futura
      // await db.execute('ALTER TABLE habits ADD COLUMN new_field TEXT');
    }
  }

  /// Cierra la base de datos
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }

  /// Elimina la base de datos (útil para testing)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'habits.db');
    await deleteDatabase(path);
    _database = null;
  }
}
