// lib/db/medication_db.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/medication_model.dart';

class MedicationDB {
  static final MedicationDB _instance = MedicationDB._internal();
  factory MedicationDB() => _instance;
  MedicationDB._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = join(await getDatabasesPath(), 'caremate_meds.db');
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medicines (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            type        INTEGER NOT NULL DEFAULT 0,
            total_days  INTEGER NOT NULL DEFAULT 0,
            total_pills INTEGER NOT NULL DEFAULT 0,
            daily_count INTEGER NOT NULL DEFAULT 1,
            taken_count INTEGER NOT NULL DEFAULT 0,
            start_date  TEXT    NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insert(MedicationModel med) async {
    final db = await database;
    return db.insert('medicines', med.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MedicationModel>> getAll() async {
    final db = await database;
    final rows = await db.query('medicines', orderBy: 'id DESC');
    return rows.map(MedicationModel.fromMap).toList();
  }

  Future<MedicationModel?> getById(int id) async {
    final db = await database;
    final rows =
        await db.query('medicines', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : MedicationModel.fromMap(rows.first);
  }

  Future<MedicationModel?> checkMedication(int id) async {
    final med = await getById(id);
    if (med == null || med.remainingDoses <= 0) return med;
    final updated = med.takeMedication();
    final db = await database;
    await db.update(
      'medicines',
      {'taken_count': updated.takenCount},
      where: 'id = ?',
      whereArgs: [id],
    );
    return updated;
  }

  Future<void> update(MedicationModel med) async {
    final db = await database;
    await db.update('medicines', med.toMap(),
        where: 'id = ?', whereArgs: [med.id]);
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('medicines', where: 'id = ?', whereArgs: [id]);
  }
}
