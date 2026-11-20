# 맥 브리지 MCP 서버 설계 — 폰 클라이언트, Claude는 localhost(stdio)

> 작성: 2026-11-17 · 상태: **초안** · 결정 배경: `docs/adr-002-desktop-mcp-bridge.md`
> ADR-001(`docs/mcp-design.md`)의 폰 내장 서버를 대체하는 기본 경로. 폰 서버는 폴백으로 유지.

## 0. 한 줄 구조

```
Claude Code ── stdio(JSON-RPC/MCP) ── 브리지(node 단일 파일) ── TCP 8766(JSON lines) ── 폰 Loop 앱
```

- Claude 입장: 플러그인이 제공하는 stdio MCP 서버. **설정·포트·IP·토큰 전무** — 설치만 하면 끝
- 폰 입장: "PC 연결" 화면에서 맥에 **클라이언트로** 접속. 데이터 원본은 폰에 그대로

## 1. 구성 요소

### 1.1 맥 — `bridge/server.mjs` (node ≥18, 의존성 0)

- **stdio MCP**: `initialize`·`tools/list`·`tools/call`·`ping` (기존 `mcp_protocol.dart`
  최소 구현과 동일한 JSON-RPC 2.0. 도구 정의는 `mcp_tools.dart` definitions를 JSON으로 이식)
- **TCP 리스너 8766**: 폰 전용. 한 브리지에 폰 1대(다중 폰은 후순위)
- **상태 파일 `~/.loop-bridge/state.json`**: 페어링된 폰(deviceId·secret·이름·마지막 연결)
- **mDNS 광고**: 하위호환 명령으로 시스템 바이너리 실행 — macOS `dns-sd -R`,
  Linux `avahi-publish-service`. 광고명 `Loop Bridge`, 타입 `_loop-bridge._tcp`, 포트 8766.
  폰 NSD 탐색용. 실패해도 수동 IP 입력으로 동작(치명적 아님)

### 1.2 폰 — `lib/services/pc_link.dart` (신규) + 설정 → "PC 연결" 화면

- **v1은 수동 IP 입력**(1회, 저장) — Claude에게 맥 IP를 물어보면 `bridge_status`가
  안내한다. NSD 자동 탐색은 후순위로 미뤘다: Android 멀티캐스트 락 안정성·
  의존성 추가(§9) 트레이드오프가 v1 가치보다 큼
- 접속 → 미페어링이면 8자리 코드 입력 UI → 페어링 후 자동 재접속
- 도구 호출 수신 시 기존 `McpTools.call()` 재사용 — 응답 생성 로직 공유
- ~~앱 foreground에서만 유지~~ → **2026-11-18 변경(ADR-003)**: 연결 중에는 Android `dataSync`
  FGS(`PcLinkService`)로 화면 꺼짐·다른 앱 사용 중에도 유지. 연결 또는 마지막 질의 후
  60분 조용하면 끊고 FGS 종료. 알림의 [연결 끊기]·Android 15+ `onTimeout`도 즉시 종료

## 2. 도구 (Claude에 노출)

| 도구 | 동작 |
|---|---|
| `search_logs` / `get_log` / `get_chain` / `logs_on_day` | 폰으로 중계. 폰 미연결 시 안내 오류(`isError`) |
| `bridge_status` | 폰 연결 상태·페어링 여부·맥 주소(폰에 표시될 코드 안내 포함) |
| `pairing_code` | 미페어링 폰 접속 시 8자리 코드 생성·반환. Claude가 채팅에 표시 → 사용자가 폰에 입력 |

좌표 제외·장소명 포함 등 기존 정책(`mcp-design.md` §도구) 그대로.

## 3. 페어링

1. 폰이 TCP 접속 → `hello` (deviceId, proto=1)
2. 브리지: 미등록 deviceId면 `need_code` 응답. 등록이면 secret 대조 후 `paired`
3. 사용자가 Claude에게 코드 요청 → `pairing_code` 호출 → 브리지가 8자리(숫자, 5분 TTL)
   생성· 반환 → Claude가 표시
4. 폰이 코드를 `pair` 메시지로 전송 → 일치 시: 브리지가 32바이트 secret 발급·
   `state.json` 저장, 폰에도 전달(폰은 자체 저장) → `paired`
5. 이후 재접속은 `hello`의 deviceId+secret로 즉시 연결. 폰/맥 어디서나 페어링 해제 가능
6. 자동 재연결: 연결돼 있던 링크가 예기치 않게 끊기면(브리지 재시작·업그레이드, 맥 잠자기,
   Wi-Fi 순단, ping 무응답) 폰이 1·2·5·10·30초 간격으로 최대 10회(약 3분) 다시 붙는다.
   `refused`/`timeout`/단선만 재시도하고, 사용자가 끊음·`busy`·`too_many`·secret 무효·코드 요구는
   멈춘다. 앱이 배경이면 멈추고(단, FGS 세션 중이면 배경에서도 계속 — ADR-003), 전경으로
   돌아오면(포기 후 포함) 즉시 다시 시도한다. 재시도를 다 쓰면 FGS 세션도 끝낸다.

