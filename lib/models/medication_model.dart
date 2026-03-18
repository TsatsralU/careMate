// lib/models/medication_model.dart

enum MedicationType { days, pills }

class MedicationModel {
  final int? id;
  final String name;
  final MedicationType type;
  final int totalDays;
  final int totalPills;
  final int dailyCount;
  final int takenCount;
  final DateTime startDate;

  const MedicationModel({
    this.id,
    required this.name,
    required this.type,
    this.totalDays = 0,
    this.totalPills = 0,
    required this.dailyCount,
    this.takenCount = 0,
    required this.startDate,
  });

  int get totalDoses =>
      type == MedicationType.days ? totalDays * dailyCount : totalPills;

  int get remainingDoses => (totalDoses - takenCount).clamp(0, totalDoses);

  int get remainingDays =>
      dailyCount > 0 ? (remainingDoses / dailyCount).floor() : 0;

  int get remainingPills =>
      type == MedicationType.pills ? remainingDoses : remainingDays * dailyCount;

  double get adherenceRate =>
      totalDoses == 0 ? 0.0 : (takenCount / totalDoses).clamp(0.0, 1.0);

  String get warningLevel {
    if (remainingDays <= 3) return 'critical';
    if (remainingDays <= 7) return 'warning';
    return 'normal';
  }

  String get remainingText {
    if (type == MedicationType.days) return '$remainingDays일치 남음';
    return '$remainingPills알 남음 (약 ${remainingDays}일)';
  }

  String get warningMessage {
    switch (warningLevel) {
      case 'critical':
        return '⚠️ $name 약이 $remainingDays일치 남았어요! 약을 받아오세요.';
      case 'warning':
        return '💊 $name 약이 $remainingDays일치 남았어요.';
      default:
        return '';
    }
  }

  MedicationModel takeMedication() {
    if (remainingDoses <= 0) return this;
    return copyWith(takenCount: takenCount + 1);
  }

  MedicationModel copyWith({
    int? id,
    String? name,
    MedicationType? type,
    int? totalDays,
    int? totalPills,
    int? dailyCount,
    int? takenCount,
    DateTime? startDate,
  }) =>
      MedicationModel(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        totalDays: totalDays ?? this.totalDays,
        totalPills: totalPills ?? this.totalPills,
        dailyCount: dailyCount ?? this.dailyCount,
        takenCount: takenCount ?? this.takenCount,
        startDate: startDate ?? this.startDate,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'type': type.index,
        'total_days': totalDays,
        'total_pills': totalPills,
        'daily_count': dailyCount,
        'taken_count': takenCount,
        'start_date': startDate.toIso8601String(),
      };

  factory MedicationModel.fromMap(Map<String, dynamic> m) => MedicationModel(
        id: m['id'],
        name: m['name'],
        type: MedicationType.values[m['type'] ?? 0],
        totalDays: m['total_days'] ?? 0,
        totalPills: m['total_pills'] ?? 0,
        dailyCount: m['daily_count'] ?? 1,
        takenCount: m['taken_count'] ?? 0,
        startDate: DateTime.parse(m['start_date']),
      );
}
