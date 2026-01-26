import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/net/ws/ws_client.dart';
import 'package:frontend/providers/ws_ui_status_provider.dart';

void main() {
  test('deriveWsUiStatus derives status from connection/serverHello/snapshot', () {
    // 1) disconnected
    final m1 = deriveWsUiStatus(
      wsConn: const WsConnectionState(
        status: WsConnStatus.disconnected,
        reconnectAttempt: 0,
        lastError: null,
        epoch: 0,
      ),
      serverHelloEpoch: 0,
      hasSnapshot: false,
      userReconnectIntent: false,
    );
    expect(m1.status, WsUiStatus.disconnected);
    expect(m1.showReconnect, true);

    // 2) connected but serverHello not yet confirmed for this epoch
    final m2 = deriveWsUiStatus(
      wsConn: const WsConnectionState(
        status: WsConnStatus.connected,
        reconnectAttempt: 0,
        lastError: null,
        epoch: 2,
      ),
      serverHelloEpoch: 0,
      hasSnapshot: false,
      userReconnectIntent: false,
    );
    expect(m2.status, WsUiStatus.awaitingServerHello);
    expect(m2.showReconnect, false);

    // 3) serverHello confirmed but snapshot not yet received
    final m3 = deriveWsUiStatus(
      wsConn: const WsConnectionState(
        status: WsConnStatus.connected,
        reconnectAttempt: 0,
        lastError: null,
        epoch: 2,
      ),
      serverHelloEpoch: 2,
      hasSnapshot: false,
      userReconnectIntent: false,
    );
    expect(m3.status, WsUiStatus.awaitingSnapshot);
    expect(m3.showReconnect, false);

    // 4) snapshot received -> synced
    final m4 = deriveWsUiStatus(
      wsConn: const WsConnectionState(
        status: WsConnStatus.connected,
        reconnectAttempt: 0,
        lastError: null,
        epoch: 2,
      ),
      serverHelloEpoch: 2,
      hasSnapshot: true,
      userReconnectIntent: false,
    );
    expect(m4.status, WsUiStatus.synced);
    expect(m4.isSynced, true);
    expect(m4.showReconnect, false);
  });
}
