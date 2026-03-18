// lib/widgets/beacon_status_widget.dart

import 'package:flutter/material.dart';
import '../services/beacon_service.dart';

class BeaconStatusWidget extends StatefulWidget {
  final VoidCallback? onMedicationTaken;
  const BeaconStatusWidget({Key? key, this.onMedicationTaken}) : super(key: key);

  @override
  State<BeaconStatusWidget> createState() => _BeaconStatusWidgetState();
}

class _BeaconStatusWidgetState extends State<BeaconStatusWidget>
    with SingleTickerProviderStateMixin {
  final _beacon = BeaconService();
  late AnimationController _pulse;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.92, end: 1.08).animate(_pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: _beacon.statusNotifier,
      builder: (_, status, __) => ValueListenableBuilder<int>(
        valueListenable: _beacon.rssiNotifier,
        builder: (_, rssi, __) => _buildCard(status, rssi),
      ),
    );
  }

  Widget _buildCard(String status, int rssi) {
    final cfg = _config(status);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cfg.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: cfg.color.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          status == 'immediate'
              ? ScaleTransition(
                  scale: _anim,
                  child: Icon(cfg.icon, size: 52, color: Colors.white))
              : Icon(cfg.icon, size: 52, color: Colors.white),
          const SizedBox(height: 10),
          Text(cfg.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(cfg.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85), fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12)),
            child: Text('RSSI: $rssi dBm',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          if (status == 'immediate') ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: widget.onMedicationTaken,
              icon: const Icon(Icons.check_circle, size: 22),
              label: const Text('약 먹었어요!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: cfg.color,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _StatusConfig _config(String status) {
    switch (status) {
      case 'immediate':
        return _StatusConfig(
          color: const Color(0xFF4CAF50),
          icon: Icons.medication,
          title: '약통 근처예요!',
          subtitle: '약을 드실 시간이에요.\n아래 버튼을 눌러 복약을 확인해요.',
        );
      case 'near':
        return _StatusConfig(
          color: const Color(0xFFFFA726),
          icon: Icons.bluetooth_searching,
          title: '약통에 가까워지고 있어요',
          subtitle: '조금 더 가까이 가보세요.',
        );
      default:
        return _StatusConfig(
          color: const Color(0xFF90A4AE),
          icon: Icons.bluetooth,
          title: '약통을 찾고 있어요',
          subtitle: '약통이 있는 곳으로 이동해보세요.',
        );
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
