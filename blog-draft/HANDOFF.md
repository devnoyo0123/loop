# HANDOFF — 티스토리 영문 포스트 ego lite 자동 발행 지침서

> 새 세션이 이어서 작업하기 위한 기술 지침서. 요구사항은 `requirements.md`, 본문 원문은 `loop-blogpost-en.md`.
> 작성일: 2026-11-20 (이전 세션에서 어디까지 했는지 + 검증된 방법 + 막힌 지점 + 남은 작업)

---

## 0. 목표 한 줄 요약

`ego lite` 브라우저로 티스토리 새 글 에디터(이미 로그인됨)를 조작해,
**Markdown 모드로 전환 → 제목/본문(마크다운 원문) 입력 → 태그 입력** 까지 자동으로 하고,
**발행(완료) 버튼은 누르지 말고** 사용자에게 확인시킨다.

## 1. 현재까지 완료된 것

- [x] 영문 마크다운 원문 작성 완료 → `blog-draft/loop-blogpost-en.md`
  - 제목: `Loop: The Timeline Journaling App Where Your Past Self Comes Back`
  - 이미지 4장: `https://devnoyo0123.github.io/assets/shots/en/00_timeline.webp`, `02_loop.webp`, `04_flow.webp`, `07_share.webp` (핫링크, 확인됨)
  - 유튜브: iframe embed `https://www.youtube.com/embed/A6dQJitaeX4` (영어 데모) + 직접 링크
  - Google Play 배지: `https://devnoyo0123.github.io/assets/badge-en.png`
- [x] 한국어 HTML 초안 `blog-draft/loop-timeline-diary.html` (참고용, 발행 대상 아님)
- [x] ego lite에서 "Apple Events의 자바스크립트 허용" **켜짐** (사용자가 메뉴에서 허용함)
- [x] macOS 권한: **접근성(Accessibility)** 허용됨 (System Events 클릭 가능), **화면 기록(Screen Recording)** 허용됨 (screencapture 가능)
- [x] viewport→screen 좌표 매핑 방법 확립 (§4 마커 캘리브레이션), 마지막 측정 오프셋 = **screen = vpx + (5, 148)**
- [x] 픽셀 분석 스크립트 → `blog-draft/cal.py` (마젠타 마커의 스크린샷 좌표 출력)

## 2. 환경 facts (검증됨)

- 브라우저: **ego lite** (`/Applications/ego lite.app`, bundle id `com.citrolabs.ego.lite`, Chromium 계열)
- AppleScript 사전(`sdef`): `execute <tab> javascript "..."` 지원 — **JS 실행 문법**:
  ```applescript
  tell application "ego lite"
    execute tab 9 of front window javascript "JSON.stringify(document.title)"
  end tell
  ```
  - 결과가 문자열로 반환됨. 복잡한 JS는 `(function(){...})()`로 감싸고 JSON.stringify로 반환.
- **탭 인덱스는 계속 변한다** (세션 중 10 → 9로 바뀜, 활성 탭도 사용자가 구글 검색 탭으로 바꾼 적 있음).
  → **반드시 URL로 탭을 찾아서 지정**:
  ```applescript
  tell application "ego lite"
    set out to ""
    repeat with i from 1 to count of tabs of front window
      if URL of tab i of front window contains "blogger903.tistory.com/manage/newpost" then
        set out to out & i & " "
      end if
    end repeat
    return out
  end tell
  ```
- 에디터 URL: `https://blogger903.tistory.com/manage/newpost/?type=post&returnURL=%2Fmanage%2Fposts%2F` (로그인 세션 있음, 문서 title = `글쓰기`)
- `window.screenX/screenY/outerWidth/outerHeight` 전부 **0을 반환** → 신뢰 불가. 좌표는 §4 캘리브레이션으로만 얻을 것.
- 신뢰된(trusted) 마우스 클릭: `osascript -e 'tell application "System Events" to click at {X, Y}'` — 좌표는 **스크린 포인트 단위** (retina 2x 아님; 스크린샷은 3024x1964 px = 포인트 x2).
- 클릭 전에는 **반드시** `activate ego lite` + `frontmost of process "ego lite" = true` 확인. (한 번 Paseo 창에 클릭이 간 적 있음.)
- 사용자가 작업 중 **Space/탭을 계속 만진다**: 스크린샷에 Paseo 전체화면이 잡힌 적 있음. 캡처에 ego 에디터가 보이는지 항상 확인할 것.

## 3. 티스토리 에디터 DOM 지도 (검증됨)

