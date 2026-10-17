# Loop 데이터 모델 v4 (확정)

> 결정 일자: 2026-08-31 · v2: 위치·날씨 캡처 / v3: 이미지 첨부 / v4: 반복 규칙

## 설계 원칙

1. **순수 시계열** — 섹션/폴더 없음. 로그는 쓰인 시각 순서로만 존재
2. **로컬 퍼스트** — 내부 저장은 SQLite, 교환은 JSONL 파일
3. **계보 보존** — 포크(루프) 구조는 id 기반이라 시간 수정과 독립적
4. **윈도우 리딩** — 앵커 기반 keyset 페이징으로 화면 주변 ~500개만 읽음

## 스키마 (SQLite)

```sql
CREATE TABLE logs (
  id                  TEXT PRIMARY KEY,  -- ULID류 (시각 정렬 가능한 ID)
  content             TEXT NOT NULL,
  created_at          INTEGER NOT NULL,  -- epoch millis (수정 가능)
  original_created_at INTEGER NOT NULL,  -- 최초 생성 시각 (불변)
  parent_id           TEXT,              -- 바로 위 부모 (인접 리스트)
  root_id             TEXT,              -- 계보의 시작점 (최초 원본, 원본이면 NULL)
  depth               INTEGER DEFAULT 0, -- 포크 깊이 (원본=0)
  path                TEXT,              -- Materialized Path: "원본id/자식id/손자id"
  loop_at             INTEGER,           -- 예약된 알림(루프) 시각
  loop_done           INTEGER DEFAULT 0, -- 루프 소화 여부
  -- v2: 저장 순간의 맥락 (전부 nullable — 캡처 실패해도 로그는 저장됨)
  latitude            REAL,              -- 위도
  longitude           REAL,              -- 경도
  place               TEXT,              -- 역지오코딩 장소명 ("서울특별시 성동구")
  weather_code        INTEGER,           -- WMO 코드 (0=맑음, 61=비, 95=뇌우…)
  temperature_c       REAL,              -- 기온 ℃
  -- v4: 반복 발화로 자동 생성된 포크만 값이 있다
  repeat_rule_id      TEXT               -- 생성한 repeat_rules.id
);

CREATE INDEX idx_created_at ON logs(created_at, id);  -- 시계열 윈도우 리딩
CREATE INDEX idx_parent     ON logs(parent_id);       -- 직계 자식 조회
CREATE INDEX idx_path       ON logs(path);            -- LIKE 'prefix%' 전방검색
CREATE INDEX idx_repeat     ON logs(repeat_rule_id);  -- 반복 발화 로그 조회

-- v4: 반복 규칙
CREATE TABLE repeat_rules (
  id            TEXT PRIMARY KEY,
  source_log_id TEXT NOT NULL,       -- 반복의 원본 로그
  kind          TEXT NOT NULL,       -- 'minutes' | 'hours' | 'daily' | 'weekday'
  every_n       INTEGER,             -- minutes/hours 주기값
  time_of_day   TEXT,                -- daily/weekday 발화 시각 "HH:mm"
  next_fire_at  INTEGER NOT NULL,    -- 다음 발화 예정 시각
  fire_count    INTEGER DEFAULT 0,   -- 지금까지 발화 횟수
  active        INTEGER DEFAULT 1,   -- stop하면 0 (기록은 남음)
  created_at    INTEGER NOT NULL,
  stopped_at    INTEGER
);

CREATE INDEX idx_repeat_active ON repeat_rules(active, next_fire_at);
CREATE INDEX idx_repeat_source ON repeat_rules(source_log_id);
```

### 마이그레이션 전략 (구현됨)

`open()` 순서가 중요: **테이블 없으면 생성 → 컬럼 비교해서 없는 것만 ALTER TABLE ADD → 인덱스 생성.**
인덱스를 먼저 만들면 옛날 테이블에 새 컬럼 인덱스가 터진다. 전체 컬럼 집합(`_columns` 맵)을
데이터로 관리하므로 어떤 구버전 DB든 열면 자동으로 최신 스키마로 승격된다.

## 이미지 첨부 (v3)

```sql
CREATE TABLE log_images (
  id       TEXT PRIMARY KEY,
  log_id   TEXT NOT NULL,
  position INTEGER NOT NULL,   -- 로그 안의 순서
  base64   TEXT NOT NULL      -- 긴 변 1080px JPEG q80 (장당 ~200KB)
);
CREATE INDEX idx_log_images ON log_images(log_id, position);
```

**설계 결정**: 이미지는 *개념상* 로그의 일부(같은 로그 id, 같은 시계열 위치, 익스포트 시 인라인)지만
*물리적으로만* 자식 테이블에 둔다. logs 본문에 base64를 넣으면 이미지 로그 하나가 수백 KB가 되어
윈도우 쿼리(`SELECT *`)가 무거워져 "스크롤 시 화면에 3~4장" 성능 목표와 충돌하기 때문.

