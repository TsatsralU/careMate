// lib/widgets/medication_card.dart

import 'package:flutter/material.dart';
import '../models/medication_model.dart';

class MedicationCard extends StatelessWidget {
  final MedicationModel med;
  final VoidCallback onCheck;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationCard({
    Key? key,
    required this.med,
    required this.onCheck,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _warningColor(med.warningLevel).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication,
                      color: _warningColor(med.warningLevel), size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.bold)),
                      Text('하루 ${med.dailyCount}회',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('삭제',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 1.0 - med.adherenceRate,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          _warningColor(med.warningLevel)),
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  med.remainingText,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _warningColor(med.warningLevel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '복약률 ${(med.adherenceRate * 100).toStringAsFixed(0)}%  •  ${med.takenCount}/${med.totalDoses}회 복용',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: med.remainingDoses > 0 ? onCheck : null,
                icon: const Icon(Icons.check, size: 20),
                label: Text(
                  med.remainingDoses > 0 ? '복약 확인' : '모두 복용 완료',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: med.remainingDoses > 0
                      ? _warningColor(med.warningLevel)
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _warningColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red.shade500;
      case 'warning':
        return Colors.orange.shade500;
      default:
        return const Color(0xFF4CAF50);
    }
  }
}
