import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Cache local SQLite usada por el trabajo de campo.
/// Guarda JSON de rutas, solicitudes y catalogos para poder continuar
/// consultando la informacion descargada cuando el dispositivo pierde red.
class LocalCacheDatabase {
  LocalCacheDatabase._();

  static final LocalCacheDatabase instance = LocalCacheDatabase._();
  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    late final DatabaseFactory factory;
    late final String dbPath;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      dbPath = p.join(dir.path, 'cosaalt_medidores_cache.db');
    } else {
      factory = databaseFactory;
      dbPath = p.join(await getDatabasesPath(), 'cosaalt_medidores_cache.db');
    }

    _db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cache_entries (
              cache_key TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    return _db!;
  }

  Future<void> writeJson(String key, String payload) async {
    final db = await database;
    await db.insert(
      'cache_entries',
      {
        'cache_key': key,
        'payload': payload,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readJson(String key) async {
    final db = await database;
    final rows = await db.query(
      'cache_entries',
      columns: ['payload'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['payload'] as String?;
  }

  Future<DateTime?> updatedAt(String key) async {
    final db = await database;
    final rows = await db.query(
      'cache_entries',
      columns: ['updated_at'],
      where: 'cache_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final value = rows.first['updated_at'] as String?;
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> delete(String key) async {
    final db = await database;
    await db.delete('cache_entries', where: 'cache_key = ?', whereArgs: [key]);
  }
}