**읽기 패턴**:
| 용도 | 쿼리 | 시점 |
|---|---|---|
| 카드 인디케이터 + 이미지 전용 로그 썸네일 | `log_id IN (윈도우 ids)` GROUP BY + position=0 | 윈도우 로딩 시 배치 |
| 상세(탭 확장) 전체 이미지 | `WHERE log_id = ? ORDER BY position` | 펼치는 순간 |
| 카드 썸네일 렌더링 | 같은 base64 + `Image.memory(cacheWidth: 320)` | 디코딩 시 엔진이 축소 |

**압축**: 원본 그대로 base64는 +33% 부피(사진 한 장 = 수 MB). 저장 전 `flutter_image_compress`로
긴 변 1080px JPEG q80 통일. 제한: 로그당 최대 10장, 작성 시트에서만 첨부.
**삭제 연쇄**: 로그 삭제 시 log_images도 함께 삭제 (트랜잭션).

## 포크(루프) 계보 연산

| 기능 | 쿼리 |
|---|---|
| 이 로그에서 직계 포크 수 | `SELECT COUNT(*) FROM logs WHERE parent_id = :id` |
| 파생 전체 (손자 포함) | `SELECT * FROM logs WHERE path LIKE :id \|\| '/%' ORDER BY depth` |
| 계보(조상 목록) | path 파싱 — `"A/B/E"` → A → B → E (조인/재귀 불필요) |
| 가장 많이 퍼진 원본 | `SELECT root_id, COUNT(*) FROM logs WHERE root_id IS NOT NULL GROUP BY root_id ORDER BY 2 DESC` |

**포크 생성 규칙**: 부모의 `root_id`/`depth+1`/`path = 부모path + '/' + 내id` 그대로 파생. 조상은 절대 변경되지 않으므로 path 재계산 불필요.

## 윈도우 리딩 (keyset 페이징)

```sql
-- 앵커 기준 아래로 500개
SELECT * FROM logs WHERE (created_at, id) < (:anchorTime, :anchorId)
  ORDER BY created_at DESC, id DESC LIMIT 500;
```

OFFSET 미사용 → 로그가 백만 개여도 스크롤 읽기 속도 일정.

## 시간 수정

- `UPDATE logs SET created_at = ?` 후 목록 재쿼리 → 시계열 위치 자동 재정렬
- `original_created_at`은 불변 — 원래 언제 적었는지 항상 보존
- 계보(id 기반)에는 영향 없음

## 익스포트 형식: `.looplog` (JSONL v1)

한 줄 = 한 로그. `created_at ASC, id ASC` 정렬 보장.

```
{"v":1,"id":"01JAK5...","content":"새벽에 떠오른 생각","createdAt":"2026-08-31T01:12:00Z","originalCreatedAt":"2026-08-31T01:12:00Z","parentId":null,"rootId":null,"depth":0,"path":null,"loopAt":"2026-08-31T01:22:00Z","loopDone":true}
{"v":1,"id":"01JAK6...","content":"아침에 다시 보니 정리됨","createdAt":"2026-08-31T08:30:00Z","originalCreatedAt":"2026-08-31T08:30:00Z","parentId":"01JAK5...","rootId":"01JAK5...","depth":1,"path":"01JAK5...","loopAt":null,"loopDone":false}
```

- 임포트는 id 기준 upsert → 여러 파일 병합/복구 가능
- 사람이 읽을 수 있고, grep/diff 가능

## 저장소 이중 구조

| 역할 | 파일 | 이유 |
|---|---|---|
| 작업용 | `loop.db` (SQLite) | 인덱스/수정/정렬/윈도우 리딩 빠름 |
| 교환용 | `*.looplog` (JSONL) | 백업/이동/병합/사람이 직접 열어보기 |

## 위치·날씨 캡처 (v2)

| 항목 | 결정 |
|---|---|
| 위치 | 저장 시 자동 캡처 (`geolocator`, 대략 정확도, 5초 타임아웃) |
| 장소명 | OS 내장 역지오코딩 (`geocoding` — 좌표→"서울특별시 성동구") |
| 날씨 | 위치 확보 시 Open-Meteo 현재 날씨 (무료·키 불필요, 3초 타임아웃) |
| 실패 정책 | 어떤 단계가 실패해도 로그 저장은 반드시 성공 (컬럼만 null) |
| 표시 | 카드엔 날씨 아이콘+온도만, 탭하면 장소·좌표·날씨·원본 시각 상세 |

macOS 샌드박스 entitlements: `network.client`(날씨 API), `personal-information.location`(GPS) + Info.plist `NSLocationWhenInUseUsageDescription`.

## 반복 규칙 (v4)

"매일 이 시간", "N분/N시간마다" — 원본 로그에 규칙을 걸면 발화마다 **빈 포크 로그**가
생성된다. 포크 구조(parent_id/root_id/path)를 그대로 재사용하므로 "몇 번 반복됐는지"는
`root_id`/`repeat_rule_id`로 바로 셀 수 있다.

