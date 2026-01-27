import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

class BleProximityService {
  final String _myUserId;
  final List<String> _gameParticipantIds;

  // State
  bool _isAdvertising = false;
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // RSSI data stream
  final StreamController<Map<String, int>> _rssiController =
      StreamController<Map<String, int>>.broadcast();

  // Current RSSI snapshot: userId -> RSSI value
  final Map<String, int> _currentRssi = {};

  // UUID mapping: UUID -> userId
  final Map<String, String> _uuidToUserId = {};

  BleProximityService({
    required String myUserId,
    required List<String> gameParticipantIds,
  })  : _myUserId = myUserId,
        _gameParticipantIds = gameParticipantIds {
    // Pre-compute UUID mappings for all participants
    for (final userId in gameParticipantIds) {
      final uuid = _userIdToUuid(userId);
      _uuidToUserId[uuid] = userId;
    }
  }

  /// Generate deterministic UUID from userId
  /// Uses SHA-256 hash of userId to create consistent UUIDs
  String _userIdToUuid(String userId) {
    // Create hash of userId
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);
    final hexString = digest.toString();

    // Format as UUID (8-4-4-4-12)
    final uuid = '${hexString.substring(0, 8)}-'
        '${hexString.substring(8, 12)}-'
        '${hexString.substring(12, 16)}-'
        '${hexString.substring(16, 20)}-'
        '${hexString.substring(20, 32)}';

    return uuid.toUpperCase();
  }

  /// Check if Bluetooth permissions are granted
  Future<bool> checkPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android 12+ requires new granular permissions
      final scanStatus = await Permission.bluetoothScan.status;
      final advertiseStatus = await Permission.bluetoothAdvertise.status;
      final connectStatus = await Permission.bluetoothConnect.status;

      return scanStatus.isGranted &&
          advertiseStatus.isGranted &&
          connectStatus.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS uses bluetooth permission
      final bluetoothStatus = await Permission.bluetooth.status;
      return bluetoothStatus.isGranted;
    }

    return false;
  }

  /// Request Bluetooth permissions from user
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }

    return false;
  }

  /// Start advertising this device's UUID
  /// Note: Flutter Blue Plus doesn't support BLE advertising on most platforms
  /// This is a placeholder for future implementation or native platform integration
  Future<bool> startAdvertising() async {
    try {
      // Check if Bluetooth is available and enabled
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        debugPrint('[BLE] Bluetooth adapter not available');
        return false;
      }

      final isOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
      if (!isOn) {
        debugPrint('[BLE] Bluetooth is off, attempting to turn on...');
        // Note: FlutterBluePlus cannot turn on Bluetooth, user must do it manually
        return false;
      }

      // TODO: Implement BLE advertising via platform channel
      // Flutter Blue Plus doesn't support advertising natively
      // Would need native iOS/Android code to advertise manufacturer data
      debugPrint('[BLE] Advertising not yet implemented (requires platform channel)');
      debugPrint('[BLE] My UUID: ${_userIdToUuid(_myUserId)}');

      _isAdvertising = true;
      return true;
    } catch (e) {
      debugPrint('[BLE] Failed to start advertising: $e');
      return false;
    }
  }

  /// Stop advertising
  Future<void> stopAdvertising() async {
    _isAdvertising = false;
    debugPrint('[BLE] Stopped advertising');
  }

  /// Start scanning for nearby BLE devices
  Future<bool> startScanning() async {
    try {
      // Check if Bluetooth is available and enabled
      final isAvailable = await FlutterBluePlus.isAvailable;
      if (!isAvailable) {
        debugPrint('[BLE] Bluetooth adapter not available');
        return false;
      }

      // Wait for adapter to be on
      await FlutterBluePlus.adapterState
          .firstWhere((state) => state == BluetoothAdapterState.on)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('[BLE] Bluetooth is off');
              return BluetoothAdapterState.off;
            },
          );

      // Start scanning
      debugPrint('[BLE] Starting scan...');

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: false, // We're not using BLE for location
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _processScanResults(results);
      });

      // Restart scan every 5 seconds to keep scanning active
      Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!_isScanning) {
          timer.cancel();
          return;
        }

        FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 4),
          androidUsesFineLocation: false,
        );
      });

      _isScanning = true;
      debugPrint('[BLE] Scan started');
      return true;
    } catch (e) {
      debugPrint('[BLE] Failed to start scanning: $e');
      return false;
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    _isScanning = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
    _currentRssi.clear();
    debugPrint('[BLE] Stopped scanning');
  }

  /// Process scan results and extract RSSI data for game participants
  void _processScanResults(List<ScanResult> results) {
    for (final result in results) {
      final deviceId = result.device.remoteId.toString();
      final rssi = result.rssi;

      // Check if this device belongs to a game participant
      // Note: Since we can't advertise custom UUIDs easily with flutter_blue_plus,
      // we're using device IDs directly. In production, this would use manufacturer data.
      final userId = _uuidToUserId[deviceId];

      if (userId != null) {
        _currentRssi[userId] = rssi;
        debugPrint('[BLE] Detected $userId at RSSI: $rssi dBm');
      }
    }

    // Emit updated RSSI data
    _rssiController.add(Map.from(_currentRssi));
  }

  /// Get current RSSI snapshot (synchronous)
  Map<String, int> currentRssiSnapshot() {
    return Map.from(_currentRssi);
  }

  /// Stream of RSSI updates
  Stream<Map<String, int>> get rssiStream => _rssiController.stream;

  /// Check if service is currently scanning
  bool get isScanning => _isScanning;

  /// Check if service is currently advertising
  bool get isAdvertising => _isAdvertising;

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    _rssiController.close();
  }
}
