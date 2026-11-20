# Loop — 스토어 스크린샷 제작 계획 (2026-10-18 수정)

> **이미지 세트 3종: 영어(US 베이스) + 중국어 + 스페인어.**
> 한국어·일본어·베트남어·인도는 **텍스트만 등록**하고 영어(US) 이미지를
> 재사용한다 (사용자 결정). 인도는 기본 목록(en-US)이 그대로 커버 — 힌디어
> 별도 번역 없음.
> 한국어 사용자에게는 영어 스크린샷이 보인다 — 의도된 정책(기록용).

## 제작 파이프라인

1. 데모 데이터: 폰의 개인 로그 대신 데모 로그를 넣은 상태로 촬영 (프라이버시 보호)
2. 실기기 캡처: adb screencap — 핵심 화면 5종 (언어 무관, 앱 UI는 영어로 통일해도
   무방하나 한국어 UI 그대로여도 스크린샷 문구가 영어면 충분히 자연스럽다 — 캡처 시 앱 언어는 영어 권장)
3. 문구 오버레이: HTML 목업 → PNG — 같은 캡처에 언어별 텍스트만 교체해 3세트 생성
4. 규격: 폰 스크린샷 원본 비율 그대로 (Play 요건: 최소 320px, 최대 3840px)

## 화면 5종 × 3개 언어 문구

### 1. 타임라인 (메인 화면)
| 언어 | 헤드라인 | 서브 |
|---|---|---|
| en | Log your day in order | Capture the thought right where it happened |
| zh | 按顺序积累的一天记录 | 冒出的想法，记在它发生的时刻 |
| es | Registra tu día en orden | Guarda la idea justo donde surgió |

### 2. 작성 + 루프 걸기 (Loop 시트)
| 언어 | 헤드라인 | 서브 |
|---|---|---|
| en | Loop the thoughts that matter | It comes back when the time is right |
| zh | 重要的事，用循环提醒 | 时间到了，它会回来找你 |
| es | Pon un bucle a lo importante | Vuelve cuando toque |

### 3. 루프 보기 (이어쓰기 사슬)
| 언어 | 헤드라인 | 서브 |
|---|---|---|
| en | Continue where you left off | The whole chain, one screen |
| zh | 流逝的想法，续写接续 | 从最初到现在，一屏看尽 |
| es | Continúa donde lo dejaste | Toda la cadena en una pantalla |

### 4. 다가오는 루프 (미리보기)
| 언어 | 헤드라인 | 서브 |
|---|---|---|
| en | Loops coming this week | Your week of reminders at a glance |
| zh | 本周将回来的循环 | 未来7天，一眼看清 |
| es | Bucles de esta semana | Tus recordatorios de 7 días |

### 5. 검색
| 언어 | 헤드라인 | 서브 |
|---|---|---|
| en | Find any past thought, fast | Search content and places |
| zh | 秒找过去的想法 | 内容、地点都能搜 |
| es | Encuentra tus ideas al instante | Busca por contenido y lugar |

## Play Console 등록 구조

| 목록 | 텍스트 | 이미지 |
|---|---|---|
| **en-US (기본)** | en-US 문구 (전 세계 기본값 — 인도 포함) | 영어 세트 |
| ko-KR | 한국어 문구 | 영어 세트 재사용 |
| ja-JP | 일본어 문구 | 영어 세트 재사용 |
| zh-CN | 중국어 문구 | **중국어 세트** |
| es | 스페인어 문구 | **스페인어 세트** |
| vi | 베트남어 문구 | 영어 세트 재사용 |

텍스트는 docs/store-listing.md에 6개 언어 전부 작성돼 있다.

## 촬영 체크리스트

- [ ] 데모 .looplog 준비 (자연스러운 샘플 로그 15~20개, 사진 1~2장, 루프 걸린 로그)
- [ ] 폰 세팅: 다크 테마, 앱 언어 영어로 통일, 시각 통일(9:00대), 배터리 100%, 알림 정리
- [ ] 5화면 캡처 (adb screencap)
- [ ] 오버레이 조립 ×3언어 → PNG 15장
- [ ] Play Console 업로드: 기본 세트(영어) + zh/es 이미지 현지화 + ko/ja/vi 텍스트 현지화
