import 'dart:math';
import 'package:sqflite_sql_cipher/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import '../models/collaborator.dart';
import '../models/meal_ticket.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  Database? _database;
  final _secureStorage = const FlutterSecureStorage();

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> _getOrCreateDbKey() async {
    const keyName = 'kiosk_db_aes_key';
    String? key = await _secureStorage.read(key: keyName);
    if (key == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _secureStorage.write(key: keyName, value: key);
    }
    return key;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hospital_kiosk_encrypted.db');
    final password = await _getOrCreateDbKey();

    return await openDatabase(
      path,
      password: password,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE collaborators (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            registration TEXT NOT NULL UNIQUE,
            sector TEXT NOT NULL,
            face_embedding TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE meal_tickets (
            id TEXT PRIMARY KEY,
            collaborator_id TEXT NOT NULL,
            collaborator_name TEXT NOT NULL,
            registration TEXT NOT NULL,
            sector TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            security_hash TEXT NOT NULL,
            FOREIGN KEY (collaborator_id) REFERENCES collaborators (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            details TEXT,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertCollaborator(Collaborator c) async {
    final db = await database;
    await db.insert('collaborators', c.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Collaborator>> getAllActiveCollaborators() async {
    final db = await database;
    final res = await db.query('collaborators', where: 'is_active = ?', whereArgs: [1]);
    return res.map((e) => Collaborator.fromMap(e)).toList();
  }

  Future<void> registerTicket(MealTicket ticket) async {
    final db = await database;
    await db.insert('meal_tickets', ticket.toMap());
  }

  Future<bool> hasAlreadyEatenInWindow(String collaboratorId, DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'meal_tickets',
      where: 'collaborator_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [collaboratorId, start.toIso8601String(), end.toIso8601String()],
    );
    return result.isNotEmpty;
  }

  Future<List<MealTicket>> getTicketsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final res = await db.query(
      'meal_tickets',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'timestamp DESC',
    );
    return res.map((e) => MealTicket.fromMap(e)).toList();
  }

  Future<Map<String, int>> getSectorCountsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT sector, COUNT(*) as count 
      FROM meal_tickets 
      WHERE timestamp >= ? AND timestamp <= ?
      GROUP BY sector
      ORDER BY count DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, int> sectorMap = {};
    for (var row in res) {
      sectorMap[row['sector'] as String] = row['count'] as int;
    }
    return sectorMap;
  }
}
