# 블로그 포스트 발행 요구사항

> 원 요청(세션 첫 대화)을 요구사항만 추린 문서. 구현 방법·기술 상세는 `HANDOFF.md` 참조.

## 1. 발행처
- 기존에 사용하던 TISTORY 블로그: **https://blogger903.tistory.com/**
- 새 글 작성 화면에서 직접 작성해서 올릴 것 (미리보기가 깨진 paste 방식 아님)
- 최종적으로 블로그에 **글이 발행(업로드)** 되어야 함

## 2. 언어·형식
- **영어로 작성** (한국 독자 대상 아님)
- **마크다운 형식**으로 기록 (티스토리 에디터의 Markdown 모드 사용)

## 3. 글 내용 (주제)
- Loop 앱 (https://devnoyo0123.github.io/ — 타임라인 일기 앱) 소개 포스트
- 과거의 기록이 다시 찾아오는 컨셉 중심의 영문 소개글

## 4. SEO (구글 검색 대응)
- 제목을 검색 키워드에 맞게 신경써서 작성
  - 확정 제목: `Loop: The Timeline Journaling App Where Your Past Self Comes Back`
- 키워드가 자연스럽게 들어간 본문 (journaling app, timeline, reminder, local-first 등)
- 태그(티스토리 태그) 설정

## 5. 필수 포함 요소
- **devnoyo0123.github.io 링크** (본문 + 공식 사이트 링크)
- **YouTube 링크 + 영상 임베드** (영어 데모: https://www.youtube.com/watch?v=A6dQJitaeX4)
- **이미지 포함** (스크린샷 4장: timeline / loop 설정 / flow / share — devnoyo0123.github.io 에 호스팅된 영문 스크린샷 사용)
- Google Play 다운로드 배지·링크 (https://play.google.com/store/apps/details?id=com.devnoyo0123.loop)

## 6. 본문 소스
- 작성 완료된 마크다운 원문: `blog-draft/loop-blogpost-en.md`
  - (파일 최상단의 `<!-- ... -->` 안내 주석 블록은 발행 시 제외하고 `# Loop: ...`부터 본문으로 사용)
