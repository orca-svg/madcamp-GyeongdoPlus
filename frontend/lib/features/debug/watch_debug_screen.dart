import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/game_phase_provider.dart';
import '../../providers/watch_provider.dart';
import '../../watch/state_snapshot_builder.dart';
import '../../watch/watch_bridge.dart';
import '../../watch/watch_debug_overrides.dart';

class WatchDebugScreen extends ConsumerStatefulWidget {
  const WatchDebugScreen({super.key});

  @override
  ConsumerState<WatchDebugScreen> createState() => _WatchDebugScreenState();
}

class _WatchDebugScreenState extends ConsumerState<WatchDebugScreen> {
  StreamSubscription<Map<String, dynamic>>? _sub;
  final List<String> _logs = <String>[];

  @override
  void initState() {
    super.initState();
    _sub = ref.read(watchBridgeProvider).onWatchAction().listen((event) {
      final line = jsonEncode(event);
      _addLog('RX ${line.length}b ${_trim(line)}');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _addLog(String line) {
    setState(() {
      _logs.insert(0, line);
      if (_logs.length > 20) _logs.removeLast();
    });
  }

  Future<void> _sendSnapshot() async {
    final snapshot = StateSnapshotBuilder.build((p) => ref.read(p));
    await ref.read(watchBridgeProvider).sendStateSnapshot(snapshot);
    final len = jsonEncode(snapshot).length;
    debugPrint(
      '[WATCH][FLUTTER][TX] STATE_SNAPSHOT matchId=${snapshot['matchId']} len=$len',
    );
    _addLog('TX STATE_SNAPSHOT ${len}b');
  }

  Future<void> _sendHaptic() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final payload = {
      'type': 'HAPTIC_ALERT',
      'ts': now,
      'matchId': 'DEBUG',
      'payload': {
        'kind': 'ENEMY_NEAR_5M',
        'cooldownSec': 5,
        'durationMs': 300,
      },
    };
    await ref.read(watchBridgeProvider).sendHapticAlert(payload);
    final len = jsonEncode(payload).length;
    debugPrint(
      '[WATCH][FLUTTER][TX] HAPTIC_ALERT matchId=${payload['matchId']} len=$len',
    );
    _addLog('TX HAPTIC_ALERT ${len}b');
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug only')),
      );
    }

    final connected = ref.watch(watchConnectedProvider);
    final phase = ref.watch(gamePhaseProvider);
    final override = ref.watch(debugWatchPhaseOverrideProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Watch Debug')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Connected', connected ? 'true' : 'false'),
            const SizedBox(height: 8),
            _row('Phase', phase.name),
            _row('Override', override?.name ?? 'null'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _phaseBtn(context, 'OFF_GAME', GamePhase.offGame),
                _phaseBtn(context, 'LOBBY', GamePhase.lobby),
                _phaseBtn(context, 'IN_GAME', GamePhase.inGame),
                _phaseBtn(context, 'POST_GAME', GamePhase.postGame),
                OutlinedButton(
                  onPressed: () => ref
                      .read(debugWatchPhaseOverrideProvider.notifier)
                      .set(null),
                  child: const Text('Clear Override'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _sendSnapshot,
                  child: const Text('Send Snapshot Now'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _sendHaptic,
                  child: const Text('Send Haptic Now'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Action Logs (latest 20)'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Text(
                    _logs[i],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(k)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _phaseBtn(BuildContext context, String label, GamePhase phase) {
    return OutlinedButton(
      onPressed: () =>
          ref.read(debugWatchPhaseOverrideProvider.notifier).set(phase),
      child: Text(label),
    );
  }

  String _trim(String s) => s.length <= 140 ? s : '${s.substring(0, 140)}…';
}
