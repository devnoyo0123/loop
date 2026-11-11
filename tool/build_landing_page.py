#!/usr/bin/env python3
"""Loop 공개 랜딩 페이지(devnoyo0123.github.io) 생성기.

- 언어: loop-guide와 같은 8개 언어, 화자 수(인구) 순 (2026-11-11 사용자 결정)
- 글: lib/l10n/app_*.arb 의 guide* 키(공식 번역) + docs/store-listing.md 의
  공식 짧은 설명(아래 SUB에 복사). TRUST·CTA 등 짧은 문구는 이 파일에서 관리.
- 그림: assets/guide/{ko,en}/*.webp — 나머지 언어는 en 그림 재사용(가이드와 같은 규칙)
- 배지: Google Play 공식 배지 8개 언어(badge-*.png)는 출력 폴더 assets/ 에 이미
  커밋돼 있어야 한다 (스크립트가 만들지 않는다).

사용:
  python3 tool/build_landing_page.py <출력 폴더>   # 예: devnoyo0123.github.io 클론
출력 폴더에 index.html, assets/{icon.png, shots/{ko,en}/*.webp} 를 쓴다.
공개 URL: https://devnoyo0123.github.io/
"""
import html
import json
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PLAY_URL = "https://play.google.com/store/apps/details?id=com.devnoyo0123.loop"
GUIDE_URL = "https://devnoyo0123.github.io/loop-guide/"
PRIVACY_URL = "https://devnoyo0123.github.io/loop-privacy/"
CONTACT_MAIL = "theloopapp.official@gmail.com"

# 화면 노출 순서 — 가이드 페이지와 같이 화자 수(인구) 순
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
LANG_IDS = [lang for lang, _ in LANGS]

# (아이콘, arb 키) — 가이드 섹션을 그대로 피처 카드로
FEATURES = [
    ("↩", "guideLoop"),
    ("🔁", "guideRepeat"),
    ("⛓", "guideFlow"),
    ("⏰", "guideAlarm"),
    ("📡", "guideShare"),
    ("🔒", "guideBackup"),
]

# (그림, arb 키) — 스크린샷 캡션은 해당 섹션 제목
SHOTS = [
    ("00_timeline", "guideIntro"),
    ("02_loop", "guideLoop"),
    ("04_flow", "guideFlow"),
    ("07_share", "guideShare"),
]

# docs/store-listing.md 의 공식 짧은 설명·제목 (2026-11-11 기준)
SUB = {
    "en": "Log your day in order. Loops bring thoughts back — even as full-screen alarms.",
    "zh": "按顺序积累的一天记录。用续写接住流逝的想法，让循环提醒带你回来。",
    "es": "Registra tu día en orden. Continúa un pensamiento y los bucles te lo devuelven.",
    "hi": "अपने दिन को क्रम में लिखें. पुराने विचारों को जोड़ें, लूप उन्हें वापस लाएँ.",
    "ja": "思った順に積もる一日ログ。過ぎた思考は続き書きでつなぎ、ループ通知でまた戻る。",
    "vi": "Ghi lại ngày theo trình tự. Viết tiếp suy nghĩ cũ, vòng lặp đưa bạn quay lại.",
    "it": "Registra il tuo giorno in ordine. I loop riportano i pensieri persi.",
    "ko": "순서대로 쌓는 하루 기록. 루프는 전체 화면 알람처럼 — 확인할 때까지 다시 돌아옵니다.",
}
STORE_TITLE = {
    "en": "Loop — Daily Timeline Log",
    "zh": "Loop — 按顺序记录每一天",
    "es": "Loop — Tu día, en orden",
    "hi": "Loop — हर दिन, अपने क्रम में",
    "ja": "Loop — 時間順の一日ログ",
    "vi": "Loop — Nhật ký theo trình tự",
    "it": "Loop — Il giorno in ordine",
    "ko": "Loop : 흘러간 하루의 기록",
}

