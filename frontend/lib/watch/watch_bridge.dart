import 'dart:convert';
import 'package:flutter/services.dart';
import 'radar_packet.dart';

class WatchBridge {
  static const MethodChannel _ch = MethodChannel('gyeongdo/watch_bridge');

  static Future<void> init() async {
    await _ch.invokeMethod('init');
  }

  static Future<bool> isPairedOrConnected() async {
    final v = await _ch.invokeMethod('isConnected');
    return (v == true);
  }

  /// 워치로 레이더 패킷(JSON) 전송
  static Future<void> sendRadarPacket(RadarPacketDto packet) async {
    final jsonStr = jsonEncode(packet.toJson());
    await _ch.invokeMethod('sendRadarPacket', {"json": jsonStr});
  }
}
