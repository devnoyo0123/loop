# 로컬 MCP 서버 계획 — 같은 Wi-Fi의 Mac에서 Loop 기록 검색

> 작성 일자: 2026-11-01 · 상태: **폐기 (2026-11-17)** — ADR-002로 방향 반전. 폰 내장 서버는 스토어 출시 전 제거됨.
> 대체: `docs/adr-002-desktop-mcp-bridge.md` · `docs/mcp-bridge-design.md`. 아래는 역사 기록으로 보존.
> 원 상태: P1~P4 코드 구현 완료 (2026-11-01) · 대상: **Android 전용** (iOS 범위 밖 — 2026-11-01 결정)
> **상세 설계: `docs/mcp-design.md`** — 이 문서는 결정 기록·단계·리스크만 둔다.
> 개발 순서: 순수 Dart 핸들러(폰 없이 테스트) → HTTP 계층(macOS 빌드로 테스트) → UI·l10n → Android FGS → 문서.

## 0. 목표와 원칙

- **목표** — 앱에서 "MCP 서버" 토글을 켜면, 같은 Wi-Fi의 Mac에 있는 Claude Code가 폰의 Loop 기록을 검색해 컨텍스트로 가져간다.
- **로컬 퍼스트 유지** — 중계 서버 없음. 폰 ↔ Mac 직접 통신. 데이터가 밖으로 나가는 지점은 "사용자가 붙인 LLM 클라이언트" 하나뿐이며, 켤 때 명시 동의.
- **기본 OFF, 읽기 전용, 짧게 열고 자동으로 닫힘.**
- **기존 자산 재사용** — 검색은 `LoopDb.searchDetailed`(FTS5 trigram, `lib/data/loop_db.dart:459`), 계보는 `lineage`/path 전방 일치, 하루 단위는 `logsOnDay`.

## 1. 결정 사항

| 항목 | 결정 | 상태 |
|---|---|---|
| 플랫폼 | **Android만**. iOS는 메뉴 자체를 숨김(`Platform.isAndroid` 가드). iOS는 백그라운드 소켓 유지 불가라 제외 | 확정 |
| 전송 방식 | MCP **Streamable HTTP** (`POST /mcp`, JSON-RPC 2.0, 응답 `application/json`) | 확정 |
| SDK | 최소 구현 직접 작성 (`initialize`·`tools/list`·`tools/call`·`ping`). `dart_mcp` 패키지 HTTP 서버 지원 여부는 착수 시 확인 후 대체 검토 | 확정(재검토 가능) |
| 1차 클라이언트 | Claude Code (`claude mcp add --transport http …`) | 확정 |
| Claude Desktop | `npx mcp-remote` 브리지로 안내만 (공식 지원 범위 밖) | 후순위 |
| 권한 범위 | **읽기 전용** 도구만. 쓰기(로그 추가 등)는 범위 밖 | 확정 |
| 인증 | Bearer 토큰 — **영속**(설정 저장), 수동 재발급 버튼 + 5회 실패 시 자동 재발급 | 확정 (2026-11-01) |
| 바인딩 | `0.0.0.0` 아님 — **Wi-Fi 인터페이스 IPv4에만** bind (셀룰러 노출 차단) | 확정 |
| 자동 종료 | **기본 30분** (15/30/60분 선택, 화면에서 연장 가능) | 확정 |
| 위치 정보 | 좌표(lat/lng) **항상 제외**, 장소명(`place`)·날씨는 **기본 포함**(서버 화면에서 장소명 끌 수 있음) | 확정 |
| 미디어 | 1차 제외. 이미지 개수만 메타로 표시 | 확정 |
| Android FGS 타입 | **`dataSync`** — 자동 종료 최대 60분이라 Android 15의 dataSync 시간 제한(24시간 중 6시간) 안에 듦. `specialUse`는 기각 | 확정 |
| TLS | 1차 평문 HTTP + 토큰. 자체 서명 인증서 + 핀 고정은 후순위 | 확정 |
| mDNS 탐색 | 1차 없음 (화면에 URL·토큰 표시). 후순위 | 확정 |

