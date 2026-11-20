# Loop 사용법 그림 다시 찍기

> 앱 안내(`lib/screens/guide_screen.dart`)와 공개 페이지(`tool/build_guide_page.py` → devnoyo0123/loop-guide)가 같은 그림을 쓴다.
> **개인 기록이 담기지 않게** 에뮬레이터 + 데모 DB로만 찍는다.
> **2026-11-02: 8개 언어 전부 촬영 완료** (ko/en + ja/zh/es/vi/it/hi). 아래 절차는 언어 하나 추가할 때의 절차.

1. 데모 DB: `DEMO_OUT=/tmp/demo_<lang> DEMO_LANG=<lang> flutter test test/make_demo_db_test.dart`
   — `tool/make_demo_db.dart`의 `_texts` 맵에 8개 언어 본문·장소명 있다. share_name(공유 표시명)도 언어별로 설정됨(ko=민수, 나머지=Minsu).
2. 빌드: `flutter build apk --debug --dart-define=LOOP_MCP=false` (MCP 메뉴가 그림에 나오지 않게) → 에뮬레이터 설치.
3. DB 주입: `adb push` 후 `run-as com.devnoyo0123.loop` 로 `files/loop.db` 교체(-wal/-shm 삭제).
4. 폰 비율·언어: `wm size 1080x2340`, `wm density 420`,
   `cmd locale set-app-locales com.devnoyo0123.loop --locales <ko-KR|en-US|ja-JP|zh-CN|es-ES|vi|it-IT|hi-IN>`.
5. 장면(파일명): 00_timeline · 01_write(＋, 에뮬레이터 기준 (964,2140)) · 02_loop(카드 ⋯ 메뉴 › Loop — 메뉴 행은 ⋯y+22부터 126px 간격, **행 수를 스캔해서 고르 것**: 5행이면 공유=4행째) · 03_repeat(Loop 시트 반복 탭) · 04_flow(포크 카드 ⋯ 메뉴 › 루프 보기) · 05_upcoming(첫 아이콘 x=512) · 06_rhythm(설정 x=1016) · 07_share(카드 ⋯ 메뉴 › Loop 공유) · 08_backup(설정 데이터) · 09_stats(기록 흐름 x=890) · 10_alarm_permission(FSI **appops deny** 후 발화 체험 — USE_FULL_SCREEN_INTENT가 대상, 오버레이 아님) · 11_alarm(허용 후 발화 체험, 20초 대기).
   ⚠️ 카드 ⋯ 버튼 x중심=953, 앱바 아이콘 y=170. 언어마다 카드 높이가 달라 ⋯ y는 매 언어 픽셀 스캔으로 재측정.
6. 가공: 상단 90px·하단 70px 자르고 폭 720 → `cwebp -q 78` → `assets/guide/<lang>/`.
   ⚑ PC 연결 장면(2026-11-17 추가)은 2장: `12_pc_menu`(설정 시트 스크롤 후 — "PC 연결" 행 보이는 상태)
   · `12_pc`(PC 연결 화면 — 주소 필드에 `192.168.35.8` 입력 후 키보드 접은 상태).
   촬영 시 주의: macOS /bin/bash는 3.2라 `declare -A` 불가(로케일이 전부 마지막 값으로 밀림 —
   2026-11-17 실제 발생). 위치 기반 함수 + 명시 인자로 우회. 에뮬레이터 창 가장자리에
   초록 테두리(코치 투어 하이라이트)가 남으면 데모 DB에 `coach_tour_step='done'` 주입으로 제거.
7. 되돌리기: `wm size`/`density` 원래 값, 앱 언어 해제, 백업해 둔 DB 복원.
8. 공개 페이지 갱신: `python3 tool/build_guide_page.py <loop-guide 클론>` → 커밋·푸시.
   pubspec.yaml assets 목록과 `lib/utils/guide_content.dart`의 `guideImageLanguages`에도 언어 추가.