TRUST = {
    "en": "No server · no account · logs stay on your phone",
    "zh": "无服务器 · 无账号 · 记录只留在你的手机里",
    "es": "Sin servidor · sin cuenta · los registros quedan en tu teléfono",
    "hi": "कोई सर्वर नहीं · कोई खाता नहीं · लॉग सिर्फ़ आपके फ़ोन पर",
    "ja": "サーバーなし · アカウントなし · 記録は端末の中だけ",
    "vi": "Không máy chủ · không tài khoản · nhật ký nằm trên máy bạn",
    "it": "Nessun server · nessun account · i log restano sul telefono",
    "ko": "서버 없음 · 계정 없음 · 기록은 내 폰에만",
}
CTA = {
    "en": "Write today's thought — meet it again tomorrow.",
    "zh": "今天的想法，明天再见面。",
    "es": "Escribe hoy el pensamiento — reencuéntralo mañana.",
    "hi": "आज का विचार लिखें — कल दोबारा मिलें।",
    "ja": "今日のひと言を、明日もう一度。",
    "vi": "Ghi lại suy nghĩ hôm nay — gặp lại vào ngày mai.",
    "it": "Scrivi oggi il pensiero — ritrovalo domani.",
    "ko": "오늘의 생각을, 내일 다시 만나보세요.",
}
GUIDE_LABEL = {
    "en": "How to use (with pictures)",
    "zh": "使用方法（图文）",
    "es": "Cómo usarlo (con imágenes)",
    "hi": "उपयोग कैसे करें (चित्रों के साथ)",
    "ja": "使い方（画像つき）",
    "vi": "Cách dùng (có hình ảnh)",
    "it": "Come si usa (con immagini)",
    "ko": "사용법(그림 안내)",
}
PRIVACY = {
    "en": "Privacy Policy",
    "zh": "隐私政策",
    "es": "Política de privacidad",
    "hi": "गोपनीयता नीति",
    "ja": "プライバシーポリシー",
    "vi": "Chính sách quyền riêng tư",
    "it": "Informativa sulla privacy",
    "ko": "개인정보처리방침",
}
CONTACT_LABEL = {
    "en": "Contact",
    "zh": "联系",
    "es": "Contacto",
    "hi": "संपर्क",
    "ja": "お問い合わせ",
    "vi": "Liên hệ",
    "it": "Contatti",
    "ko": "문의",
}
BADGE_FILE = {
    "en": "badge-en.png",
    "zh": "badge-zh.png",
    "es": "badge-es.png",
    "hi": "badge-hi.png",
    "ja": "badge-ja.png",
    "vi": "badge-vi.png",
    "it": "badge-it.png",
    "ko": "badge-ko.png",
}
BADGE_ALT = {
    "en": "Get it on Google Play",
    "zh": "在 Google Play 中获取",
    "es": "Disponible en Google Play",
    "hi": "Google Play पर पाएं",
    "ja": "Google Play で手に入れよう",
    "vi": "Có trên Google Play",
    "it": "Disponibile su Google Play",
    "ko": "Google Play에서 다운로드",
}
GUIDE_LABEL_SHORT = {
    "en": "Guide",
    "zh": "指南",
    "es": "Guía",
    "hi": "गाइड",
    "ja": "ガイド",
    "vi": "Hướng dẫn",
    "it": "Guida",
    "ko": "사용법",
}


def arb(lang):
    with open(os.path.join(ROOT, "lib", "l10n", f"app_{lang}.arb"), encoding="utf-8") as f:
        return json.load(f)


def first_sentence(text):
    return re.split(r"(?<=[.。!?!?।])\s+", text.strip(), maxsplit=1)[0]


def image_lang(lang):
    """언어별 스크린샷 폴더가 있으면 그 언어 그림을 쓴다 (가이드와 같은 규칙)."""
    return lang if os.path.isdir(os.path.join(ROOT, "assets", "guide", lang)) else "en"


def spans(field):
    """dict(lang -> text) 를 언어별 span 묶음으로. .t 는 현재 언어만 보인다."""
    return "".join(
        f'<span class="t t-{lang}">{html.escape(text)}</span>' for lang, text in field.items()
    )