## 2. 문서·정책

- `docs/privacy-policy.md` — "사용자가 켠 경우에 한해, 같은 네트워크의 사용자 기기로 기록을 전송하며 그 기기의 AI 클라이언트가 외부 서비스로 보낼 수 있음" 조항.
- `docs/store-listing.md` — 기능 소개(선택).
- `docs/data-model.md` — 스키마 변경 없음(신규 DB 메서드만) 확인.
- Play Console 앱 콘텐츠 — FGS 권한 신고에 `dataSync` 용도 추가(설명 + 데모 영상). 기존 `mediaPlayback` 신고와 같은 양식.

## 3. 단계

| 단계 | 내용 | 완료 기준 |
|---|---|---|
| **P1 프로토콜·도구** | `mcp_protocol.dart`, `mcp_tools.dart`, `LoopDb` 확장(`searchDetailed` 날짜 필터, `chainLogs`) | 단위 테스트 통과(폰·HTTP 없이) |
| **P2 HTTP 계층** | `mcp_server.dart` — bind, 토큰, Origin/Host 검사, 실패 잠금, 자동 종료 | macOS 빌드에서 `curl` 시나리오 + Claude Code `claude mcp add`로 실제 검색 성공 |
| **P3 UI·l10n** | 설정 항목, 서버 화면, 동의·경고, 명령 복사, 접근 로그, 연결 상태 진단, **연결 FAQ 화면**(오류 → 해당 항목 바로 열기) | 6개 언어 테스트 통과, 오류 상태별 "자세히 보기"가 맞는 FAQ 항목을 여는지 위젯 테스트, 수동 확인 |
| **P4 Android** | FGS + 상주 알림 + WifiLock | 실기기에서 화면 끔 상태로 30분간 Mac 검색 유지 |
| **P5 문서** | 개인정보처리방침·스토어·체크리스트 | `docs/pre-release-checklist.md` 항목 추가 |

## 4. 테스트

상세 목록은 `docs/mcp-design.md` §12.

## 5. 리스크·미정

- **AP isolation**(게스트 Wi-Fi·일부 공유기) — 기기 간 통신 불가. 폰은 "막혔다"를 직접 감지할 수 없으므로(요청이 아예 안 옴) 설계 §4.4 진단 + §11.3 Mac 진단 명령으로 안내.
- **macOS 로컬 네트워크 권한**(macOS 15+) — 터미널 앱이 허용 안 되면 LAN 접속이 조용히 실패. 설계 §11.3 진단 명령이 감지·안내. P2에서 실제 팝업·실패 메시지 확인.
- **진단 명령 정확도** — `route`/`curl` 출력 문구가 macOS 버전별로 다를 수 있음. P2에서 각 케이스(VPN·다른 대역·격리 Wi-Fi·권한 거부)를 실제로 재현해 검증.
- **DHCP IP 변경** — 서버 재시작 시 URL이 바뀔 수 있음 → 명령 복사 버튼으로 완화, 근본 해결은 mDNS(후순위).
- **Claude Code의 LAN http 연결 동작** — P2에서 실제 확인(헤더 전달, 타임아웃).
- 미정 결정: 없음 — 자동 종료 30분, 좌표 제외·장소명 포함, FGS `dataSync`로 2026-11-01 확정.

## 6. 후순위

- mDNS/Bonjour 광고(`_loop-mcp._tcp`) + Mac 쪽 자동 탐색.
- TLS(자체 서명 + 페어링 시 인증서 핀).
- 이미지 반환(요청 시 썸네일만, MCP image content).
- 쓰기 도구(`add_log`) — 별도 동의·확인 UI 필요.
- Claude Desktop 공식 연결 가이드.
