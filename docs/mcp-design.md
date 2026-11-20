# Mac에서 검색 (로컬 MCP 서버) — 설계안

> 작성 일자: 2026-11-01 · 상태: **폐기 (2026-11-17)** — ADR-002로 방향 반전, 구현은 출시 전 제거. 역사 기록으로 보존.
> 대체: `docs/adr-002-desktop-mcp-bridge.md` · `docs/mcp-bridge-design.md`
> 진행 계획·단계·리스크: `docs/mcp-server-plan.md`

## 0. 한 줄 요약

사용자가 켜면, Loop 앱이 같은 Wi-Fi 안에서만 열리는 읽기 전용 MCP 서버(HTTP)를 30분간 띄우고, Mac의 Claude Code가 토큰으로 붙어 기록을 검색한다. 연결이 안 되면 상태를 진단해 원인별 FAQ로 안내한다.

## 1. 범위

| 포함 | 제외 |
|---|---|
| Android 앱 내 HTTP MCP 서버 (Streamable HTTP, JSON 응답) | iOS (메뉴 숨김) |
| 읽기 전용 도구 4개 | 쓰기 도구, 이미지·영상 반환 |
| 토큰 인증, Wi-Fi 인터페이스 바인딩, 자동 종료 | TLS, mDNS 자동 탐색 |
| Foreground Service(`dataSync`)로 백그라운드 유지 | 앱이 완전히 종료된 뒤의 서버 유지 |
| 연결 상태 진단, Mac 진단 명령, 연결 FAQ 화면 | Claude Desktop 공식 지원 |

## 2. 구성 요소

```
┌──────────────────────── Flutter (Dart, 메인 isolate) ────────────────────────┐
│ screens/mcp_server_screen.dart ─┐                                            │
│ screens/mcp_faq_screen.dart     ├─ listen ─▶ services/mcp/mcp_controller.dart │
│ screens/settings_sheet.dart  ───┘             (ChangeNotifier: 상태·타이머·진단)│
│                                                  │            │               │
│                         services/mcp/mcp_http_server.dart   services/mcp/     │
│                         (HttpServer: bind·인증·Origin/Host·  mcp_platform.dart │
│                          크기 제한·접근 로그 기록)           (MethodChannel/   │
│                                  │                          EventChannel)     │
│                         services/mcp/mcp_protocol.dart            │           │
│                         (JSON-RPC 디스패치, 순수 Dart)             │           │
│                                  │                                │           │
│                         services/mcp/mcp_tools.dart               │           │
│                         (도구 정의·실행·포맷) ──▶ LoopDb           │           │
└───────────────────────────────────────────────────────────────────┼───────────┘
                                                                    │ app.loop/mcp
┌──────────────────────────── Android (Kotlin) ─────────────────────┼───────────┐
│ McpBridge.kt  — 채널 핸들러, Wi-Fi IPv4 조회, VPN 감지,            ◀┘           │
│                 NetworkCallback(Wi-Fi 소실·IP 변경) → EventChannel             │
│ McpKeepAliveService.kt — FGS(dataSync), 상주 알림, WifiLock, onTimeout          │
│ MainActivity.kt — McpBridge 등록 / 엔진 정리 시 서비스 정지                     │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 핵심 원칙: 서버는 Dart, 서비스는 "생명 유지 장치"

- HTTP 서버는 **Dart 메인 isolate**에서 돈다(`dart:io HttpServer`). LoopDb를 그대로 쓰기 위해서다.
- Kotlin FGS는 서버를 직접 돌리지 않는다. **프로세스가 백그라운드에서 죽지 않게 붙잡고**, 상주 알림과 WifiLock만 담당한다.
- 홈 버튼으로 나가도 프로세스와 Flutter 엔진은 살아 있으므로 서버가 계속 돈다.
- 최근 앱에서 밀어서 닫는 등 **엔진이 정리되면 서버도 죽는다** → `MainActivity.cleanUpFlutterEngine`에서 서비스를 같이 정지한다. "앱을 닫으면 서버도 꺼짐"이 의도된 동작이다.

## 3. 파일 목록

| 파일 | 역할 |
|---|---|
| `lib/services/mcp/mcp_controller.dart` | 서버 생명주기, 토큰, 타이머, 진단 상태, 설정 읽기/쓰기. UI가 구독 |
| `lib/services/mcp/mcp_http_server.dart` | `HttpServer` 래퍼. 요청 검증 → `McpProtocol` 호출 → 응답. 이벤트를 컨트롤러에 보고 |
| `lib/services/mcp/mcp_protocol.dart` | JSON-RPC 파싱·디스패치. `Map → Map?` 순수 함수 |
| `lib/services/mcp/mcp_tools.dart` | 도구 4개의 스키마·실행·텍스트 포맷 |
| `lib/services/mcp/mcp_platform.dart` | `app.loop/mcp` MethodChannel + `app.loop/mcp_net` EventChannel 래퍼 |
| `lib/services/mcp/mcp_access_log.dart` | 메모리 링 버퍼(50건) |
| `lib/services/mcp/mcp_diagnosis.dart` | 상태 → 진단 결과 계산(순수 함수), Mac 진단 스크립트 생성 |
| `lib/services/mcp/mcp_faq.dart` | `enum McpFaq` + 각 항목의 l10n 키 매핑 |
| `lib/screens/mcp_server_screen.dart` | 서버 화면 |
| `lib/screens/mcp_faq_screen.dart` | 연결 FAQ 화면 |
| `android/.../McpBridge.kt` | 채널 핸들러, 네트워크 조회·감시 |
| `android/.../McpKeepAliveService.kt` | Foreground Service |
| `test/mcp_*_test.dart` | §12 |

## 4. 상태 모델

### 4.1 서버 상태 (`McpServerStatus`)

```
        사용자 ON(동의·경고 통과)
 off ───────────────────────────▶ starting ──bind 성공──▶ running
  ▲                                  │                      │
  │                        bind 실패(포트 모두 사용 중,       │ 정지 사유 발생
  │                        Wi-Fi 없음) → off + 오류 표시      ▼
  └──────────────────────────────────────────────────── stopping
