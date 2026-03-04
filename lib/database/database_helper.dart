// ──────────────────────────────────────────────────────────────
// database_helper.dart
// Kotlin Room DB → sqflite 변환
// IntakeRecordDao.kt + TreeStateDao.kt 통합
// ──────────────────────────────────────────────────────────────

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caremate.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // intake_records 테이블 (Kotlin IntakeRecord.kt 동일)
    await db.execute('''
      CREATE TABLE intake_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicationId INTEGER NOT NULL,
        takenAt INTEGER NOT NULL,
        isConfirmed INTEGER NOT NULL DEFAULT 0,
        detectionMethod TEXT NOT NULL,
        note TEXT
      )
    ''');

    // tree_state 테이블 (Kotlin TreeState.kt 동일)
    await db.execute('''
      CREATE TABLE tree_state (
        id INTEGER PRIMARY KEY DEFAULT 1,
        growthLevel INTEGER NOT NULL DEFAULT 1,
        totalIntakes INTEGER NOT NULL DEFAULT 0,
        lastWateredAt INTEGER NOT NULL DEFAULT 0,
        consecutiveDays INTEGER NOT NULL DEFAULT 0,
        missedCount INTEGER NOT NULL DEFAULT 0,
        healthPoints INTEGER NOT NULL DEFAULT 100,
        achievements TEXT NOT NULL DEFAULT ''
      )
    ''');

    // 나무 초기 데이터 삽입
    await db.insert('tree_state', TreeState().toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ── IntakeRecord DAO ──────────────────────────────────────

  /// 복용 기록 삽입
  Future<int> insertIntakeRecord(IntakeRecord record) async {
    final db = await database;
    return db.insert('intake_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 전체 복용 기록 조회 (최신순)
  Future<List<IntakeRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('intake_records', orderBy: 'takenAt DESC');
    return maps.map((m) => IntakeRecord.fromMap(m)).toList();
  }

  /// 오늘 복용 기록 조회
  Future<List<IntakeRecord>> getTodayRecords() async {
    final db = await database;
    final todayStart = _getTodayStartTime();
    final maps = await db.query(
      'intake_records',
      where: 'takenAt >= ?',
      whereArgs: [todayStart],
      orderBy: 'takenAt DESC',
    );
    return maps.map((m) => IntakeRecord.fromMap(m)).toList();
  }

  /// 오늘 복용 횟수
  Future<int> getTodayIntakeCount() async {
    final db = await database;
    final todayStart = _getTodayStartTime();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM intake_records WHERE isConfirmed = 1 AND takenAt >= ?',
      [todayStart],
    );
    return result.first['count'] as int;
  }

  /// 전체 복용 횟수
  Future<int> getTotalIntakeCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM intake_records WHERE isConfirmed = 1',
    );
    return result.first['count'] as int;
  }

  /// 최근 복용 날짜 목록 (연속일수 계산용)
  Future<List<String>> getRecentIntakeDates(int startTime) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(takenAt / 1000, 'unixepoch') AS date
      FROM intake_records
      WHERE isConfirmed = 1 AND takenAt >= ?
      ORDER BY date DESC
    ''', [startTime]);
    return result.map((r) => r['date'] as String).toList();
  }

  // ── TreeState DAO ─────────────────────────────────────────

  /// 나무 상태 조회
  Future<TreeState?> getTreeState() async {
    final db = await database;
    final maps = await db.query('tree_state', where: 'id = 1');
    if (maps.isEmpty) return null;
    return TreeState.fromMap(maps.first);
  }

  /// 복용 시 나무 성장 (Kotlin waterTree() 동일)
  Future<void> waterTree() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawUpdate('''
      UPDATE tree_state 
      SET 
        totalIntakes  = totalIntakes + 1,
        growthLevel   = MIN(4, (totalIntakes + 1) / 15 + 1),
        lastWateredAt = ?,
        healthPoints  = MIN(100, healthPoints + 1)
      WHERE id = 1
    ''', [now]);
  }

  /// 연속 복용 일수 절대값 저장 (Kotlin setConsecutiveDays() 동일)
  Future<void> setConsecutiveDays(int days) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE tree_state SET consecutiveDays = ? WHERE id = 1',
      [days],
    );
  }

  /// 놓친 횟수 증가 + 건강도 -5 (Kotlin incrementMissedCount() 동일)
  Future<void> incrementMissedCount() async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE tree_state 
      SET 
        missedCount  = missedCount + 1,
        healthPoints = MAX(0, healthPoints - 5)
      WHERE id = 1
    ''');
  }

  // ── 유틸 ─────────────────────────────────────────────────

  int _getTodayStartTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .millisecondsSinceEpoch;
  }
}
