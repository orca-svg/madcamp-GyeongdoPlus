# Manual Test Checklist

- Home/내정보: Bottom overflow 0건
- Lobby: 하단 바 높이 과다 없음(시각적으로 컨텐츠 더 보임)
- Lobby: 규칙 요약이 편집 값 그대로 반영
- Lobby(방장): 편집 버튼 노출/동작, 참가자는 실시간 반영(프론트 상태)
- Lobby: 경찰 수 슬라이더 조작 시 도둑 수 자동, 합=방 인원 유지
- Lobby: 팀 선택(경찰/도둑) 네온 라디오, READY/WAIT 토글 정상
- Lobby: 게임 시작 버튼은 조건 만족 시만 활성화 + 미충족 문구 표시
- Debug: BOT 추가/READY 토글로 조건 테스트 가능
- ZoneEditor: 점 3개 미만이면 지도 위 폴리곤 fill이 즉시 사라짐(undo/reset 포함)
- InGame Radar: 상단 UI 겹침 없음, 시간 우측 표기, WsStatusPill 제거
- InGame Map: 지도 높이 증가, 폴리곤/감옥 표시만(편집 불가)
- Watch: 연결 상태가 5초 주기로 갱신되어 끊김도 즉시 반영
- InGame: 나가기 버튼/주요 버튼이 하단 nav에 가리지 않음