def build(out):
    os.makedirs(out, exist_ok=True)
    data = {lang: arb(lang) for lang in LANG_IDS}

    h1 = {lang: first_sentence(data[lang]["guideIntroBody"]) for lang in LANG_IDS}

    lang_btns = "".join(
        f'<button class="lang-btn" data-set-lang="{lang}">{label}</button>'
        for lang, label in LANGS
    )

    def badge_block():
        per = "".join(
            f'<span class="t t-{lang}"><a href="{PLAY_URL}" target="_blank" rel="noopener">'
            f'<img data-badge src="/assets/{BADGE_FILE[lang]}" alt="{html.escape(BADGE_ALT[lang])}"></a></span>'
            for lang in LANG_IDS
        )
        return f'<div class="badge-row">{per}</div>'

    def guide_link():
        return (
            f'<a class="guide-link" href="{GUIDE_URL}" target="_blank" rel="noopener">'
            f'📖 {spans(GUIDE_LABEL)}</a>'
        )

    shots_html = "".join(
        f'''<figure class="shot">
          <img data-shot="{name}" src="/assets/shots/en/{name}.webp" alt="" loading="lazy">
          <figcaption>{spans({lang: data[lang][f"{key}Title"] for lang in LANG_IDS})}</figcaption>
        </figure>'''
        for name, key in SHOTS
    )

    features_html = "".join(
        f'''<div class="card">
          <span class="ico">{icon}</span>
          <h3>{spans({lang: data[lang][f"{key}Title"] for lang in LANG_IDS})}</h3>
          <p>{spans({lang: data[lang][f"{key}Body"] for lang in LANG_IDS})}</p>
        </div>'''
        for icon, key in FEATURES
    )

    footer_links = "".join(
        f'<a href="{url}">{spans(labels)}</a>'
        for url, labels in [
            (GUIDE_URL, GUIDE_LABEL_SHORT),
            (PRIVACY_URL, PRIVACY),
        ]
    ) + f'<a href="mailto:{CONTACT_MAIL}">{spans(CONTACT_LABEL)}</a>'

    titles_json = json.dumps(STORE_TITLE, ensure_ascii=False)
    badges_json = json.dumps(
        {lang: f"/assets/{BADGE_FILE[lang]}" for lang in LANG_IDS}, ensure_ascii=False
    )
    alts_json = json.dumps(BADGE_ALT, ensure_ascii=False)
    css_lang_visible = ", ".join(f'html[data-lang="{l}"] .t-{l}' for l in LANG_IDS)

    page = f"""<!DOCTYPE html>
<html lang="en" data-lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{html.escape(STORE_TITLE["en"])}</title>
  <meta name="description" content="{html.escape(SUB["en"])}">
  <meta name="google-site-verification" content="DyFAMy89VhwcWuHAOaZSG24vtLMT7edr9ZknETy2UmQ">
  <link rel="canonical" href="https://devnoyo0123.github.io/">
  <link rel="icon" type="image/png" sizes="32x32" href="/assets/favicon-32.png">
  <link rel="apple-touch-icon" sizes="180x180" href="/assets/icon-180.png">
  <meta property="og:type" content="website">
  <meta property="og:url" content="https://devnoyo0123.github.io/">
  <meta property="og:title" content="{html.escape(STORE_TITLE["en"])}">
  <meta property="og:description" content="{html.escape(SUB["en"])}">
  <meta property="og:image" content="https://devnoyo0123.github.io/assets/icon.png">
  <style>
    :root {{
      --bg: #0B0D12;
      --surface: #12151D;
      --surface-hi: #1A1E2A;
      --text: #E8EAF2;
      --dim: #8B90A0;
      --lavender: #A78BFA;
      --mint: #7DE2C3;
      --line: #262B3A;
    }}
    * {{ margin: 0; padding: 0; box-sizing: border-box; }}
    body {{
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Pretendard", "Noto Sans KR", Roboto, sans-serif;
      line-height: 1.6;
      overflow-x: hidden;
    }}
    .aurora {{
      position: fixed; inset: 0; z-index: -1; pointer-events: none;
      background:
        radial-gradient(600px 400px at 15% 0%, rgba(167, 139, 250, .13), transparent 70%),
        radial-gradient(700px 500px at 90% 25%, rgba(125, 226, 195, .07), transparent 70%),
        radial-gradient(800px 600px at 50% 100%, rgba(167, 139, 250, .06), transparent 70%);
    }}
    .wrap {{ max-width: 1060px; margin: 0 auto; padding: 0 24px; }}

    .t {{ display: none; }}
    {css_lang_visible} {{ display: inline; }}

    nav {{
      position: sticky; top: 0; z-index: 10;
      backdrop-filter: blur(12px);
      background: rgba(11, 13, 18, .78);
      border-bottom: 1px solid var(--line);
    }}
    .nav-inner {{ display: flex; align-items: center; justify-content: space-between; height: 60px; }}
    .brand {{ display: flex; align-items: center; gap: 10px; color: var(--text); text-decoration: none; font-weight: 700; font-size: 1.05rem; letter-spacing: .02em; }}
    .brand img {{ width: 28px; height: 28px; border-radius: 8px; }}

    .lang-row {{ display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; padding-top: 20px; }}
    .lang-btn {{
      border: 1px solid var(--line); background: transparent; color: var(--dim);
      font: inherit; font-size: .82rem; padding: 5px 12px; border-radius: 999px; cursor: pointer;
    }}
    .lang-btn:hover {{ color: var(--text); border-color: var(--lavender); }}
    .lang-btn.on {{ color: var(--lavender); border-color: var(--lavender); background: rgba(167, 139, 250, .1); }}

    .hero {{ text-align: center; padding: 48px 0 56px; }}
    .hero .icon {{
      width: 112px; height: 112px; border-radius: 28px;
      box-shadow: 0 0 60px rgba(167, 139, 250, .35), 0 12px 40px rgba(0, 0, 0, .5);
      margin-bottom: 32px;
    }}
    h1 {{
      font-size: clamp(1.8rem, 4.6vw, 2.8rem); line-height: 1.28; font-weight: 800; letter-spacing: -0.02em;
      background: linear-gradient(100deg, var(--lavender), var(--mint));
      -webkit-background-clip: text; background-clip: text; color: transparent;
      max-width: 720px; margin: 0 auto;
    }}
    .hero p.sub {{ color: var(--dim); font-size: clamp(1rem, 2.4vw, 1.15rem); max-width: 560px; margin: 20px auto 0; }}
    .badge-row {{ margin-top: 36px; display: flex; justify-content: center; gap: 16px; flex-wrap: wrap; }}
    .badge-row a {{ display: inline-block; transition: transform .15s ease; }}
    .badge-row a:hover {{ transform: translateY(-2px) scale(1.02); }}
    .badge-row img {{ height: 64px; width: auto; border-radius: 8px; }}
    .guide-link {{ color: var(--lavender); text-decoration: none; font-size: .95rem; display: inline-block; margin-top: 20px; }}
    .guide-link:hover {{ text-decoration: underline; }}
    .trust {{
      margin: 28px auto 0; display: inline-flex; gap: 14px; flex-wrap: wrap; justify-content: center;
      color: var(--dim); font-size: .85rem;
      border: 1px solid var(--line); border-radius: 999px; padding: 8px 20px; background: var(--surface);
    }}
    .dot {{ color: var(--lavender); }}

    .shots {{ padding: 48px 0 24px; }}
    .shots-row {{ display: flex; gap: 28px; justify-content: center; flex-wrap: wrap; }}
    .shot {{ text-align: center; width: 240px; }}
    .shot img {{
      width: 240px; border-radius: 26px; border: 1px solid var(--line);
      box-shadow: 0 16px 48px rgba(0, 0, 0, .55);
    }}
    .shot figcaption {{ margin-top: 14px; color: var(--dim); font-size: .88rem; }}
    @media (max-width: 560px) {{
      .shots-row {{ flex-wrap: nowrap; overflow-x: auto; justify-content: flex-start; scroll-snap-type: x mandatory; padding-bottom: 8px; }}
      .shot {{ flex: 0 0 auto; scroll-snap-align: center; }}
    }}

    .features {{ padding: 56px 0; }}
    .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(290px, 1fr)); gap: 16px; }}
    .card {{
      background: var(--surface); border: 1px solid var(--line); border-radius: 18px; padding: 26px 24px;
      transition: border-color .15s ease, background .15s ease;
    }}
    .card:hover {{ border-color: rgba(167, 139, 250, .45); background: var(--surface-hi); }}
    .card .ico {{
      display: inline-flex; align-items: center; justify-content: center;
      width: 44px; height: 44px; border-radius: 12px; font-size: 1.3rem;
      background: rgba(167, 139, 250, .12); margin-bottom: 14px;
    }}
    .card h3 {{ font-size: 1.02rem; font-weight: 700; margin-bottom: 6px; }}
    .card p {{ color: var(--dim); font-size: .92rem; }}

    .cta {{ text-align: center; padding: 72px 0 88px; border-top: 1px solid var(--line); }}
    .cta h2 {{ font-size: clamp(1.4rem, 3.6vw, 2rem); font-weight: 800; letter-spacing: -0.02em; }}
    .cta .badge-row {{ margin-top: 28px; }}

    footer {{ border-top: 1px solid var(--line); padding: 32px 0 48px; color: var(--dim); font-size: .85rem; text-align: center; }}
    footer a {{ color: var(--dim); text-decoration: none; }}
    footer a:hover {{ color: var(--lavender); }}
    footer .links {{ display: flex; gap: 20px; justify-content: center; flex-wrap: wrap; margin-bottom: 14px; }}
  </style>
</head>
<body>
  <div class="aurora"></div>

  <nav>
    <div class="wrap nav-inner">
      <a class="brand" href="/"><img src="/assets/icon.png" alt="">Loop</a>
    </div>
  </nav>

  <main class="wrap">

    <div class="lang-row">{lang_btns}</div>

    <section class="hero">
      <img class="icon" src="/assets/icon.png" alt="Loop app icon">
      <h1>{spans(h1)}</h1>
      <p class="sub">{spans(SUB)}</p>
      {badge_block()}
      {guide_link()}
      <div><span class="trust">{spans(TRUST)}</span></div>
    </section>

    <section class="shots">
      <div class="shots-row">
        {shots_html}
      </div>
    </section>

    <section class="features">
      <div class="grid">
        {features_html}
      </div>
    </section>

    <section class="cta">
      <h2>{spans(CTA)}</h2>
      {badge_block()}
      {guide_link()}
    </section>

  </main>

  <footer>
    <div class="wrap">
      <div class="links">{footer_links}</div>
      <div>© 2026 Loop</div>
    </div>
  </footer>

  <script>
    (function () {{
      var LANGS = {json.dumps(LANG_IDS)};
      var TITLES = {titles_json};
      var BADGES = {badges_json};
      var ALTS = {alts_json};

      function detect() {{
        var n = (navigator.language || "en").toLowerCase();
        if (n.indexOf("zh") === 0) return "zh";
        for (var i = 0; i < LANGS.length; i++) {{
          if (n.indexOf(LANGS[i]) === 0) return LANGS[i];
        }}
        return "en";
      }}

      function apply(l) {{
        document.documentElement.dataset.lang = l;
        document.documentElement.lang = l;
        document.title = TITLES[l];
        document.querySelectorAll("[data-set-lang]").forEach(function (b) {{
          b.classList.toggle("on", b.dataset.setLang === l);
        }});
        document.querySelectorAll("[data-badge]").forEach(function (img) {{
          img.src = BADGES[l];
          img.alt = ALTS[l];
        }});
        document.querySelectorAll("[data-shot]").forEach(function (img) {{
          img.src = "/assets/shots/" + l + "/" + img.dataset.shot + ".webp";
        }});
        try {{ localStorage.setItem("loop-lang", l); }} catch (e) {{}}
      }}

      var saved = null;
      try {{ saved = localStorage.getItem("loop-lang"); }} catch (e) {{}}
      var lang = saved && LANGS.indexOf(saved) >= 0 ? saved : detect();

      document.querySelectorAll("[data-set-lang]").forEach(function (b) {{
        b.addEventListener("click", function () {{ apply(b.dataset.setLang); }});
      }});
      apply(lang);
    }})();
  </script>
</body>
</html>
"""
    with open(os.path.join(out, "index.html"), "w", encoding="utf-8") as f:
        f.write(page)
    dst_assets = os.path.join(out, "assets")
    os.makedirs(dst_assets, exist_ok=True)
    shutil.copyfile(
        os.path.join(ROOT, "icon", "store_icon_512.png"),
        os.path.join(dst_assets, "icon.png"),
    )
    for src_lang in {image_lang(l) for l in LANG_IDS}:
        dst = os.path.join(dst_assets, "shots", src_lang)
        os.makedirs(dst, exist_ok=True)
        for name, _ in SHOTS:
            shutil.copyfile(
                os.path.join(ROOT, "assets", "guide", src_lang, f"{name}.webp"),
                os.path.join(dst, f"{name}.webp"),
            )


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    build(sys.argv[1])
    print("ok")