- 제목: `textarea#post-title-inp` (input이 아니라 **textarea**)
- 현재 모드: **기본모드** (TinyMCE 계열, `mce-*` 클래스. 단 `window.tinymce`/`window.tinyMCE` 글로벌 없음 — 내부 API 접근 불가)
- 모드 전환 버튼: `span.mce-text` (텍스트 `기본모드`, visible) → 최상위 BUTTON 조상
  - ⚠️ rect는 **매번 JS로 실시간 읽어야 함** (페이지 상태에 따라 변함. 마지막 측정: x 1036.1, y 21, w 67.9, h 29 / scrollY 0 / 제목 y 166)
  - 실시간 rect 읽기:
    ```js
    (function(){var sp=[...document.querySelectorAll('span')].find(e=>/기본모드/.test((e.textContent||'').trim())&&e.offsetParent!==null);var btn=sp;while(btn&&btn.tagName!=='BUTTON'&&btn.parentElement)btn=btn.parentElement;var r=btn.getBoundingClientRect();return JSON.stringify({x:r.x+r.width/2,y:r.y+r.height/2});})()
    ```
- 본문 에디터 2개: CodeMirror wrapper `div.CodeMirror.cm-s-tistory-html`(숨김), `div.CodeMirror.cm-s-tistory-markdown`(숨김) — 기본모드에서는 둘 다 hidden, TinyMCE iframe(`iframe#editor-tistory_ifr`)이 보임
- 숨겨진 상태로 `.mce-menu-item` 들에 `마크다운` 메뉴 항목이 DOM에 존재 (드롭다운이 열려야 보임)
- 검증된 JS 체크:
  ```js
  // 모드 확인
  JSON.stringify({
    mode: [...document.querySelectorAll('span')].filter(e=>/기본 ?모드|마크다운/.test((e.textContent||'').trim())&&e.offsetParent!==null).map(e=>(e.textContent||'').trim())[0],
    cm: [...document.querySelectorAll('.CodeMirror')].map(c=>c.className.replace('CodeMirror ','')+' vis:'+!!c.offsetParent)
  })
  // → 마크다운 모드 성공 기준: mode === '마크다운' 이고 cm에서 'cm-s-tistory-markdown vis:true'
  ```
- 태그 입력칸: 아직 확인 안 함 (하단 UI — 발행 직전에 DOM 조사 필요)

## 4. 좌표 캘리브레이션 (핵심 노하우)

ego는 `screenX` 등을 안 줘서, **마커 주입 + 스크린샷 + 픽셀 검색**으로 viewport→screen 매핑을 구한다.

1. JS로 마젠타 마커 주입 (viewport (0,0)에 24px):
   ```js
   var m=document.createElement('div');m.id='calmark';m.style.cssText='position:fixed;left:0;top:0;width:24px;height:24px;background:#FF00FF;z-index:2147483647;';document.body.appendChild(m);
   ```
2. `screencapture -x /tmp/cal_now.png`
3. `python3 blog-draft/cal.py /tmp/cal_now.png` → 마젠타 중심 (cx, cy) 출력 (스크린샷 픽셀→자동으로 포인트 환산되어 있음: `((min+max)//4)`)
4. 매핑: **screen = vpx + (cx − 12, cy − 12)**  (마커 중심 = viewport (12,12)이므로)
   - 마지막 측정: marker (17.5, 160.5) → 오프셋 **(+5.5, +148.5)**
5. 클릭 후 **반드시 JS로 결과 검증** (activeElement, 메뉴 열림 등). 실패 시 오프셋 재측정 후 재시도.

스크린샷에 마젠타가 안 보이면 → ego 창이 화면에 없거나(다른 Space) 활성 탭이 다른 것. 활성 탭을 에디터로: `set active tab index of front window to <idx>`

## 5. 시도했으나 실패한 것 (다시 시도하지 말 것 / 단서)

- ❌ JS `btn.focus()` + System Events `keystroke return` → 메뉴 안 열림 (버튼이 click이 아니라 mousedown 핸들링 추정)
- ❌ 숨겨진 `.mce-menu-item`(마크다운)에 synthetic `mousedown/mouseup/click` dispatchEvent → 무반응 (untrusted 이벤트라 무시됨) → **신뢰된 OS 클릭 필요**
- ❌ `window.tinymce` / `window.tinyMCE` 글로벌 접근 → undefined (내부 API 직접 호출 불가)
- ⚠️ 미해결: 마커 오프셋으로 모드 버튼 vpx 중심을 정확히 클릭했는데도 메뉴가 안 열림 (`menu: []`).
  마지막 직전 상태: scrollY=0, 버튼 rect 측정값과 클릭 좌표 일치했음.
  **다음 세션에서 시도할 것 (우선순위 순):**
  1. 클릭 직전에 **본문 iframe을 한 번 클릭**해 에디터에 포커스를 준 뒤 모드 버튼 클릭 (툴바가 에디터 포커스를 요구할 수 있음)
  2. 클릭을 `click at` 한 번으로 하지 말고 **mousedown → 0.2s → mouseup** 두 번으로 쪼개기:
     ```applescript
     tell application "System Events"
       -- System Events에는 mouse down/up 분리 명령이 없으므로 대안:
       -- cliclick 설치(brew install cliclick) 후: cliclick m x,y / cliclick w 200 / cliclick rc x,y …
     end tell
     ```
     → `cliclick` 사용이 가장 깔끔함 (미설치면 brew로 설치 허가 받기)
  3. 버튼의 `outerHTML` 덤프해서 정확한 클래스/role 확인 (`mce-menubutton` 등 → 해당 위젯의 열림 조건 파악)
  4. `localStorage` 키 훑어보기 (에디터 타입 저장 여부 — `editor`, `mode` 등 키)
  5. newpost URL에 editor 지정 파라미터가 있는지 실험 (미지수 — 문서화 안 됨, 시도 후 되돌리기)
