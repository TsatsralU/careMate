// ──────────────────────────────────────────────────────────────
// intake_repository.dart
// Kotlin IntakeRecordRepository.kt → Dart 변환
// 연속 복용 일수 버그 수정 버전 포함
// ──────────────────────────────────────────────────────────────

import 'database_helper.dart';
import 'models.dart';

class IntakeRepository {
  final DatabaseHelper _db = DatabaseHelper();

  static const int intakePerLevel = 15;

  // ── 복용 기록 ──────────────────────────────────────────────

  /// 복용 기록 + 나무 자동 성장
  /// "약 먹었어요" 음성 감지 시 호출
  Future<int> recordIntake({
    int medicationId = 0,
    DetectionMethod detectionMethod = DetectionMethod.voice,
    String? note,
  }) async {
    final record = IntakeRecord(
      medicationId: medicationId,
      takenAt: DateTime.now().millisecondsSinceEpoch,
      isConfirmed: true,
      detectionMethod: detectionMethod,
      note: note,
    );

    final id = await _db.insertIntakeRecord(record);
    await _db.waterTree();
    await _updateConsecutiveDays();

    return id;
  }

  /// 알람만 울림 (미복용)
  Future<int> recordAlarmOnly(int medicationId) async {
    final record = IntakeRecord(
      medicationId: medicationId,
      takenAt: DateTime.now().millisecondsSinceEpoch,
      isConfirmed: false,
      detectionMethod: DetectionMethod.alarm,
      note: '알람만 울림 (미복용)',
    );

    final id = await _db.insertIntakeRecord(record);
    await _db.incrementMissedCount();
    return id;
  }

  // ── 조회 ──────────────────────────────────────────────────

  Future<List<IntakeRecord>> getAllRecords() => _db.getAllRecords();
  Future<List<IntakeRecord>> getTodayRecords() => _db.getTodayRecords();
  Future<int> getTodayIntakeCount() => _db.getTodayIntakeCount();
  Future<int> getTotalIntakeCount() => _db.getTotalIntakeCount();

  // ── 나무 상태 ──────────────────────────────────────────────

  Future<TreeState?> getTreeState() => _db.getTreeState();

  /// 다음 레벨까지 남은 횟수 (Kotlin getIntakesUntilNextLevel() 동일)
  Future<int> getIntakesUntilNextLevel() async {
    final tree = await _db.getTreeState();
    if (tree == null) return intakePerLevel;
    if (tree.growthLevel >= 4) return 0;
    final nextLevelThreshold = tree.growthLevel * intakePerLevel;
    return (nextLevelThreshold - tree.totalIntakes).clamp(0, intakePerLevel);
  }

  /// 현재 레벨 진행률 (0.0 ~ 1.0)
  Future<double> getLevelProgress() async {
    final tree = await _db.getTreeState();
    if (tree == null) return 0.0;
    if (tree.growthLevel >= 4) return 1.0;
    final currentLevelStart = (tree.growthLevel - 1) * intakePerLevel;
    final progress = tree.totalIntakes - currentLevelStart;
    return (progress / intakePerLevel).clamp(0.0, 1.0);
  }

  // ── 연속 복용 일수 (버그 수정 버전) ────────────────────────

  /// 연속 복용 일수 업데이트
  Future<void> _updateConsecutiveDays() async {
    final thirtyDaysAgo =
        DateTime.now().millisecondsSinceEpoch - 30 * 24 * 60 * 60 * 1000;
    final dates = await _db.getRecentIntakeDates(thirtyDaysAgo);
    final consecutive = calculateConsecutiveDays(dates);
    await _db.setConsecutiveDays(consecutive);
  }

  /// 날짜 목록에서 오늘부터 연속된 일수 계산
  /// Kotlin calculateConsecutiveDays() 동일 (버그 수정 버전)
  int calculateConsecutiveDays(List<String> dates) {
    if (dates.isEmpty) return 0;

    final today = _getTodayDateString();
    if (dates.first != today) return 0;

    int consecutive = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final curr = DateTime.parse(dates[i]);
      final next = DateTime.parse(dates[i + 1]);
      final diff = curr.difference(next).inDays;

      if (diff == 1) {
        consecutive++;
      } else {
        break;
      }
    }
    return consecutive;
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
