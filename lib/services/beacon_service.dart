// lib/services/beacon_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// ──────────────────────────────────────────────────────────
// ★ 비콘 도착 후 이 UUID 1줄만 교체!
//   nRF Connect 앱 → 비콘 스캔 → UUID 확인 → 아래 붙여넣기
// ──────────────────────────────────────────────────────────
const String kTargetUUID = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';

const int kRssiImmediate   = -65;
const int kRssiNear        = -80;
const int kCooldownMinutes = 5;

class BeaconService {
  static final BeaconService _instance = BeaconService._internal();
  factory BeaconService() => _instance;
  BeaconService._internal();

  final _notifications = FlutterLocalNotificationsPlugin();

  bool _scanning = false;
  bool _notified = false;
  StreamSubscription? _scanSub;
  Timer? _cooldownTimer;

  final statusNotifier = ValueNotifier<String>('far');
  final rssiNotifier   = ValueNotifier<int>(-100);

  VoidCallback? onBeaconDetected;

  Future<void> initialize() async {
    // 웹에서는 BLE/알림 미지원 → 스킵
    if (kIsWeb) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifications.initialize(
        const InitializationSettings(android: android));
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.notification,
    ].request();
  }

  Future<void> startScanning() async {
    // 웹에서는 BLE 미지원 → 스킵
    if (kIsWeb) return;
    if (_scanning) return;
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) return;

    _scanning = true;
    await FlutterBluePlus.startScan(continuousUpdates: true);
    _scanSub = FlutterBluePlus.scanResults.listen(_onResults);
  }

  Future<void> stopScanning() async {
    if (kIsWeb) return;
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _scanning = false;
  }

  void _onResults(List<ScanResult> results) {
    for (final r in results) {
      if (!_isTarget(r)) continue;

      rssiNotifier.value = r.rssi;

      final status = r.rssi >= kRssiImmediate
          ? 'immediate'
          : r.rssi >= kRssiNear
              ? 'near'
              : 'far';

      if (status != statusNotifier.value) statusNotifier.value = status;
      if (status == 'immediate' && !_notified) _triggerAlert();
    }
  }

  bool _isTarget(ScanResult r) {
    final found = r.advertisementData.serviceUuids
        .any((u) => u.toString().toUpperCase() == kTargetUUID.toUpperCase());
    if (found) return true;

    final apple = r.advertisementData.manufacturerData[0x004C];
    if (apple != null && apple.length >= 18 &&
        apple[0] == 0x02 && apple[1] == 0x15) {
      final hex = apple
          .sublist(2, 18)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final uuid =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
      if (uuid.toUpperCase() == kTargetUUID.toUpperCase()) return true;
    }
    return false;
  }

  Future<void> _triggerAlert() async {
    if (kIsWeb) return;
    _notified = true;
    onBeaconDetected?.call();

    await _notifications.show(
      0,
      '💊 약 드실 시간이에요!',
      '약통 근처에 계시네요. 오늘 약 드셨나요?',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_ch', '복약 알림',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
      ),
    );

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(Duration(minutes: kCooldownMinutes), () {
      _notified = false;
    });
  }

  void dispose() {
    stopScanning();
    _cooldownTimer?.cancel();
    statusNotifier.dispose();
    rssiNotifier.dispose();
  }
}