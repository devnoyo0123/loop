# 사슬 공유 설계 — P2P (1안) 확정안

> 결정 일자: 2026-11-01 · 대화에서 확정한 결정 전부를 모은 스펙.
> 개발 순서: 페이로드·스키마(폰 없이 테스트) → UI → 전송 계층(실기기 테스트는 마지막).

## 0. 원칙

- **로컬 퍼스트 유지** — 공유 데이터는 기기에서 기기로 직접. 서버 없음(2안 E2EE 릴레이는 별도 미래 계획).
- **페이로드 = 사슬 스코프의 .looplog** — 기존 JSONL 포맷 확장. 머지 규칙은 기존과 동일("같은 id skip").
- **의도적으로 뺀 것은 크게, 없는 것은 조용히** — 미리보기 표시 규칙.

## 1. 공유 단위와 정책

| 항목 | 결정 |
|---|---|
| 단위 | 사슬 1개(원본 + 줄기 + 발화 포크 전체). `path` 계보라 완전한 세트로만 이동. **모든 기록의 ⋯ › "Loop 공유"** — 혼자인 기록·막 건 루프(발화 전)는 원본 1개짜리 사슬, 포크에서 누르면 원본 기준 전체 (2026-11-01) |
| 반복 규칙 | 내보낼 때 원본 active 상태 그대로 실리고, **강제는 받는 쪽 정책 한 곳**(`LoopDb.ruleForReceive`) — 비이어받기면 살아있던 규칙도 무조건 정지 상태로 수입(catch-up 홍수 방지). 단일 강제 지점이라 변조 페이로드에도 안전 |
| "이어받기" | 받는 쪽이 선택 시 규칙을 `active=1`로 부활. **`next_fire_at`은 받는 시점 기준 재계산** — 주기는 물려받고 시계는 새로. `fire_count`·기존 포크는 그대로. 애초에 정지였던 규칙은 이어받기를 골라도 정지 유지 |
| 미디어 | **기본 포함**(base64 인라인 — Wi-Fi Direct 수십 MB/s라 수십 초). "미디어 빼고 보내기" 토글 시 미디어 라인 자체를 미포함(메타만 보내서 유령 흔적을 남기지 않음) |
| 위치 | "위치 정보 빼고 보내기" **기본 ON** — latitude/longitude/place 제거, 날씨는 유지 |
| 표시 규칙 | 원래 없는 항목은 요약에서 생략, 의도적으로 뺀 항목만 배지("위치 정보 없이 전송됨") |
| 영상 상한 | 1분 (카메라 인텐트 EXTRA_DURATION_LIMIT + mp4 mvhd 재검증 — v11 이전 구현 완료) |

## 2. 정체성 — 기기 식별자

- **ULID를 앱이 직접 생성**, `settings` 테이블에 저장. OS 식별자(ANDROID_ID 등) 미사용 — 이름과 무관, 권한·의존성 불필요.
- **생성 시점: 첫 공유** — 한 번도 공유 안 한 설치본엔 식별자가 존재하지 않음.
- `share_name`(표시명)은 자기 선언, 기본값 기기명, 언제든 변경. id는 불변, 이름은 peers에서 upsert.
- 재설치 = 새 ULID(새 정체성). 로컬 퍼스트 앱에 바람직한 성질 — 추적 불가.

## 3. 스키마 v11

```sql
CREATE TABLE IF NOT EXISTS peers (
  id         TEXT PRIMARY KEY,   -- 상대 기기 식별자 (랜덤 ULID)
  name       TEXT NOT NULL,
  first_seen INTEGER NOT NULL,
  last_seen  INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS chain_shares (
  root_id     TEXT PRIMARY KEY,  -- logs.root_id — 사슬당 출처 1개(첫 수신 유지)
  peer_id     TEXT NOT NULL,     -- 직접 보낸 사람
  received_at INTEGER NOT NULL,
  via         TEXT NOT NULL      -- 'p2p' | 'file'
);
-- logs에 컬럼 추가: author_id TEXT (null = 내가 씀 / 받은 기록은 peers.id)
```

- 3단계 전파(민수→지민→나): `author_id`가 기록과 함께 이동해 다단계 저자 구분. `chain_shares`는 직접 출처만.
- 마이그레이션: 기존 전략(없는 테이블 생성 + 없는 컬럼만 ALTER). 기존 로그는 author_id=null이므로 손댈 필요 없음.