- **발화 타이밍**: 알림은 다가오는 발화 12개를 미리 걸고 앱 켤 때마다 다시 맞춘다.
  로그 생성은 앱이 켜진 시점에 `settleRepeats()`가 처리 — 안드로이드는 앱이
  꺼져 있으면 코드를 못 돌리는 구조.
- **몰아 생성(catch-up)**: 앱을 안 켠 동안 발화 시각이 모두 지나도, 그 시각대로
  빈 로그를 전부 생성한다(사용자 결정). `created_at` = 예정됐던 발화 시각 —
  시계열의 올바른 자리에 끼워 들어간다. 1회 정리당 규칙별 최대 200개(홍수 방지).
- **중지**: **원본이 아니라 생성된 로그에서** 멈춘다(사용자 결정). 살아있는 반복의
  포크 카드에 🔁 칩(탭=중지, 메뉴에도 ⏹ 반복 중지). stop은 `active=0`만 —
  규칙·fire_count는 기록으로 남아 나중에 통계를 낼 수 있다.
- **빈 로그 UX**: 반복으로 생긴 빈 포크는 탭하면 곧장 내용 편집으로 열린다.
  카드에는 원본 내용 앞 10자 + … 를 미리보기로 보여준다(2026-10-17 사용자 결정).
- **daily 발화**: +1일 방식 — 한국은 DST가 없어 시각이 유지된다.
- **weekday 발화** (2026-10-17): "매일(토·일·공휴일 제외)" — 다음 근무일 같은 시각.
  공휴일은 `lib/utils/workday.dart`의 관공서 기준 날짜표(현재 2026~2028, 대체공휴일
  포함)로 판정한다. 표에 없는 해는 주말만 제외된다 — 앱 업데이트로 표를 연장.

## 단발 루프와 망각곡선 (v6)

한 번 알림(loop_at)의 발화는 앱이 켜진 시점 `settleExpiredLoops()`가 처리한다 —
발화 시각대로 빈 포크를 만들고 `loop_done = 1`.

- **loop_count (v6 신규 컬럼)**: 이 체인에서 단발 루프로 돌아온 횟수.
  발화 시 원본 +1, 발화로 태어난 포크는 그 시점 카운트를 이어받는다(N+1).
  발화를 기다리지 않고 "지금 이어쓰기"로 소비해도 +1 — 돌아온 것은 복습 1회.
- **망각곡선 사다리**: 10분 → 1시간 → 1일 → 1주 → 1달 (5단계, `LoopSheet.curve`).
  Loop 시트는 loop_count N에 대해 N+1번째 간격을 기본 칩으로 제안하고
  실제 적용 시각(`LoopOnce(at)`)도 그 간격에서 시작한다. 끝에 도달하면 1달 유지.
  다른 칩/직접 선택은 언제나 가능 — 곡선은 기본값일 뿐 강제가 아니다.

## 시간 저장 원칙

- **저장은 전부 UTC**: SQLite의 모든 시각 컬럼(created_at, original_created_at,
  loop_at, next_fire_at)은 epoch 밀리초 — 타임존 개념이 없는 절대시각.
- **표시는 기기 시간대**: 읽을 때 `fromMillisecondsSinceEpoch()`가 로컬 시간대로
  변환하므로 표시 로직(t.hour, 날짜 경계 계산)은 전부 기기 설정을 따른다.
  여행 가면 현지 시간대로 보인다 — 카톡 등 표준 앱과 같은 동작.
- **언어의 역할**: 표기 형식(l10n)뿐 — "시간대를 언어별로" 바꾸지 않는다.
  시간대는 언어가 아니라 기기 설정의 속성이다.
- **알림도 절대시각**: `TZDateTime.from(at, tz.local)`로 인스턴트를 보존해
  예약하므로 예약 시점과 발화 시점의 시간대가 달라도 정확히 울린다.
- 회귀 테스트: test/time_storage_test.dart

## 참고 용어

- **Materialized Path**: 계층 경로를 컬럼에 저장하는 기법. SQLite는 물리 뷰(materialized view)를 지원하지 않으므로, 계층 전체 한 방 조회는 이 기법으로 해결
- **ULID류 ID**: 시각 순 정렬이 가능한 base36 ID (`created_at` 동률 시 id로 타이브레이크)
- **WMO 코드**: 세계기상기구 표준 날씨 코드 (Open-Meteo가 반환)

### 가져오기 (2026-10-17 구현)

`LoopDb.importLines(Stream<String>)` — exportLines의 역. ID가 전 세계적으로
유니크(시각+무작위, auto increment 아님)하므로 머지는 "같은 id면 건너뛴다"로
끝난다: 다른 기기 데이터 추가, 같은 백업 재가져오기 모두 중복 없음.
SAF "열기"(MainActivity.kt `pick`/`openRead`/`readChunk`/`closeRead`)로
512KB 청크를 읽고 chunked UTF-8 디코더로 줄을 복원(청크 경계의 멀티바이트
안전). 트랜잭션으로 원자성 보장 — 형식 오류면 rollback. 살아있는 반복 규칙의
next_fire_at이 과거면 이후 settleRepeats가 몰아 생성(기존 동작과 동일).
