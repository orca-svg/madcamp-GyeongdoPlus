import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

const String _appServiceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";

class DetectedPlayer {
  final String partialId; // Used to match with GameProvider
  final double rssi;
  final double distance;
  final DateTime timestamp;

  DetectedPlayer({
    required this.partialId,
    required this.rssi,
    required this.distance,
    required this.timestamp,
  });
}

class InteractionService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  final _detectedController =
      StreamController<List<DetectedPlayer>>.broadcast();

  bool _isAdvertising = false;
  bool _isScanning = false;

  // Cache detected players
  final Map<String, DetectedPlayer> _nearbyPlayers = {};
  Timer? _cleanupTimer;

  Stream<List<DetectedPlayer>> get nearbyPlayers => _detectedController.stream;

  Future<void> init() async {
    // Request initial permissions used for both scan/advertise
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();
    } else if (Platform.isIOS) {
      await [Permission.bluetooth].request();
    }
  }

  Future<void> start(String userId) async {
    await stop(); // Ensure clean state
    await _requestPermissions();

    // 1. Start Advertising
    await _startAdvertising(userId);

    // 2. Start Scanning
    await _startScanning();

    // 3. Start Cleanup Timer (remove old devices)
    _cleanupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      _nearbyPlayers.removeWhere(
        (key, value) => now.difference(value.timestamp).inSeconds > 5,
      );
      _detectedController.add(_nearbyPlayers.values.toList());
    });
  }

  Future<void> stop() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    if (_isAdvertising) {
      await _peripheral.stop();
      _isAdvertising = false;
    }

    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
    }

    _nearbyPlayers.clear();
    _detectedController.add([]);
  }

  Future<void> _startAdvertising(String userId) async {
    if (!await _peripheral.isSupported) {
      debugPrint('[BLE] Peripheral not supported');
      return;
    }

    // Embed partial UserID in LocalName or ManufacturerData
    // iOS doesn't always show ManufacturerData in background scan result from Android
    // But Android->Android works.
    // iOS->iOS works via ServiceUUID.
    // We will use LocalName = "GP_<ShortID>" for simplicity if length allows,
    // or Manufacturer Data.
    // UserID is 20 chars? "GP_" + 8 chars = 11 chars. logic ok.

    final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;
    final localName = "GP_$shortId";

    final AdvertiseData data = AdvertiseData(
      serviceUuid: _appServiceUuid,
      localName: localName,
      includeDeviceName: false,
    );

    try {
      await _peripheral.start(advertiseData: data);
      _isAdvertising = true;
      debugPrint('[BLE] Started Advertising: $localName');
    } catch (e) {
      debugPrint('[BLE] Advertise Error: $e');
    }
  }

  Future<void> _startScanning() async {
    // Start scanning for devices with our Service UUID (if possible to filter)
    // FlutterBluePlus supports filtering by service UUIDs.

    try {
      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          _processScanResult(r);
        }
        // Emit updates
        _detectedController.add(_nearbyPlayers.values.toList());
      });

      await FlutterBluePlus.startScan(
        withServices: [Guid(_appServiceUuid)], // Filter by our service
        timeout: null, // continuous
        androidUsesFineLocation: true,
      );
      _isScanning = true;
      debugPrint('[BLE] Started Scanning');
    } catch (e) {
      debugPrint('[BLE] Scan Error: $e');
    }
  }

  void _processScanResult(ScanResult r) {
    final adv = r.advertisementData;
    String? foundShortId;

    // 1. Try Local Name "GP_..."
    if (adv.localName.startsWith("GP_")) {
      foundShortId = adv.localName.substring(3);
    }
    // 2. Try Manufacturer Data logic (if we implemented it) - optional fallback

    if (foundShortId != null) {
      final rssi = r.rssi;
      final dist = _calculateDistance(rssi);

      _nearbyPlayers[foundShortId] = DetectedPlayer(
        partialId: foundShortId,
        rssi: rssi.toDouble(),
        distance: dist,
        timestamp: DateTime.now(),
      );
    }
  }

  double _calculateDistance(int rssi) {
    // Simple Log-distance path loss model
    // d = 10 ^ ((TxPower - RSSI) / (10 * n))
    // TxPower is roughly -59 (1m RSSI). n = 2.0 (free space) to 4.0 (indoor).
    // Let's use n = 2.5 for hallway/indoor hybrid.
    const txPower = -59;
    const n = 2.5;

    if (rssi == 0) return -1.0;

    final ratio = (txPower - rssi) / (10 * n);
    return pow(10, ratio).toDouble();
  }
}

final interactionServiceProvider = Provider<InteractionService>((ref) {
  return InteractionService();
});