코드 정책: 숫자 8자리(`crypto.randomInt`), TTL 5분, 시도 5회 초과 시 접속 끊기.
무차별 대입은 LAN 내 가정에서 이 정도로 충분(위협 모델 §7).

## 4. 브리지↔폰 프로토콜 (TCP 8766, JSON lines, UTF-8)

```
폰→맥  {"t":"hello","id":"<uuid>","proto":1,"secret":"<발급받은 경우>"}
맥→폰  {"t":"need_code"} | {"t":"paired","secret":"<32B b64u>"} | {"t":"busy"} | {"t":"bye"}
폰→맥  {"t":"pair","code":"58329417"}
폰→맥  {"t":"ping"}                      맥→폰 {"t":"pong"}        (30초 간격, 끊김 감지)
맥→폰  {"t":"invoke","rid":1,"tool":"search_logs","args":{...}}
폰→맥  {"t":"result","rid":1,"ok":true,"text":"..."} | {"t":"result","rid":1,"ok":false,"error":"..."}
```

- `rid`는 브리지가 발급, MCP 요청 id와 별도 매핑. 폰은 순서 보장 못함(비동기 처리)
- 호출 타임아웃 30초 — 폰 응답 없으면 MCP 오류로 반환
- 도구 인자 검증은 폰(`McpTools.call()`의 `_InputError` 경로)이 담당 — 브리지는 중계만

## 5. Claude ↔ 브리지 (stdio MCP)

- `plugin.json`의 `mcpServers`로 선언 — 플러그인 설치 시 자동 등록:

```json
"mcpServers": {
  "loop": {
    "type": "stdio",
    "command": "node",
    "args": ["${CLAUDE_PLUGIN_ROOT}/bridge/server.mjs"],
    "env": {}
  }
}
```

- 세션마다 브리지 프로세스 1개 기동. 두 번째 세션의 브리지는 8766 점유 실패를 감지하면
  **stdio MCP는 정상 서비스하되** `bridge_status`에 "다른 세션이 폰 연결을 점유 중" 표시.
  폰은 점유 브리지에 붙음(모든 세션이 같은 폰을 공유하는 구조는 후순위)

## 6. 보안·프라이버시

- 기록은 폰의 DB에만 존재. 맥·브리지는 질의 응답을 메모리에만 두고 디스크 기록 없음
  (`state.json`엔 deviceId·secret·이름만)
- secret은 평문 저장(로컬 파일, 디스크 암호화에 의존 — 키체인 연동은 후순위)
- LAN 내 공격자가 TCP 8766에 직접 붙어도: 미페어링 deviceId → 코드 필요(5분 TTL),
  페어링된 deviceId 가장 → secret 몰라 `paired` 불가
- 평문 TCP(폰 서버의 TLS 후순위 결정과 동일 수준). HMAC per-message는 v1.1 후보

## 7. 위협 모델과 남는 리스크

| 위협 | 대응 | 남는 것 |
|---|---|---|
| 같은 Wi-Fi의 제3자 | 페어링 코드 + secret | 평문 스니핑은 가능(응답 내용 노출) → TLS/HMAC 후순위 |
| 무차별 코드 대입 | 5회 실패 접속 끊기 + 5분 TTL | — |
| 맥 파일 열람 | state.json에 기록 없음(메타만) | secret 자체는 평문 파일 |
| 폰 분실 | 폰에서 해제 불가해도 맥 `state.json`에서 deviceId 삭제로 차단 | — |

## 8. 단계

| 단계 | 내용 | 완료 기준 |
|---|---|---|
| B1 | `server.mjs` — stdio MCP + TCP + 페어링 + state | 가상 폰 스크립트로 tools/call E2E 성공 — **완료(2026-11-17, 16/16)** |
| B2 | loop-skill 반영 — `mcpServers`·SKILL.md·README | `claude plugin validate` 통과, 실세션에서 도구 목록 — **완료(2026-11-17)** |
| B3 | 폰 `pc_link.dart` + "PC 연결" 화면 | 실기기: 코드 입력 → `search_logs` 검색 성공 — **구현·단위테스트 완료(7/7), 실기기 검증 남음** |
| B4 | 문서 — ADR-002 상태 갱신, FAQ 통합, 스토어 문구 | 기존 P5 절차 준용 |

## 9. 후순위

- 다중 폰·다중 세션 동시 접속(브리지 소유권 이관 또는 상주 데몬)
- TLS(자체 서명 + 페어링 시 핀) / 메시지 HMAC
- ~~폰 백그라운드 유지(FGS)~~ — 2026-11-18 ADR-003으로 60분 유휴 세션 FGS 채택.
  "AI가 필요할 때 폰에 요청" 푸시 계열(연결 안 된 상태에서 깨우기)은 여전히 후순위
- 키체인 저장, 클립보드·QR 대체 입력
