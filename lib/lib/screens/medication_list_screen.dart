// lib/screens/medication_list_screen.dart
// 기존 HistoryScreen을 대체하는 복약 기록 탭

import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../db/medication_db.dart';
import '../services/beacon_service.dart';
import '../widgets/beacon_status_widget.dart';
import '../widgets/medication_card.dart';
import 'medication_register_screen.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({Key? key}) : super(key: key);

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final _db     = MedicationDB();
  final _beacon = BeaconService();
  List<MedicationModel> _meds = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeds();
    _beacon.startScanning();

    // 비콘 감지 시 스낵바
    _beacon.onBeaconDetected = () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('💊 약통 근처예요! 약 드셨나요?',
              style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    };
  }

  @override
  void dispose() {
    _beacon.stopScanning();
    super.dispose();
  }

  Future<void> _loadMeds() async {
    setState(() => _loading = true);
    final meds = await _db.getAll();
    setState(() {
      _meds = meds;
      _loading = false;
    });
  }

  Future<void> _checkMed(MedicationModel med) async {
    if (med.remainingDoses <= 0) {
      _showToast('${med.name} 약이 모두 소진됐어요!');
      return;
    }
    final updated = await _db.checkMedication(med.id!);
    if (updated == null) return;
    await _loadMeds();

    if (updated.warningLevel != 'normal') {
      _showWarningDialog(updated);
    } else {
      _showToast('✅ 복약 완료! 화분이 자랐어요 🌱');
    }
  }

  void _showWarningDialog(MedicationModel med) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          med.warningLevel == 'critical' ? '⚠️ 약이 얼마 안 남았어요!' : '💊 약 잔량 알림',
          style: const TextStyle(fontSize: 20),
        ),
        content: Text(med.warningMessage,
            style: const TextStyle(fontSize: 17)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: const TextStyle(fontSize: 15))));
  }

  Future<void> _deleteMed(MedicationModel med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('약 삭제', style: TextStyle(fontSize: 20)),
        content: Text('${med.name}을(를) 삭제할까요?',
            style: const TextStyle(fontSize: 17)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(fontSize: 16))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(fontSize: 16, color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await _db.delete(med.id!);
      await _loadMeds();
    }
  }

  Future<void> _goRegister([MedicationModel? existing]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => MedicationRegisterScreen(existing: existing)),
    );
    if (result == true) await _loadMeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text('복약 기록',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _loadMeds,
              color: Colors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 비콘 상태 카드
                    BeaconStatusWidget(
                      onMedicationTaken: _meds.isNotEmpty
                          ? () => _checkMed(_meds.first)
                          : null,
                    ),

                    // 잔량 경고 배너
                    ..._meds
                        .where((m) => m.warningLevel != 'normal')
                        .map((m) => Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: m.warningLevel == 'critical'
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: m.warningLevel == 'critical'
                                      ? Colors.red.shade300
                                      : Colors.orange.shade300,
                                ),
                              ),
                              child: Text(m.warningMessage,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: m.warningLevel == 'critical'
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.w600)),
                            )),

                    // 약 목록
                    if (_meds.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(children: [
                          Icon(Icons.medication_outlined,
                              size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('등록된 약이 없어요',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade500)),
                          const SizedBox(height: 8),
                          Text('아래 버튼을 눌러 약을 등록해보세요',
                              style: TextStyle(
                                  fontSize: 15, color: Colors.grey.shade400)),
                        ]),
                      )
                    else
                      ..._meds.map((m) => MedicationCard(
                            med: m,
                            onCheck: () => _checkMed(m),
                            onEdit: () => _goRegister(m),
                            onDelete: () => _deleteMed(m),
                          )),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goRegister(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('약 등록',
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
