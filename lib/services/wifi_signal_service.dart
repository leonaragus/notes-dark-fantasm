import 'dart:async';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter/services.dart';

class WifiSignalService {
  static final WifiSignalService _instance = WifiSignalService._internal();
  factory WifiSignalService() => _instance;
  WifiSignalService._internal();

  StreamController<int> _rssiController = StreamController<int>.broadcast();
  Stream<int> get rssiStream => _rssiController.stream;
  
  int _currentRSSI = -100;
  int get currentRSSI => _currentRSSI;
  
  String _currentSSID = "Unknown";
  String get currentSSID => _currentSSID;

  Timer? _scanTimer;

  Future<void> startScanning() async {
    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan != CanStartScan.yes) return;

    _scanTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();
      
      if (results.isNotEmpty) {
        // En una app real, filtraríamos por el SSID al que estamos conectados.
        // Aquí tomamos la señal más fuerte para simular.
        results.sort((a, b) => b.level.compareTo(a.level));
        _currentRSSI = results.first.level;
        _currentSSID = results.first.ssid;
        _rssiController.add(_currentRSSI);
      }
    });
  }

  void stopScanning() {
    _scanTimer?.cancel();
  }

  // Calcula proximidad de 0.0 a 1.0 basándose en la diferencia de RSSI
  double calculateProximity(int targetRSSI) {
    if (_currentRSSI == -100) return 0.0;
    
    int diff = (_currentRSSI - targetRSSI).abs();
    if (diff > 20) return 0.1; // Muy lejos
    if (diff == 0) return 1.0; // Coincidencia exacta
    
    return (1.0 - (diff / 20.0)).clamp(0.1, 1.0);
  }

  void triggerHapticAlert() {
    HapticFeedback.vibrate();
  }
}
