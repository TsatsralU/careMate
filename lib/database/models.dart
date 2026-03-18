// ──────────────────────────────────────────────────────────────
// models.dart
// Kotlin IntakeRecord.kt + TreeState 를 Dart로 변환
// ──────────────────────────────────────────────────────────────

/// 복용 감지 방법 (Kotlin DetectionMethod enum 동일)
enum DetectionMethod { beacon, manual, voice, alarm }

/// 복용 기록 (Kotlin IntakeRecord.kt 동일)
class IntakeRecord {
  final int? id;
  final int medicationId;
  final int takenAt;
  final bool isConfirmed;
  final DetectionMethod detectionMethod;
  final String? note;

  IntakeRecord({
    this.id,
    required this.medicationId,
    required this.takenAt,
    required this.isConfirmed,
    required this.detectionMethod,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicationId': medicationId,
        'takenAt': takenAt,
        'isConfirmed': isConfirmed ? 1 : 0,
        'detectionMethod': detectionMethod.name,
        'note': note,
      };

  factory IntakeRecord.fromMap(Map<String, dynamic> map) => IntakeRecord(
        id: map['id'],
        medicationId: map['medicationId'],
        takenAt: map['takenAt'],
        isConfirmed: map['isConfirmed'] == 1,
        detectionMethod: DetectionMethod.values
            .firstWhere((e) => e.name == map['detectionMethod']),
        note: map['note'],
      );
}

/// 나무 상태 (Kotlin TreeState.kt 동일)
class TreeState {
  final int id;
  final int growthLevel;
  final int totalIntakes;
  final int lastWateredAt;
  final int consecutiveDays;
  final int missedCount;
  final int healthPoints;
  final String achievements;

  TreeState({
    this.id = 1,
    this.growthLevel = 1,
    this.totalIntakes = 0,
    this.lastWateredAt = 0,
    this.consecutiveDays = 0,
    this.missedCount = 0,
    this.healthPoints = 100,
    this.achievements = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'growthLevel': growthLevel,
        'totalIntakes': totalIntakes,
        'lastWateredAt': lastWateredAt,
        'consecutiveDays': consecutiveDays,
        'missedCount': missedCount,
        'healthPoints': healthPoints,
        'achievements': achievements,
      };

  factory TreeState.fromMap(Map<String, dynamic> map) => TreeState(
        id: map['id'],
        growthLevel: map['growthLevel'],
        totalIntakes: map['totalIntakes'],
        lastWateredAt: map['lastWateredAt'],
        consecutiveDays: map['consecutiveDays'],
        missedCount: map['missedCount'],
        healthPoints: map['healthPoints'],
        achievements: map['achievements'],
      );

  TreeState copyWith({
    int? growthLevel,
    int? totalIntakes,
    int? lastWateredAt,
    int? consecutiveDays,
    int? missedCount,
    int? healthPoints,
    String? achievements,
  }) =>
      TreeState(
        id: id,
        growthLevel: growthLevel ?? this.growthLevel,
        totalIntakes: totalIntakes ?? this.totalIntakes,
        lastWateredAt: lastWateredAt ?? this.lastWateredAt,
        consecutiveDays: consecutiveDays ?? this.consecutiveDays,
        missedCount: missedCount ?? this.missedCount,
        healthPoints: healthPoints ?? this.healthPoints,
        achievements: achievements ?? this.achievements,
      );
}
