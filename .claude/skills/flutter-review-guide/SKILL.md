---
name: flutter-review-guide
description: GyeongdoPlus Flutter/Dart 코드 리뷰 가이드. flutter-reviewer 에이전트가 사용하는 심층 리뷰 기준과 체크포인트. Flutter, Riverpod, Dart, 게임 UI 코드를 리뷰할 때 사용한다.
---

# Flutter 코드 리뷰 가이드 — GyeongdoPlus

## 프로젝트 컨텍스트

- **경로**: `frontend/lib/`
- **상태 관리**: Riverpod (`flutter_riverpod`)
- **빌드 환경**: FVM + Flutter 3.24.5
- **핵심 의존성**: `web_socket_channel`, `dio`, `riverpod`

## 리뷰 우선순위

### 1순위 — 게임 안정성 직결

**Phase 전환 안전성** (`providers/game_phase_provider.dart`, `features/navigation/`)
- `offGame → lobby → inGame → postGame` 각 전환에서 이전 리소스 정리 확인
- 특히 `inGame → postGame` 전환 시 오디오, WebSocket 구독, 타이머 모두 정리되는지

**WS 이벤트 구독 수명주기** (`net/ws/ws_client_provider.dart`)
- `ProviderSubscription`이 올바른 `ref` 수명과 연결되어 있는지
- `listen`으로 시작한 구독이 `close()` 호출로 종료되는지

**레이더 CustomPainter 성능** (`features/radar/widgets/radar_painter.dart`)
- `shouldRepaint` 구현이 실제로 이전/현재 상태를 비교하는지 (항상 `true` 반환 금지)
- 레이더는 게임 중 초당 여러 번 갱신 → 불필요한 repaint는 프레임 드롭으로 직결

### 2순위 — 코드 품질

**Riverpod 패턴 오류**
```dart
// 잘못된 패턴 — build 메서드 내 ref.read
Widget build(BuildContext context, WidgetRef ref) {
  final value = ref.read(someProvider); // ❌ 갱신 안 됨
}

// 올바른 패턴
Widget build(BuildContext context, WidgetRef ref) {
  final value = ref.watch(someProvider); // ✅
}
```

**ConsumerStatefulWidget dispose 패턴**
```dart
// 필수 체크: dispose에서 StreamSubscription, Timer, AnimationController 취소
@override
void dispose() {
  _timer.cancel();
  _sub.cancel();
  _controller.dispose();
  super.dispose();
}
```

**null safety**
- `!` 강제 unwrap 남용 확인 (null 가능성 있는 값에 `!` 사용)
- `late` 변수가 initState보다 먼저 접근될 수 있는 경우

### 3순위 — UI 일관성

**디자인 시스템 준수**
- 색상은 반드시 `AppColors.*` 사용 (hex 리터럴 금지)
- 간격/반경은 `AppDimens.*` 상수 사용
- 버튼은 `GradientButton`, 카드는 `GlowCard` 또는 `GlassBackground` 사용

**게임 테마 일관성**
- 네온/사이버펑크 테마 (`borderCyan`, `lime`, `red`, `orange`, `purple`)
- 게임 화면에서 Material 기본 스타일 요소 사용 지양

## 자주 발생하는 패턴 문제

### Apple Watch 브리지
`watch/watch_bridge.dart`에서 platform channel 호출 시:
- try/catch로 `PlatformException` 처리
- Watch 미연결 상태에서도 게임이 정상 동작해야 함

### 오디오 서비스
`core/services/audio_service.dart`:
- `dispose`에서 BGM 정지 확인
- 화면 이동 시 이전 BGM 중복 재생 방지

### 환경 변수
- `Env.apiBaseUrl`, `Env.wsUrl`은 `core/env.dart`에서만 접근
- 하드코딩된 URL 문자열 없음 확인

## 출력 형식 (엄격히 준수)

섹션 구조:
1. **요약** (이슈 카운트)
2. **CRITICAL** (게임 안정성, 크래시 유발)
3. **WARNING** (동작은 하지만 비정상 패턴)
4. **SUGGESTION** (선택적 개선)
5. **기획 의도 부합도** (UX 관점 종합 평가)

각 이슈: `파일명:라인번호 — 문제` + `현재 코드` + `개선안`
