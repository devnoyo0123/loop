# Loop 개인정보처리방침 (초안)

> 스토어 등록용. GitHub Pages 등 **공개 URL**에 올린 뒤 그 주소를 Play Console
> "개인정보처리방침" 필드에 넣는다. ⚑ = 올리기 전 사용자 확정 필요.
> 광고(AdMob)를 출시 직후 넣을 계획이라 정책에도 처음부터 포함했다 —
> "광고 있음" 선언과 정책 내용이 어긋나면 심사 지적 사유가 된다.

---

## 한국어

**최종 수정: 2026-10-18 · 버전 1.0**

Loop(이하 "앱")은 기기 안에서만 동작하는 기록 앱입니다. 최소한의 정보만 수집하며, 회원가입이나 계정이 없습니다.

### 1. 수집·저장하는 정보

- **로그 내용**: 사용자가 작성한 텍스트, 첨부한 사진 — **기기 내부(SQLite 데이터베이스)에만 저장**되고 서버로 전송되지 않습니다.
- **위치 정보**: 위치 기록 기능이 켜져 있을 때(기본 켬, 설정에서 끌 수 있음) 로그 저장 순간의 좌표를 기기에 저장하고, 좌표를 주소로 바꾸는 역지오코딩에 사용합니다. 화면에는 도시·구 단위 장소명만 표시되고 좌표 값 자체는 노출되지 않습니다.
- **날씨 정보**: 로그 저장 순간의 날씨를 표시하기 위해 **기기의 좌표를 Open-Meteo(open-meteo.com) 날씨 API로 전송**합니다. Open-Meteo의 개인정보 처리는 해당 서비스의 정책을 따릅니다: https://open-meteo.com/en/terms

### 2. 기기를 떠나는 정보

좌표 → 날씨 API 전송이 유일합니다. 로그 본문·사진·검색 기록은 그 어떤 서버로도 전송되지 않으며, 개발자도 열어볼 수 없습니다.

### 3. 자동 백업

앱은 안드로이드 OS의 자동 백업을 사용합니다. 기기의 앱 데이터(로그 포함)는 사용자의 **구글 계정 백업**에 저장될 수 있으며, 이는 Google의 개인정보 처리 방침(https://policies.google.com/privacy)에 따릅니다. 기기 간 이전(스마트 스위치 등)에도 동일하게 사용자의 구글 계정 또는 직접 연결을 통해서만 이동합니다.

### 4. 광고

앱은 무료로 제공되며 Google AdMob 광고를 표시합니다.

- Google AdMob은 광고 제공을 위해 **광고 ID** 등의 정보를 수집할 수 있습니다. Google의 광고 정책: https://policies.google.com/technologies/ads
- 유럽 경제 지역(EEA) 사용자에게는 동의 관리(UMP) 화면을 제공합니다.
- 광고 개인 최적화를 원하지 않으면 기기 설정 → Google → 광고에서 광고 ID 삭제 또는 개인 최적화 해제를 할 수 있습니다.

### 5. 권한

- **알림**: 예약한 루프(알림·알람)를 울리기 위해
- **위치**: 로그에 장소·날씨를 자동 기록하기 위해 (설정에서 끌 수 있음)
- **사진**: 사용자가 첨부를 고른 사진만 읽기 위해

### 6. 데이터 삭제

- 앱을 삭제하면 기기에 저장된 모든 로그·사진이 함께 삭제됩니다.
- "설정 → 전체 내보내기"로 만든 백업 파일은 사용자가 직접 보관하며, 앱 밖에서 관리됩니다.
- 구글 자동 백업 삭제: 기기 설정 → Google → 백업에서 초기화할 수 있습니다.

### 7. 아동

앱은 13세 미만 아동을 대상으로 하지 않으며, 아동으로부터 고의로 정보를 수집하지 않습니다.

### 8. 문의

문의: `theloopapp.official@gmail.com`

---

## English

**Last updated: October 18, 2026 · Version 1.0**

Loop (the "App") is a journaling app that works entirely on your device. There is no sign-up and no account.

### 1. Information we collect and store

- **Log content**: Text you write and photos you attach — stored **only on your device** (in a local SQLite database) and never sent to a server.
- **Location**: When location capture is enabled (on by default; you can turn it off in Settings), the app stores the coordinates of the moment you save a log and uses them for reverse geocoding (turning coordinates into a place name). Coordinates are never displayed — only a city/district-level place name.
- **Weather**: To show the weather at the moment of a log, the app **sends the device's coordinates to the Open-Meteo weather API (open-meteo.com)**. Open-Meteo's handling of data is governed by its terms: https://open-meteo.com/en/terms

### 2. Information that leaves your device

Only the coordinates sent to the weather API. Log text, photos, and search history are never transmitted to any server and cannot be accessed by the developer.

### 3. Automatic backup

The app uses Android's automatic backup. Your app data (including logs) may be stored in your **Google account backup**, governed by Google's Privacy Policy (https://policies.google.com/privacy). Device-to-device transfers (e.g., Smart Switch) move data only through your own devices and/or Google account.

### 4. Advertising

The App is free and shows ads via Google AdMob.

- Google AdMob may collect information such as the **advertising ID** to serve ads. Google's advertising policies: https://policies.google.com/technologies/ads
- Users in the EEA are shown a consent management (UMP) form.
- You can delete your advertising ID or reset ad personalization in device Settings → Google → Ads.

### 5. Permissions

- **Notifications**: to fire the loops (reminders/alarms) you scheduled
- **Location**: to automatically attach place & weather to logs (can be disabled)
- **Photos**: to read only the photos you choose to attach

### 6. Data deletion

- Uninstalling the App deletes all logs and photos stored on the device.
- Backup files created via "Settings → Export" live outside the App and are under your control.
- Google automatic backups can be deleted in device Settings → Google → Backup.

### 7. Children

The App is not directed at children under 13 and does not knowingly collect their information.

### 8. Contact

Contact: `theloopapp.official@gmail.com`