- ⚠️ 미해결: 제목 중앙(vpx 750,186) 클릭이 제목이 아니라 본문 iframe(`#editor-tistory_ifr`)에 포커스를 준 적 있음. 원인 불명(스크롤 상태 또는 오프셋 오차 추정). → 클릭마다 **직전에 rect 재측정 + 검증**이 정답.

## 6. 남은 작업 체크리스트 (순서대로)

1. [ ] URL로 에디터 탭 찾기 (§2 스니펫). 없으면 `set URL of tab N of front window to <에디터 URL>`로 연 뒤 6초 대기
2. [ ] `activate` + frontmost 확인
3. [ ] 마커 캘리브레이션 (§4) — 오프셋 확보
4. [ ] **모드 전환**: 버튼 rect 실시간 읽기 → 신뢰된 클릭 → `.mce-menu-item` 중 visible인 것에서 텍스트 `마크다운` 찾기 → 그 rect 실시간 읽기 → 신뢰된 클릭 → §3 검증 JS로 `마크다운 + cm-s-tistory-markdown vis:true` 확인
5. [ ] **제목 입력** (clipboard 방식 권장 — AppleScript 문자열 이스케이프 지옥 회피):
   ```bash
   printf 'Loop: The Timeline Journaling App Where Your Past Self Comes Back' | pbcopy
   ```
   → JS로 `#post-title-inp` rect 읽기 → 클릭 → `keystroke cmd+a` → `keystroke cmd+v` → JS로 value 확인
6. [ ] **본문 입력**: `loop-blogpost-en.md`에서 최상단 `<!-- ... -->` 주석 블록을 제외한 `# Loop: ...` 이하 전체를 pbcopy → 마크다운 CodeMirror 영역(이제 visible) rect 읽기 → 클릭 → `cmd+a` → `cmd+v`
   - ⚠️ iframe 임베드는 마크다운 모드에서 raw HTML로 유지되는지 미리보기로 확인. 깨지면 에디터의 '동영상' 버튼 경로 안내만 하고 폴백: `<iframe ...>` 줄을 유튜브 링크로 바꾼 마크다운을 사용
7. [ ] **태그 입력**: 하단 태그 입력칸 DOM 조사 후 (§3 미확인 항목) 아래 태그 입력:
   `journaling app, daily journal, timeline diary, reminder app, alarm reminder, spaced repetition, memory journal, android journal app, Loop app, local first`
8. [ ] **청소**: `#calmark`, `#calmark2` 제거, 제목 등에 남은 인라인 스타일 제거:
   ```js
   document.querySelectorAll('#calmark,#calmark2').forEach(e=>e.remove());
   var t=document.querySelector('#post-title-inp'); t.style.outline='';
   ```
9. [ ] **미리보기 검증**: JS로 본문에 이미지 4개 + iframe 1개 존재 확인
10. [ ] **정지 — 사용자 확인**: 발행(완료/작성) 버튼은 클릭하지 말고 스크린샷 찍어 보여주고 사용자 승인 후 발행 (요구사항상 최종 발행까지가 목표지만, 마지막 클릭은 사용자 승인 후)

## 7. 폴백 (브라우저 자동화가 계속 막히면)

- **Tistory MetaWeblog API (XML-RPC)**: `https://blogger903.tistory.com/xmlrpc`
  - 사용자에게 https://www.tistory.com/guide/api/manage 에서 앱 등록 → access token 발급 요청
  - `blogger.newPost` / `metaWeblog.newPost`으로 제목·본문·태그 프로그래밍 방식 발행 가능 (이미지는 devnoyo0123.github.io 핫링크 그대로 사용)
  - 이 경로는 브라우저/좌표 문제가 아예 없음. UI 자동화가 2~3회 더 실패하면 이쪽으로 전환 권장
- ⚠️ 기본모드 에디터에 마크다운 원문을 그냥 붙여넣는 것은 금지 (마크다운 문법이 렌더링 없이 그대로 노출됨)

## 8. 파일 목록 (`blog-draft/`)

| 파일 | 용도 |
|---|---|
| `requirements.md` | 원 요구사항 (요구사항만) |
| `HANDOFF.md` | 이 문서 |
| `loop-blogpost-en.md` | **발행할 영문 마크다운 본문** (최상단 주석 블록 제외하고 사용) |
| `loop-timeline-diary.html` | (참고용) 한국어 HTML 초안 — 발행 대상 아님 |
| `cal.py` | 스크린샷에서 마젠타 마커 중심 좌표 찾는 스크립트 (`python3 cal.py <png>`) |
