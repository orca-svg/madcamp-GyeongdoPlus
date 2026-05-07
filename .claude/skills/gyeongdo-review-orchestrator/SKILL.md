---
name: gyeongdo-review-orchestrator
description: GyeongdoPlus 전체 코드리뷰 오케스트레이터. "코드 리뷰해줘", "리뷰 실행", "전체 점검", "코드 품질 확인", "버그 찾아줘", "개선점 찾아줘", "다시 리뷰", "재실행", "Flutter 리뷰", "Backend 리뷰", "게임 로직 검증", "통합 정합성 확인" 요청 시 반드시 이 스킬을 사용한다. 4개 전문 에이전트를 병렬로 실행하고 종합 리포트를 생성한다.
---

# GyeongdoPlus 코드리뷰 오케스트레이터

**실행 모드:** 서브 에이전트 병렬 실행 (도메인별 독립 리뷰)

## Phase 0: 컨텍스트 확인

시작 시 `_workspace/` 디렉토리 존재 여부를 확인한다:
- `_workspace/` 없음 → **초기 실행**: Phase 1부터 전체 실행
- `_workspace/` 있음 + 사용자가 특정 영역 재리뷰 요청 → **부분 재실행**: 해당 에이전트만 재호출
- `_workspace/` 있음 + "다시 리뷰" 요청 → **전체 재실행**: `_workspace/`를 `_workspace_prev/`로 이동 후 재실행

## Phase 1: 리뷰 범위 결정

사용자가 특정 범위를 지정하지 않으면 **전체 리뷰**를 실행한다.

범위별 에이전트 할당:
| 요청 | 실행할 에이전트 |
|------|--------------|
| 전체 / 기본 | 4개 전부 |
| "Flutter" / "프론트" | flutter-reviewer만 |
| "Backend" / "서버" | backend-reviewer만 |
| "게임 로직" / "밸런스" | game-logic-reviewer만 |
| "통합" / "프로토콜" / "DTO" | integration-checker만 |

`_workspace/` 디렉토리를 생성한다.

## Phase 2: 병렬 리뷰 실행

**실행 모드: 서브 에이전트 병렬**

4개 에이전트를 `run_in_background: true`로 동시에 실행한다. 각 에이전트는 독립적으로 코드를 분석하고 결과를 `_workspace/` 파일에 저장한다.

### Flutter 리뷰어 프롬프트 템플릿
```
당신은 flutter-reviewer 에이전트입니다. flutter-review-guide 스킬에 따라 GyeongdoPlus Flutter 코드를 심층 리뷰하라.

리뷰 경로: frontend/lib/
스킬 파일 경로: .claude/skills/flutter-review-guide/SKILL.md

리뷰 완료 후 결과를 _workspace/01_flutter_review.md 파일로 저장하라.
```

### Backend 리뷰어 프롬프트 템플릿
```
당신은 backend-reviewer 에이전트입니다. backend-review-guide 스킬에 따라 GyeongdoPlus NestJS 백엔드를 심층 리뷰하라.

리뷰 경로: backend/src/
스킬 파일 경로: .claude/skills/backend-review-guide/SKILL.md

핵심 파일:
- backend/src/modules/events/events.gateway.ts
- backend/src/modules/game/game.service.ts
- backend/src/modules/lobby/lobby.service.ts

리뷰 완료 후 결과를 _workspace/02_backend_review.md 파일로 저장하라.
```

### 게임 로직 리뷰어 프롬프트 템플릿
```
당신은 game-logic-reviewer 에이전트입니다. game-logic-review-guide 스킬에 따라 GyeongdoPlus 게임 로직을 검증하라.

스킬 파일 경로: .claude/skills/game-logic-review-guide/SKILL.md

핵심 파일:
- backend/src/modules/game/game.service.ts
- frontend/lib/providers/
- frontend/lib/features/radar/
- frontend/lib/net/ws/dto/

리뷰 완료 후 결과를 _workspace/03_game_logic_review.md 파일로 저장하라.
```

### 통합 정합성 검증 프롬프트 템플릿
```
당신은 integration-checker 에이전트입니다. integration-review-guide 스킬에 따라 Frontend-Backend 통합 정합성을 검증하라.

스킬 파일 경로: .claude/skills/integration-review-guide/SKILL.md

비교 파일:
- frontend/lib/net/ws/ws_types.dart
- frontend/lib/net/ws/dto/
- frontend/lib/data/api_client.dart
- backend/src/modules/events/events.gateway.ts
- backend/src/modules/*/dto/*.ts

리뷰 완료 후 결과를 _workspace/04_integration_review.md 파일로 저장하라.
```

## Phase 3: 결과 수집 및 종합

모든 에이전트 완료 후 `_workspace/` 파일들을 읽어 종합 리포트를 생성한다.

### 종합 리포트 구조

```markdown
# GyeongdoPlus 코드리뷰 종합 리포트
**일시:** {날짜}  **리뷰 범위:** {전체/부분}

## 전체 요약
| 영역 | CRITICAL | WARNING | SUGGESTION |
|------|----------|---------|------------|
| Flutter | N | N | N |
| Backend | N | N | N |
| 게임 로직 | N | N | N |
| 통합 정합성 | N | N | N |
| **합계** | **N** | **N** | **N** |

## 즉시 수정 필요 (CRITICAL)
{각 에이전트의 CRITICAL 이슈를 우선순위별로 통합}

## 주요 경고 (WARNING)
{WARNING 이슈 통합}

## 개선 제안 (SUGGESTION)
{SUGGESTION 통합}

## 기획 의도 달성도
경찰/도둑 실시간 위치 기반 게임으로서의 완성도 평가

## 다음 스프린트 우선순위
1. {가장 중요한 이슈}
2. {두 번째}
3. {세 번째}
```

종합 리포트를 `_workspace/00_summary_report.md`에 저장하고, 사용자에게 전체 내용을 출력한다.

## Phase 4: 개선 액션 제안

리포트 출력 후 사용자에게 물어본다:
- "특정 이슈를 바로 수정할까요?"
- "특정 영역만 다시 깊게 리뷰할까요?"

## 에러 핸들링

- 에이전트가 결과 파일을 저장하지 못하면: 에이전트를 단독으로 재실행
- 파일 읽기 실패 시: 해당 영역을 "리뷰 실패"로 표시하고 나머지 계속 진행

## 테스트 시나리오

**정상 흐름:** "코드 리뷰해줘" → 4개 에이전트 병렬 실행 → 종합 리포트 생성  
**부분 리뷰:** "Flutter 쪽만 다시 리뷰해줘" → flutter-reviewer만 재실행 → 기존 결과와 새 결과 병합  
**에러 흐름:** 에이전트 1개 실패 → 실패 표시 + 나머지 3개 결과로 종합 리포트 생성
