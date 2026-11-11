#!/usr/bin/env python3
"""Loop 사용법 공개 페이지 생성기 — 앱 안내(GuideScreen)와 같은 글·그림.

원본:
  - 글: lib/l10n/app_*.arb (8개 언어) 의 guide* 키
  - 그림: assets/guide/{ko,en}/*.webp — 나머지 6개 언어는 en 그림 재사용
  - 순서: lib/utils/guide_content.dart 와 같은 SECTIONS
  - 언어 나열 순서: 화자 수(인구) 순 (2026-11-02 사용자 결정)

사용:
  python3 tool/build_guide_page.py <출력 폴더>   # 예: loop-guide 저장소 클론
출력 폴더에 index.md, _config.yml, _layouts/default.html, images/{ko,en}/*.webp 를 쓴다.
공개 URL: https://devnoyo0123.github.io/loop-guide/
"""
import json
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PLAY_URL = "https://play.google.com/store/apps/details?id=com.devnoyo0123.loop"

# 페이지 헤더 버튼(Google Play 브랜드명이라 영어 통용) + 언어별 본문 링크 문구
PLAY_LABELS = {
    "en": "Download on Google Play",
    "zh": "在 Google Play 中下载",
    "es": "Descargar en Google Play",
    "hi": "Google Play पर डाउनलोड करें",
    "ja": "Google Play でダウンロード",
    "vi": "Tải xuống trên Google Play",
    "it": "Scarica su Google Play",
    "ko": "Google Play에서 다운로드",
}

# jekyll-theme-minimal 레이아웃 오버라이드 — 테마가 자동으로 넣는 GitHub 링크들
# (View the Project on GitHub, Download ZIP/TAR, 유지자·테마 크레딧)을 빼고
# 그 자리에 Play Store 다운로드 버튼을 둔다. (2026-11-11 사용자 지적)
LAYOUT = """<!DOCTYPE html>
<html lang="{{ site.lang | default: "en-US" }}">
  <head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

{% seo %}
    <link rel="stylesheet" href="{{ "/assets/css/style.css?v=" | append: site.github.build_revision | relative_url }}">
    <!--[if lt IE 9]>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv.min.js"></script>
    <![endif]-->
    {% include head-custom.html %}
  </head>
  <body>
    <div class="wrapper">
      <header>
        <h1><a href="{{ "/" | absolute_url }}">{{ site.title | default: site.github.repository_name }}</a></h1>

        {% if site.logo %}
          <img src="{{site.logo | relative_url}}" alt="Logo" />
        {% endif %}

        <p>{{ site.description | default: site.github.project_tagline }}</p>

        <ul class="downloads">
          <li><a href="__PLAY_URL__">Download on <strong>Google Play</strong></a></li>
        </ul>
      </header>
      <section>

      {{ content }}

      </section>
    </div>
    <script src="{{ "/assets/js/scale.fix.js" | relative_url }}"></script>
  </body>
</html>
"""

# (제목 키 접두, 그림들) — guide_content.dart의 guideSections와 같은 순서
SECTIONS = [
    ("guideIntro", ["00_timeline"]),
    ("guideWrite", ["01_write"]),
    ("guideLoop", ["02_loop"]),
    ("guideRepeat", ["03_repeat"]),
    ("guideFlow", ["04_flow"]),
    ("guideUpcoming", ["05_upcoming"]),
    ("guideRhythm", ["06_rhythm"]),
    ("guideShare", ["07_share"]),
    ("guideBackup", ["08_backup"]),
    ("guideStats", ["09_stats"]),
    ("guideAlarm", ["10_alarm_permission", "11_alarm"]),
]

# 화면 노출 순서 — 스토어 설명과 같이 화자 수(인구) 순. (2026-11-02 사용자 결정:
# "영어, 중국어, 스페인어, 등 인구수 순으로… 한국어는 인구수 순으로 밀려나야지")
LANGS = [
    ("en", "English"),
    ("zh", "中文"),
    ("es", "Español"),
    ("hi", "हिन्दी"),
    ("ja", "日本語"),
    ("vi", "Tiếng Việt"),
    ("it", "Italiano"),
    ("ko", "한국어"),
]


def arb(lang):
    with open(os.path.join(ROOT, "lib", "l10n", f"app_{lang}.arb"), encoding="utf-8") as f:
        return json.load(f)


def image_lang(lang):
    """스크린샷은 ko·en만 촬영돼 있다. 나머지 언어는 en 그림을 쓴다
    (본문은 번역, 그림은 영어 UI — 앱 UI 언어별 캡처는 나중에 교체)."""
    return lang if os.path.isdir(os.path.join(ROOT, "assets", "guide", lang)) else "en"


def section_md(d, lang, i, key, images):
    title = d[f"{key}Title"]
    body = d[f"{key}Body"]
    head = f"### {title}" if i == 0 else f"### {i}. {title}"
    imgs = "\n".join(
        f'<img src="images/{image_lang(lang)}/{name}.webp" alt="{title}" width="260" '
        f'style="border-radius:12px;border:1px solid #2a2f3d;margin:4px">'
        for name in images
    )
    return f"{head}\n\n{body}\n\n<p>\n{imgs}\n</p>\n"


def build(out):
    os.makedirs(out, exist_ok=True)
    nav = " · ".join(
        f"[{label}](#{label.lower().replace(' ', '-')})" for _, label in LANGS
    )
    parts = ["# How to use Loop\n", f"{nav}\n", "---\n"]
    for lang, label in LANGS:
        d = arb(lang)
        parts.append(f"## {label}\n")
        parts.append(
            f"⬇ [{PLAY_LABELS[lang]}]({PLAY_URL})\n"
        )
        for i, (key, images) in enumerate(SECTIONS):
            parts.append(section_md(d, lang, i, key, images))
        parts.append("---\n")
    parts.append(
        "개인정보처리방침 · Privacy Policy: "
        "<https://devnoyo0123.github.io/loop-privacy/>\n\n"
        "문의 · Contact: `theloopapp.official@gmail.com`\n"
    )
    with open(os.path.join(out, "index.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(parts))
    with open(os.path.join(out, "_config.yml"), "w", encoding="utf-8") as f:
        f.write("title: How to use Loop\ntheme: jekyll-theme-minimal\n")
    os.makedirs(os.path.join(out, "_layouts"), exist_ok=True)
    with open(os.path.join(out, "_layouts", "default.html"), "w", encoding="utf-8") as f:
        f.write(LAYOUT.replace("__PLAY_URL__", PLAY_URL))
    for src_lang in {image_lang(lang) for lang, _ in LANGS}:
        dst_lang = src_lang
        dst = os.path.join(out, "images", dst_lang)
        os.makedirs(dst, exist_ok=True)
        for _, images in SECTIONS:
            for name in images:
                shutil.copyfile(
                    os.path.join(ROOT, "assets", "guide", src_lang, f"{name}.webp"),
                    os.path.join(dst, f"{name}.webp"),
                )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    build(sys.argv[1])
    print("ok")