```

### 4.2 정지 사유 (`McpStopReason`)

| 사유 | 계기 | 사용자 안내 |
|---|---|---|
| `user` | 스위치 OFF, 알림의 "끄기" | 없음 |
| `autoStop` | `endsAt` 도달 | 알림 + 서버 화면 배너 "자동으로 꺼졌습니다" |
| `wifiLost` | NetworkCallback: Wi-Fi 소실 | 배너 "Wi-Fi가 끊겨 서버를 껐습니다" |
| `authLockout` | 인증 실패 누적 5회 | **토큰 자동 재발급** + 알림 + 배너 "잘못된 접속 시도가 반복돼 서버를 끄고 토큰을 바꿨습니다 — Mac에서 명령을 다시 실행하세요" → FAQ `safety` |
| `fgsTimeout` | Android 15 `onTimeout()` | 배너 "시스템 제한으로 꺼졌습니다" |
| `appClosed` | 엔진 정리 | (앱이 꺼져 표시 불가 — 상주 알림만 사라짐) |

### 4.3 running 중 컨트롤러가 들고 있는 값

```dart
class McpSession {
  final String ip;            // 바인딩한 Wi-Fi IPv4
  final int port;             // 실제 바인딩 포트
  final String token;         // §7.1 — 설정에서 읽은 영속 토큰
  final DateTime startedAt;
  DateTime endsAt;            // 연장 시 갱신
  int okCount;                // 인증 통과 요청 수
  int authFailCount;          // 401 수 (5 → authLockout)
  DateTime? lastRequestAt;
  String? ipAtCopy;           // 마지막 명령 복사 시점 IP — 설정 mcp_copied_ip에서 읽음(세션 간 유지)
  bool vpnActive;             // 폰 VPN
}
```

### 4.4 진단 상태 (`McpDiagnosis`, `mcp_diagnosis.dart`의 순수 함수로 계산)

우선순위 위에서부터 첫 번째로 맞는 것 하나를 배너로 표시한다.

| 진단 | 조건 | 배너(요지) | "자세히 보기" |
|---|---|---|---|
| `connected` | `okCount > 0` | "Mac 연결됨 ✓ · 마지막 요청 n분 전" | — |
| `tokenMismatch` | `authFailCount > 0 && okCount == 0` | "Mac은 닿았지만 토큰이 다릅니다 — 명령을 다시 복사하세요" | `token` |
| `ipChanged` | `ipAtCopy != null && ipAtCopy != ip` | "폰 주소가 바뀌었습니다 — 명령을 다시 복사하세요" | `ipChanged` |
| `suspectedBlocked` | 요청 0건 && 시작 후 2분 경과 | "Mac에서 이 폰에 닿지 않습니다" + 진단 명령 복사 | `notReachable` |
| `waiting` | 요청 0건 && 2분 미만 | "Mac에서 명령을 실행하세요" | — |

추가 경고(배너와 별개, 칩으로 표시): `vpnActive` → "VPN이 켜져 있으면 연결이 막힐 수 있습니다" → `vpn`.

- 401이라도 요청이 도착했다는 것은 네트워크가 통한다는 증거다. 그래서 `tokenMismatch`와 `suspectedBlocked`를 분리한다.
- 진단은 시계(`now`)와 세션 값만 받는 순수 함수라 단위 테스트로 전 분기를 검증한다.

## 5. HTTP 계층 (`mcp_http_server.dart`)

### 5.1 바인딩

1. `McpPlatform.wifiIpv4()`로 Wi-Fi 네트워크의 IPv4를 얻는다(Kotlin: `ConnectivityManager`에서 `TRANSPORT_WIFI` 네트워크의 `LinkProperties`). 없으면 시작 실패 → "Wi-Fi에 연결하세요".
2. `HttpServer.bind(ip, port)` — `0.0.0.0` 금지. 포트는 **8765**부터 8775까지 차례로 시도, 첫 성공 포트를 쓴다.
3. `server.idleTimeout = 15s`, 요청 본문 읽기 타임아웃 10초.

### 5.2 요청 처리 순서

한 요청은 아래 순서로 검사하며, 처음 걸린 곳에서 응답하고 끝낸다. 모든 요청은 접근 로그에 남긴다.

| 순서 | 검사 | 실패 응답 |
|---|---|---|
| 1 | `Host` 헤더 == `"$ip:$port"` | 403 (DNS rebinding 차단) |
| 2 | `Origin` 헤더 없음 | 403 (브라우저 경유 차단 — Claude Code는 Origin을 보내지 않음) |
| 3 | 경로 == `/mcp` | 404 (`/.well-known/*` 포함 — OAuth 탐색 시도에 404로 "OAuth 없음"을 알림) |
| 4 | `Authorization: Bearer <token>` 상수 시간 비교 | 401 + `WWW-Authenticate: Bearer` → `authFailCount++`, 5회면 `authLockout` 정지 |
| 5 | 메서드: `POST`만 처리, `GET`·`DELETE` | 405 |
| 6 | `Content-Type: application/json`, 본문 ≤ 64KB | 415 / 413 |
| 7 | JSON 파싱 | 400 + JSON-RPC `-32700` |
| 8 | `McpProtocol.handle(json)` | 결과가 `null`(notification)이면 **202**, 아니면 200 + `application/json` |

- 인증(4)을 경로·메서드 검사보다 늦게 두지 않는 이유: 토큰 없는 쪽에 서버 기능 정보를 주지 않기 위해 1~3만 먼저 둔다. 1~3은 정상 클라이언트라면 걸릴 일이 없다.
- 응답에 서버 종류를 드러내는 헤더(`Server` 등)를 넣지 않는다.

## 6. MCP 프로토콜 (`mcp_protocol.dart`)

```dart
class McpProtocol {
  McpProtocol(this.tools, {required this.appVersion});
  /// null이면 응답 없음(notification) → HTTP 202.
  Map<String, Object?>? handle(Object? message);
}
```

| 메서드 | 응답 |
|---|---|
| `initialize` | `protocolVersion`: 클라이언트 요청 버전이 `supportedVersions`에 있으면 그대로, 없으면 우리 최신 버전. `capabilities: {tools: {listChanged: false}}`, `serverInfo: {name: "loop", version: appVersion}`, `instructions`: §6.1 |
| `notifications/*` | `null` (→ 202) |
| `ping` | `{}` |
| `tools/list` | 도구 4개 정의 |
| `tools/call` | `{content: [{type: "text", text}], isError: false}` / 입력 오류·없는 id 등은 `isError: true` + 사람이 읽을 메시지 |
| 그 외 | JSON-RPC 오류 `-32601` |
| 배열(배치) | `-32600` (최신 스펙은 배치 미지원) |

- `supportedVersions`는 상수 목록. **P1 착수 시 최신 MCP 스펙을 확인해 확정**한다(Streamable HTTP를 정의한 `2025-03-26` 이후 버전들).
- 세션 id(`Mcp-Session-Id`)는 발급하지 않는다(무상태).

### 6.1 `instructions` 문구 (영어, LLM 대상)

> Loop is the user's personal journal. Each log has an id, timestamp, content, optional place/weather, and may belong to a chain (an original log and its follow-ups). Use `search_logs` first, then `get_log` or `get_chain` for detail. Dates are in the phone's local time zone.

## 7. 인증·보안

### 7.1 토큰

- `Random.secure()` 32바이트 → base64url(패딩 없음, 43자).
- **영속 토큰** — 첫 ON 때 생성해 설정 `mcp_token`에 저장, 이후 서버를 다시 켜도 같은 토큰. Mac 명령은 한 번만 실행하면 된다(IP가 그대로라면).
- **재발급** — ① 서버 화면 "토큰 재발급" 버튼(확인 다이얼로그: "Mac에서 명령을 다시 실행해야 합니다") ② `authLockout` 시 자동. 재발급하면 `mcp_copied_ip`도 지워 진단이 "명령 다시 복사"로 안내되게 한다.
- 비교는 길이를 먼저 맞춘 상수 시간 비교.
- 저장 위치가 일기와 같은 SQLite인 이유: 토큰이 지키는 대상이 바로 그 DB라, DB를 읽을 수 있는 공격자에겐 토큰이 의미 없다. 별도 보안 저장소(Keystore)는 쓰지 않는다.
- 결정 근거(2026-11-01): 매번 새 토큰이면 30분마다 꺼지는 서버를 쓸 때마다 Mac 명령을 다시 실행해야 한다. 토큰은 같은 Wi-Fi + 서버가 켜진 동안에만 의미가 있어 영속화의 보안 손실이 작다.

### 7.2 위협과 대응 요약

| 위협 | 대응 | 위치 |
|---|---|---|
| 같은 망 다른 기기 | 토큰 | §5.2-4 |
| 무차별 대입 | 5회 실패 → 즉시 정지 + 토큰 재발급 | §5.2-4, §4.2 |
| 토큰 유출(명령 복사본이 남음 등) | "토큰 재발급" 버튼 | §7.1 |
| 브라우저 경유(DNS rebinding) | Host·Origin 검사 | §5.2-1·2 |
| 셀룰러 노출 | Wi-Fi IPv4에만 bind, Wi-Fi 소실 시 정지 | §5.1, §4.2 |
| 방치 | 30분 자동 종료, 상주 알림 | §8 |
| 과다 조회 | 결과 개수·응답 크기 상한 | §9 |
| 위치 노출 | 좌표 미출력, 장소명은 설정 | §9.3 |
| 평문 스니핑 | 1차 수용(집 LAN + 짧은 세션) | 후순위 TLS |

## 8. Android 플랫폼

### 8.1 채널 `app.loop/mcp` (MethodChannel)

| 메서드 | 방향 | 인자 → 반환 | 설명 |
|---|---|---|---|
| `wifiIpv4` | Dart→K | `→ String?` | Wi-Fi 네트워크 IPv4. 없으면 null |
| `isVpnActive` | Dart→K | `→ bool` | 활성 네트워크에 `TRANSPORT_VPN` 여부 |
| `startKeepAlive` | Dart→K | `{ip, port, endsAtMillis}` → `bool` | FGS 시작/알림 갱신 |
| `updateKeepAlive` | Dart→K | `{endsAtMillis}` | 연장 시 알림 갱신 |
| `stopKeepAlive` | Dart→K | `→ void` | FGS 정지 |
| `onStopRequested` | K→Dart | `{reason: "notification" \| "fgsTimeout"}` | 알림 "끄기"·시간 제한 |

### 8.2 채널 `app.loop/mcp_net` (EventChannel)

`NetworkCallback`(Wi-Fi 요청) 이벤트를 흘린다: `{type: "lost"}`, `{type: "ipChanged", ip}`, `{type: "vpn", active}`.
- `lost` → 컨트롤러가 `wifiLost`로 정지.
- `ipChanged` → 같은 토큰으로 **새 IP에 다시 바인딩**(포트 유지 시도), `ipAtCopy`와 비교해 `ipChanged` 진단을 띄운다.

### 8.3 `McpKeepAliveService`

- `foregroundServiceType="dataSync"`, `exported=false`.
- 상주 알림(낮은 중요도 채널 `mcp_server`): "Loop MCP 서버 실행 중 · 192.168.0.12:8765 · 21:40 자동 종료", 액션 **끄기**, 탭하면 서버 화면.
- `WifiManager.WifiLock`(`WIFI_MODE_FULL_HIGH_PERF`) 획득/해제.
- `onTimeout(startId, fgsType)`(API 35) → `McpBridge`로 `onStopRequested(fgsTimeout)` 전달 후 `stopSelf()`.
- 시작은 앱이 포그라운드일 때 사용자 조작으로만. 부팅 시 시작 없음.

### 8.4 매니페스트

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<service
    android:name=".McpKeepAliveService"
    android:exported="false"
    android:foregroundServiceType="dataSync"/>
```

(`INTERNET`·`FOREGROUND_SERVICE`·`POST_NOTIFICATIONS`·`WAKE_LOCK`는 이미 있음. 알림 권한이 거부돼도 서버는 동작하며 알림만 안 보인다.)

### 8.5 `MainActivity`

- `configureFlutterEngine`: `McpBridge.register(flutterEngine, context)`.
- `cleanUpFlutterEngine`: `McpBridge.unregister()` + 서비스 정지.

## 9. 도구 (`mcp_tools.dart`)

### 9.1 정의

| 도구 | 입력 스키마 | 반환 |
|---|---|---|
| `search_logs` | `query: string`(필수, 1~200자), `limit: integer`(기본 20, 1~50), `from`/`to: string`(YYYY-MM-DD, 포함 범위, 선택), `order: "recent"\|"relevance"`(기본 recent) | 결과 목록(스니펫) |
| `get_log` | `id: string` | 로그 1건 전문 + 메타 |
| `get_chain` | `id: string` (사슬 안 아무 로그) | 사슬 전체, 시간순 |
| `logs_on_day` | `date: string`(YYYY-MM-DD) | 그날 로그 전부(최대 50, 넘으면 잘림 안내) |

입력 검증 실패는 JSON-RPC 오류가 아니라 `isError: true` 결과로 돌려준다(LLM이 읽고 고쳐 다시 부르도록).

### 9.2 LoopDb 변경 (스키마 변경 없음)

| 메서드 | 변경 |
|---|---|
| `searchDetailed` | `DateTime? from, DateTime? to` 인자 추가. FTS·LIKE 두 경로 모두 `created_at >= ? AND created_at < ?` 조건 추가(`to`는 다음날 0시로 변환) |
| `chainLogs(String id)` **신규** | `root = log.rootId ?? log.id` → `WHERE id = ? OR path LIKE 'root/%' ORDER BY created_at, id` (`chainStats`와 같은 조건 재사용) |
| `mediaCounts(List<String> ids)` **신규** | `log_images`·`log_videos` `COUNT … GROUP BY log_id` — 바이트를 읽는 `imagesFor` 대신 |
| `logsOnDay`, `byId` | 그대로 사용 |

### 9.3 출력 포맷

```
[01JCXK…] 2026-10-31 (금) 21:14 · 성수동 · 맑음 12°C · 사진 2
사슬 01JA…의 3번째 · 루프 예약 11-03 09:00
본문 전문 또는 스니펫(**매치**)
```

- 좌표(`latitude`/`longitude`)는 **항상** 출력하지 않는다. 장소명은 설정 `mcp_include_place`가 켜져 있을 때만.
- 날씨 코드는 영어 짧은 설명으로 변환(`clear`, `rain` …) — LLM이 읽기 쉽게, 앱 언어와 무관.
- 스니펫 마커 ``/`` → `**`.
- 받은 사슬(`chain_shares`에 있는 root)은 `(received chain)` 표시만, 상대 기기 정보는 출력하지 않는다.
- 응답 텍스트 총 20,000자 상한. 넘으면 그 지점에서 자르고 마지막 줄에 `…truncated — narrow the date range or lower limit`.

## 10. 설정 키 (`settings` 테이블)

| 키 | 값 | 기본 |
|---|---|---|
| `mcp_auto_stop_min` | `15` \| `30` \| `60` | `30` |
| `mcp_include_place` | `1` \| `0` | `1` |
| `mcp_consent_at` | 동의 시각(ms) | 없음 → 첫 ON 때 동의 다이얼로그 |
| `mcp_token` | base64url 43자 | 없음 → 첫 ON 때 생성 |
| `mcp_copied_ip` | 마지막 명령 복사 시점 IP | 없음 / 재발급 시 삭제 |

접근 로그는 저장하지 않는다(메모리).

## 11. UI

### 11.1 설정 시트 항목 (Android만)

`Mac에서 검색 (MCP)` · 부제: `꺼짐` / `실행 중 · 18분 남음` → 탭하면 서버 화면.

### 11.2 서버 화면

```
┌─────────────────────────────────────┐
│ ← Mac에서 검색                        │
│                                     │
│ [■■■ ON ]   남은 시간 18:42  [+15분]   │
│                                     │
│ ┌ 진단 배너 ─────────────────────────┐ │
│ │ ⚠ Mac에서 이 폰에 닿지 않습니다      │ │
│ │ [진단 명령 복사]       자세히 보기 › │ │
│ └───────────────────────────────────┘ │
│ (칩) VPN이 켜져 있으면… ›               │
│                                     │
│ 연결 정보                             │
│  주소   http://192.168.0.12:8765/mcp  │
│  토큰   ••••••••••  [보기] [복사]      │
│         토큰 재발급 ›                  │
│  [ Claude Code 연결 명령 복사 ]         │
│                                     │
│ 옵션                                 │
│  자동 종료        30분 ▾              │
│  장소명 포함       [ON]               │
│                                     │
│ 접근 기록                             │
│  21:12  search_logs "성수동 카페"  ✓   │
│  21:11  (토큰 오류)               ✕   │
│                                     │
│ 연결 도움말 ›                          │
└─────────────────────────────────────┘
```

- **ON 흐름**: (첫 사용) 동의 다이얼로그 — "검색 결과가 Mac에서 쓰는 AI 서비스로 전송될 수 있습니다" → 매번 공용 Wi-Fi 경고 다이얼로그 → `starting` → `running`.
- **연결 명령**(복사 시 `ipAtCopy` 기록):
  ```
  claude mcp remove loop -s user 2>/dev/null; claude mcp add --transport http -s user loop http://192.168.0.12:8765/mcp --header "Authorization: Bearer <token>"
  ```
  `-s user` — 모든 프로젝트에서 쓰도록 사용자 범위로 등록(기본 local 범위는 현재 폴더에서만 보임). 기존 등록을 먼저 지워 재실행해도 안전.
- 서버가 꺼져 있을 때 연결 정보·접근 기록 영역은 숨기고, 마지막 정지 사유 배너(§4.2)만 보인다.

### 11.3 Mac 진단 명령

`mcp_diagnosis.dart`가 IP·포트를 채워 생성. 진단 배너·FAQ 상단의 "진단 명령 복사"로 제공. 각 출력 끝에 FAQ 항목명(`→ 앱 연결 도움말 > AP 격리`)을 붙이고, 문구는 복사 시점 앱 언어로 생성한다. 전체를 서브셸 `( … )`로 감싼다 — 대화형 터미널에 붙여넣어도 `exit`가 사용자 셸이 아니라 서브셸만 끝낸다. 아래는 한국어 기준 원형(2026-11-01 이 Mac에서 포트 거부·대역 다름·도달 불가·정상 4분기 실행 확인).

```bash
(
P=192.168.0.12; PORT=8765
R=$(route -n get "$P" 2>/dev/null)
if echo "$R" | grep -q 'interface: utun'; then echo "❌ Mac VPN이 내부망 트래픽을 가로챕니다 — VPN을 끄거나 LAN 예외를 켜세요"; exit 0; fi
if echo "$R" | grep -q 'gateway:'; then echo "❌ 폰과 Mac이 다른 네트워크 대역입니다 — 같은 Wi-Fi인지, 공유기가 두 대(이중 NAT)인지 확인하세요"; exit 0; fi
T=$(nc -vz -G 3 "$P" "$PORT" 2>&1)
case "$T" in
  *succeeded*) echo "✅ 네트워크 정상 — 폰에 닿습니다. 토큰/명령을 확인하세요";;
  *refused*)   echo "❌ 폰엔 닿지만 포트가 닫혀 있습니다 — 서버가 켜져 있는지, 그 IP가 정말 이 폰인지 확인하세요";;
  *)
    GW=$(route -n get default | awk '/gateway/{print $2}')
    G=$(nc -vz -G 2 "$GW" 80 2>&1)
    case "$G" in
      *succeeded*|*refused*) echo "❌ 공유기엔 닿는데 폰엔 안 닿습니다 — AP 격리(게스트/공용 Wi-Fi의 기기 간 통신 차단) 의심, 또는 폰 IP가 바뀌었는지 확인";;
      *) echo "❌ Mac이 내부망 자체에 못 나갑니다 — 시스템 설정 > 개인정보 보호 및 보안 > 로컬 네트워크에서 터미널 앱 허용(macOS 15+), 또는 방화벽·보안 앱 확인";;
    esac;;
esac
)
```

| 판정 근거 | 분류 |
|---|---|
| `route get` 경로가 `utun` | Mac VPN이 가로챔 |
| `route get`에 `gateway:` 있음 (직접 연결 대역이 아님) | **대역 다름** (다른 Wi-Fi·이중 NAT) |
| `nc` 연결 성공 | 네트워크 정상 |
| `Connection refused` | 폰 도달·포트 닫힘 (서버 꺼짐 / IP가 다른 기기) |
| `Operation timed out`·`No route to host` + **공유기는 도달** | **AP 격리** 의심 (또는 그 IP에 폰이 없음) |
| 같은 실패 + **공유기도 불가** | **Mac 쪽 차단** (로컬 네트워크 권한·방화벽·보안 앱) |

- TCP 판별에 `curl` 대신 `nc -v`를 쓰는 이유: macOS `curl`은 거부·타임아웃·경로 없음을 모두 `(7) Couldn't connect to server`로 뭉뚱그려 원인 구분이 안 됨. `nc -v`는 OS 오류 문구(`Connection refused`/`Operation timed out`)를 그대로 보여준다. (2026-11-01 macOS 26에서 확인)

- 확정이 아니라 **추정** — 메시지는 "의심/확인하세요" 어조. 공유기가 80 포트를 DROP하는 드문 경우 Mac 차단으로 오판 가능.
- 폰 쪽 방화벽은 Android 기본엔 없음 → 폰 VPN/보안 앱만 ①에서 경고.
- macOS 15+ 로컬 네트워크 권한은 터미널 앱(Terminal·iTerm·VS Code 등) 단위로 걸린다 — Claude Code 첫 연결 때 허용 팝업을 놓치면 이후 조용히 실패.

| 분류 | FAQ |
|---|---|
| Mac VPN | `vpn` |
| 대역 다름 | `differentSubnet` |
| 네트워크 정상 | `token` |
| 포트 닫힘 | `portClosed` |
| AP 격리 의심 | `apIsolation` |
| Mac 쪽 차단 | `macBlocked` |

### 11.4 연결 FAQ 화면

- `McpFaqScreen({McpFaq? initialItem})` — `initialItem`이 있으면 그 항목을 펼치고 그 위치로 스크롤.
- 맨 위: Mac 진단 명령 카드(복사 버튼). 서버가 꺼져 있으면 마지막 IP·포트로 채우고, 없으면 자리표시자.
- 항목(접이식, 질문 → 증상 / 원인 / 해결):

| `McpFaq` | 질문 |
|---|---|
| `notReachable` | Mac에서 연결이 안 돼요 |
| `apIsolation` | 게스트·공용 Wi-Fi에서는 안 돼요 |
| `differentSubnet` | 같은 Wi-Fi인데도 안 돼요 |
| `macBlocked` | Mac 권한·방화벽 (시스템 설정 > 개인정보 보호 및 보안 > 로컬 네트워크) |
| `vpn` | VPN을 켜면 안 돼요 |
| `ipChanged` | 폰 주소가 자꾸 바뀌어요 (DHCP 예약 + "기기 MAC 사용") |
| `portClosed` | 포트가 닫혀 있대요 |
| `token` | 토큰이 다르대요 |
| `autoStop` | 서버가 저절로 꺼져요 |
| `safety` | 안전한가요? |

### 11.5 l10n

키 접두사 `mcp`로 `lib/l10n/`의 8개 언어(ko 템플릿 + en/es/hi/it/ja/vi/zh) 추가. 묶음: 설정 항목·서버 화면 라벨, 동의·경고 다이얼로그, 정지 사유 5종, 진단 배너 5종 + VPN 칩, FAQ 10항목(질문·본문). 진단 스크립트의 출력 문구는 Mac 터미널용이라 **앱 언어로 생성**(복사 시점 locale). `test/locales_test.dart`가 누락을 잡는다.

## 12. 테스트

| 파일 | 대상 |
|---|---|
| `test/mcp_protocol_test.dart` | initialize 버전 협상, notification → null, 없는 메서드 -32601, 배치 -32600, tools/call 오류 → isError |
| `test/mcp_tools_test.dart` | 입력 검증, 날짜 필터, 좌표 미출력, 장소명 설정 반영, 스니펫 마커 치환, 20k자 잘림 |
| `test/loop_db_test.dart` (추가) | `searchDetailed` from/to (FTS·LIKE 양쪽), `chainLogs`, `mediaCounts` |
| `test/mcp_http_server_test.dart` | 실제 `HttpServer`(127.0.0.1)로 Host/Origin 403, 404, 401·5회 잠금, 405, 413/415, 202, 정상 200 |
| `test/mcp_diagnosis_test.dart` | 진단 우선순위 전 분기(가짜 시계), 스크립트에 IP·포트 삽입 |
| `test/mcp_controller_test.dart` | 자동 종료·연장, 정지 사유 전이, ipChanged 재바인딩(가짜 플랫폼), 토큰 영속(재시작 후 동일)·수동 재발급·잠금 시 자동 재발급 + `mcp_copied_ip` 삭제 |
| `test/mcp_faq_screen_test.dart` | `initialItem` 펼침, 진단 배너 "자세히 보기" → 맞는 항목 |
| 수동 | 실기기 + Mac Claude Code: 검색 흐름, 화면 끔 30분 유지, 알림 끄기, Wi-Fi 끊기, 진단 명령 6분기 |

컨트롤러·진단은 시계(`DateTime Function() now`)와 플랫폼(`McpPlatform` 인터페이스)을 주입받아 기기 없이 테스트한다.

## 13. 결정 이력

| 일자 | 항목 | 결정 |
|---|---|---|
| 2026-11-01 | 토큰 수명 | 매번 새 토큰 → **영속 토큰 + 수동/잠금 시 재발급** (§7.1) |