## 4. 페이로드 형식 (.looplog 확장)

```
{"type":"looplog","version":1,"exportedAt":"…",
 "participants":[{"id":"01J..","name":"민수"},{"id":"01K..","name":"지민"}]}
{"type":"log", …, "authorId":"01J.."}        ← null(본인) 작이면 필드 생략
{"type":"image"|"video"|"repeat", …}          ← repeat는 원본 상태 그대로(강제는 수신 측)
```

- `participants`: 체인에 관련된 모든 기기(본인 + peers에 남은 이전 보낸 사람). 3단계 이상에서도 이름이 살아 있게.
- 헤더에 participants가 없는 구버전 파일 → 전부 "나" 취급(기존 백업은 내 기록뿐).
- 임포트: participants → peers upsert → author 미지정 로그는 헤더 sender로 스탬프 → `chain_shares` 기록.

## 5. UI (docs/mockups/share-p2p-*.png 확정안)

1. **보내기 시트** — 사슬 요약 카운트(기록·사진·동영상·반복), 위치 제외(ON)/미디어 제외(OFF) 토글, [가까운 기기로 보내기], [파일로 내보내기]
2. **전송** — 기기 발견·연결, 큰 % 진행, "인터넷·서버를 거치지 않아요" 힌트
3. **받기 시트** — 요약 + 배지(뺀 것만), [이 기록만 가져오기] vs [살아있는 루프로 이어받기](기본 선택), [가져오기]/[거절]
4. **완료** — 가져온 사슬 카드 + 🔁 다음 발화(재계산된 시각)

## 6. 전송 계층

- Android **Nearby Connections**(Google Play Services): BLE 탐색 → Wi-Fi Direct 전송. 서버·계정 없음.
- 페이로드는 임시 .looplog 파일로 만들어 **STREAM 페이로드**로 전송(메모리 안전, 받는 쪽이 앱 폴더에 직접 씀 — §6.6).
- 경로: BLE로 찾고 BT로 연결한 뒤, 라이브러리가 가능하면 **Wi-Fi Direct로 대역폭 승격**(`P2P_STAR`). 공유기·인터넷 불필요, 두 폰 모두 Wi-Fi만 켜져 있으면 된다.
- 개발 워크플로: **폰 없이 개발**(페이로드·상태머신은 단위 테스트) → 완료 후 실기기 2대로 전파 테스트.

### 6.1 구조 — 구현과 인터페이스 분리

| 계층 | 파일 | 테스트 |
|---|---|---|
| 인터페이스 | `services/nearby_transport.dart`(`NearbyTransport`), `services/share_platform.dart`(`SharePlatform`) | — |
| 앱 로직 | `services/nearby_share.dart` — `ShareSendController`(보내기 상태 머신), `ShareReceiver`(받기 대기) | `test/nearby_share_test.dart` (가짜 전송 계층) |
| 화면 | `screens/share_sheet.dart`(`ShareTransferScreen`), `screens/settings_sheet.dart`(받기 스위치) | `test/share_transfer_test.dart` |
| 실제 구현 (Dart) | `services/native_nearby_transport.dart` — 프로토콜·완료 판정·미완성 삭제, `DeviceSharePlatform`(permission_handler + `app.loop/browser#deviceInfo`) | `test/native_nearby_transport_test.dart` (채널 목) |
| 번역층 (Kotlin) | `NearbyBridge.kt` — Nearby ↔ 채널, `ShareStreamWriter.kt` — STREAM → 파일 | `android/app/src/test/.../NearbyBridgeTest.kt`, `ShareStreamWriterTest.kt` (JVM, `./gradlew :app:testDebugUnitTest`) |
| 전파 | Google Play 서비스 Nearby Connections | 실기기 2대 |

- 이전 연결 시도의 늦은 결과는 엔드포인트 id로 걸러낸다(포기 뒤 늦게 붙으면 정리).
- 권한 요청 결과는 믿지 않고 상태를 다시 확인 — 위치 요청 결과가 COARSE 기준이라 Android 12 "대략적 위치"가 granted로 온다.

- 실제 구현은 `NearbyShareDefaults`에서 **하나만** 꽂힌다 — 플러그인의 페이로드 콜백이 전역이라, 디스패처가 엔드포인트별로 보내기/받기에 라우팅한다.
- 테스트 가짜: `test/support/fake_nearby.dart` (`FakeTransport`, `FakeSharePlatform`). 청소 로직은 `test/share_files_test.dart`.
- 계약: Kotlin이 내보내는 이벤트 맵 형식(`e`: found/lost/initiated/result/disconnected/bytes/stream/streamDone/update)은 `NearbyBridgeTest`(Kotlin)와 `native_nearby_transport_test`(Dart)가 양쪽에서 고정한다.

### 6.2 권한 — API 레벨별 (`requiredSharePermissions`)

| API | 런타임 요청 |
|---|---|
| 33+ | BLUETOOTH_SCAN/ADVERTISE/CONNECT + NEARBY_WIFI_DEVICES (위치 불필요) |
| 31–32 | BLUETOOTH 3종 + 위치 |
| ≤30 | 위치 |

- 매니페스트 선언은 앱 `AndroidManifest.xml`에 직접(플러그인 제거 후). 런타임 권한은 공식 문서의 min/maxSdk 그대로, **일반 권한 4개(WIFI_STATE·BLUETOOTH 계열)는 maxSdk 없음** — 문서 표(32/30)와 달리 Play 서비스가 API 35에서도 ACCESS_WIFI_STATE를 요구해 광고가 거부됐다(2026-11-01 에뮬레이터 확인).
- NEARBY_WIFI_DEVICES를 32 이하에서 요청하면 permission_handler가 denied → 무조건 넣으면 구형 폰 공유가 막힌다.
- ACCESS_LOCAL_NETWORK(37+)는 targetSdk 37 앱만 해당 — 현재 targetSdk 36이라 제외. 올리면 추가할 것.

### 6.3 받기 대기 정책

- 앱 시작: 권한이 **이미** 있고 사용자가 끄지 않았으면 조용히 광고(팝업 없음).
- 설정 › **가까운 기기에서 받기** 스위치: 켜면 그때 권한 요청 → 대기. 끄면 `settings.share_receive='0'` 저장, 다음 실행에도 자동 대기 안 함.
- 들어오는 연결은 자동 수락, 가져올지는 받기 시트에서 사용자가 결정. 파일을 옮긴 뒤 받는 쪽이 연결을 끊는다.
- **받는 중 알림**(`IncomingShareNotice`): 어느 화면에서든 하단 스낵바로 "지민님이 보내는 중 · 42%", 중단되면 "지민님의 전송이 중단됐어요". 완료되면 치우고 받기 시트가 이어서 뜬다. 상태는 `ShareReceiver.incoming`.
- **받는 쪽 멈춤 감지**: 60초 동안 바이트가 안 늘면 이쪽에서 그 연결을 끊고 실패 처리(미완성 파일 삭제).

### 6.4 보내기 흐름

- 권한 → 탐색 → **발견 목록에서 탭해서 선택**(한 대여도 자동 연결 안 함 — 엉뚱한 사람에게 가는 것 방지) → 연결 → 파일 전송.
- 완료 판정: 내 쪽 SUCCESS 후 **받는 쪽이 끊으면** 완료(상한 5초 뒤엔 내가 끊고 완료) — 바로 끊으면 상대의 마지막 바이트가 잘릴 수 있다.
- 정리는 그 기기만 `disconnectFromEndpoint` — `stopAllEndpoints`는 광고까지 멈춰 받기 대기가 꺼진다.
- 표시명이 비었으면 기기 이름(Settings.Global.DEVICE_NAME → Build.MODEL)을 쓴다.
- 기기가 하나도 안 보이면 60초 뒤 "찾지 못함" + 받는 쪽 안내, [다시 찾기].
- **멈춤 감지(전체 시간 상한 없음)**: 60초 동안 바이트가 안 늘면 `stalled` 실패 + "가까이 두고 다시" 안내. 블루투스로 느리게라도 계속 가면 끝까지 보낸다(이전의 10분 고정 상한은 큰 사슬을 진행 중에 끊었다).
- **속도·남은 시간**: "3.2 MB / 12 MB · 0.2 MB/s · 약 45초 남음" (최근 3초 창). 4초 넘게 1 MB/s 미만이고 20초 넘게 남았으면 블루투스 경로로 보고 "취소하고 양쪽 Wi-Fi를 켠 뒤 다시" 안내.
- **이어받기 없음**: 중단 후 다시 보내면 0%부터. Nearby 파일 전송은 이어받기를 지원하지 않는다. 연결 중 Wi-Fi를 켜도 대역폭 승격이 다시 일어나는지는 미확인(실기기 항목) — 그래서 안내는 "취소 → Wi-Fi → 다시".

### 6.5 공유 파일 수명 — 쓰레기를 남기지 않는다 (`services/share_files.dart`)

공유 파일은 전부 **앱 캐시의 전용 폴더 `share/`** 하나에만 생긴다. 공용 폴더(Downloads)는 쓰지 않는다.

| 파일 | 즉시 삭제 |
|---|---|
| `loop-chain-*.looplog` 보내는 쪽 페이로드 | 전송 화면이 닫힐 때 |
| `in-<ep>-<pid>.part` 받는 중(미완성) | 실패·취소·중간 끊김·크기 불일치·쓰기 실패·멈춤 감지·받기 끄기 |
| `in-<ep>-<pid>.looplog` 다 받은 것 | 받기 시트가 어떻게 닫히든(가져오기·거절·바깥 탭·실패) |

- **주기 청소 `ShareJanitor`**: 앱 시작 1회 · 앱 복귀(resume) · 세션 종료(전송 화면·받기 시트 닫힘, 받기 실패) · 켜져 있는 동안 30분마다. 쓰는 중(hold)이 아니고 10분 넘은 파일. 나이 조건은 만들자마자 hold 전에 지우는 경쟁을 막는다. 겹쳐 불려도 한 번만 돈다.
- **수동 정리**: 설정 › 데이터 › "공유 임시 파일 정리 · 12.3 MB" — 확인 후 쓰는 중만 남기고 나이와 무관하게 전부.
- 앱 삭제 시 캐시와 함께 사라진다.

### 6.6 왜 플러그인(FILE)이 아니라 직접 연동(STREAM)인가 (2026-11-01 결정)

- `nearby_connections` Flutter 플러그인(개인 관리, 마지막 릴리스 20개월 전)은 BYTES·FILE만 지원. **FILE 페이로드는 Play 서비스가 공용 Downloads에 쓰고 앱이 위치를 못 정한다** → 일기 내용이 공용 폴더에 놓이고(≤9는 저장소 권한 앱이 읽을 수 있음), 미완성 파일은 URI를 알 때만 회수 가능.
- 플러그인 우회 4건(메인 스레드 1KB 복사 ANR 위험, 전역 콜백 덮어쓰기, IOException만 처리, ≤9 file:// 처리)도 함께 사라진다.
- **STREAM**: 받는 쪽 Kotlin이 InputStream을 바로 `share/*.part`로 흘려 쓴다(64KB 버퍼, 백그라운드 스레드). STREAM은 전체 크기를 안 알려줘(total=-1) 보내는 쪽이 먼저 BYTES 헤더 `{"loop":"chain","v":1,"size":N}`를 보낸다 — 진행률 + 잘림 검사.
- **완료 판정(받는 쪽, Dart)**: Nearby SUCCESS ∧ 파일 쓰기 성공 ∧ 바이트 = 헤더 크기 (순서 무관) → `.part` → `.looplog` 후 받는 쪽이 끊는다.
- **유지보수 원칙**: Kotlin은 번역만(판단 없음), 판단은 Dart. 페이로드 id는 음수일 수 있는 임의 64비트 — 실패 표식은 `null`(−1 금지).
- 남는 검증 공백: Nearby 콜백 객체에서 필드를 꺼내는 한 줄 어댑터와 실제 전파 — 실기기.

## 7. 의도적 한계 (v1)

- `chain_shares`는 사슬당 출처 1개(첫 수신 유지). 전달 경로 전체 이력은 author_id로 간접 복원.
- 표시명은 자기 선언(위조 가능) — 위협 모델은 "친구끼리 기록 출처 구분".
- iOS 전송은 미포함(Android 우선). E2EE 릴레이(2안)는 원격 수요 확인 후 별도 설계.
