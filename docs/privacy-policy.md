# Loop 개인정보처리방침 (초안)

> 스토어 등록용. **공개 URL: https://devnoyo0123.github.io/loop-privacy/**
> (GitHub Pages, 저장소 devnoyo0123/loop-privacy — 2026-10-20 게시. 이 파일을
> 수정하면 그 저장소의 index.md에도 반영해야 한다.) ⚑ = 올리기 전 사용자 확정 필요.
> 광고(AdMob)를 출시 직후 넣을 계획이라 정책에도 처음부터 포함했다 —
> "광고 있음" 선언과 정책 내용이 어긋나면 심사 지적 사유가 된다.

---

## 한국어

**최종 수정: 2026-11-17 · 버전 1.4** (PC 연결 — 로컬 네트워크 브리지)

Loop(이하 "앱")은 기기 안에서만 동작하는 기록 앱입니다. 최소한의 정보만 수집하며, 회원가입이나 계정이 없습니다.

### 1. 수집·저장하는 정보

- **로그 내용**: 사용자가 작성한 텍스트, 첨부한 사진 — **기기 내부(SQLite 데이터베이스)에만 저장**되고 서버로 전송되지 않습니다.
- **위치 정보**: 위치 기록 기능이 켜져 있을 때(기본 켬, 설정에서 끌 수 있음) 로그 저장 순간의 좌표를 기기에 저장하고, 좌표를 주소로 바꾸는 역지오코딩에 사용합니다. 화면에는 도시·구 단위 장소명만 표시되고 좌표 값 자체는 노출되지 않습니다.
- **날씨 정보**: 로그 저장 순간의 날씨를 표시하기 위해 **기기의 좌표를 Open-Meteo(open-meteo.com) 날씨 API로 전송**합니다. Open-Meteo의 개인정보 처리는 해당 서비스의 정책을 따릅니다: https://open-meteo.com/en/terms
- **공유 표시명·기기 식별자**: 근거리 공유를 처음 사용할 때 앱이 무작위 식별자를 만들어 기기에 저장합니다. 기기의 하드웨어·광고 식별자와 무관하며, 앱을 다시 설치하면 새로 만들어집니다. 표시명은 사용자가 정하며 기본값은 기기 이름입니다.

### 2. 기기를 떠나는 정보

- **서버로 가는 정보**: 좌표 → 날씨 API 전송이 유일합니다. 로그 본문·사진·검색 기록은 그 어떤 서버로도 전송되지 않으며, 개발자도 열어볼 수 없습니다.
- **사용자가 직접 보내는 근거리 공유**: 아래 "근거리 공유"를 사용자가 실행할 때에만, 선택한 기록이 **옆에 있는 상대 기기로 직접** 전송됩니다(서버·인터넷을 거치지 않음).
- **사용자가 연결한 "PC 연결"**: 아래 2-2에서 사용자가 자신의 컴퓨터에 연결한 동안에만, 그 컴퓨터의 프로그램이 기록을 검색해 읽어 갈 수 있습니다.

### 2-1. 근거리 공유

- **동작**: 사용자가 기록의 "Loop 공유 → 가까운 기기로 보내기"를 실행하고 목록에서 받을 기기를 고르면, Google Play 서비스의 Nearby Connections(블루투스·Wi-Fi Direct 등)를 통해 기기끼리 직접 전송합니다. 개발자 서버를 거치지 않으며 개발자는 내용을 볼 수 없습니다.
- **상대에게 전달되는 것**: 선택한 기록(이어진 기록이 있으면 그 사슬 전체)의 본문, 사진·동영상(보내기 전에 뺄 수 있음), 반복 설정, 공유 표시명과 무작위 기기 식별자. **위치 정보(좌표·장소)는 기본으로 제외**되며, 사용자가 포함하도록 바꿨을 때만 함께 갑니다.
- **받기**: 설정의 "가까운 기기에서 받기"를 켠 동안, 앱이 열려 있을 때 주변 Loop 기기에 공유 표시명이 보입니다. 받은 기록은 사용자가 [가져오기]를 눌러야 저장되며, [거절]하면 저장되지 않습니다.
- **임시 파일**: 전송 중 파일은 앱 전용 저장 공간에만 두고, 전송이 끝나거나 중단되면 삭제합니다(설정 › 공유 임시 파일 정리로 직접 지울 수도 있음).
- 상대 기기로 넘어간 기록은 상대가 관리하며, 보낸 쪽에서 회수할 수 없습니다.

### 2-2. PC 연결 (로컬 네트워크 브리지)

- **동작**: 설정의 "PC 연결"에서 사용자가 자신의 컴퓨터 주소를 입력해 연결하면, 앱이 **사용자 컴퓨터에서 실행 중인 프로그램**(예: Claude Code의 Loop 플러그인)에 클라이언트로 접속합니다. 최초 1회 8자리 페어링 코드로 서로를 확인하고, 이후 같은 컴퓨터에는 자동으로 다시 연결됩니다. 컴퓨터 프로그램은 요청 시에만 기록 검색 질의를 보내고 앱이 결과로 응답하며, 개발자 서버를 거치지 않습니다.
- **전달될 수 있는 것**: 기록 본문, 작성 날짜·시각, 날씨, 사진·동영상 개수, 그리고 **장소명과 위치 좌표(위도·경도)**. 사진·동영상 파일 자체는 전달되지 않습니다. 기록을 바꾸거나 지울 수는 없습니다.
- **AI 서비스로의 전송**: 연결된 컴퓨터의 AI 도구는 검색 결과를 그 AI 서비스(예: Anthropic)로 보낼 수 있으며, 이는 해당 서비스의 개인정보 처리 방침을 따릅니다.
- **보안**: 통신은 같은 Wi-Fi 안에서만 이루어지며, 최초 1회 8자리 페어링 코드와 기기별 보안 키로 연결된 컴퓨터만 질의할 수 있습니다. 로컬 네트워크 통신은 암호화되지 않으므로 공용 Wi-Fi(카페·공항 등)에서는 연결하지 마세요. 폰에서 언제든 연결을 끊거나 페어링을 해제할 수 있습니다.

### 3. 자동 백업

앱은 안드로이드 OS의 자동 백업을 사용합니다. 기기의 앱 데이터(로그 포함)는 사용자의 **구글 계정 백업**에 저장될 수 있으며, 이는 Google의 개인정보 처리 방침(https://policies.google.com/privacy)에 따릅니다. 기기 간 이전(스마트 스위치 등)에도 동일하게 사용자의 구글 계정 또는 직접 연결을 통해서만 이동합니다.

### 4. 광고

앱은 무료로 제공되며 Google AdMob 광고를 표시합니다.

- Google AdMob은 광고 제공을 위해 **광고 ID** 등의 정보를 수집할 수 있습니다. Google의 광고 정책: https://policies.google.com/technologies/ads
- 유럽 경제 지역(EEA) 사용자에게는 동의 관리(UMP) 화면을 제공합니다.
- 광고 개인 최적화를 원하지 않으면 기기 설정 → Google → 광고에서 광고 ID 삭제 또는 개인 최적화 해제를 할 수 있습니다.

### 5. 권한

- **알림**: 예약한 루프(알림·알람)를 울리기 위해
- **위치**: 로그에 장소·날씨를 자동 기록하기 위해 (설정에서 끌 수 있음). Android 12 이하에서는 근거리 공유의 주변 기기 찾기에도 필요합니다(운영체제 요구 사항).
- **사진**: 사용자가 첨부를 고른 사진만 읽기 위해
- **근처 기기(블루투스·Wi-Fi)**: 근거리 공유로 주변 기기를 찾고 연결하기 위해. 공유를 보내거나 받기를 켤 때에만 요청합니다.

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

**Last updated: November 17, 2026 · Version 1.4** (PC connection — local network bridge)

Loop (the "App") is a journaling app that works entirely on your device. There is no sign-up and no account.

### 1. Information we collect and store

- **Log content**: Text you write and photos you attach — stored **only on your device** (in a local SQLite database) and never sent to a server.
- **Location**: When location capture is enabled (on by default; you can turn it off in Settings), the app stores the coordinates of the moment you save a log and uses them for reverse geocoding (turning coordinates into a place name). Coordinates are never displayed — only a city/district-level place name.
- **Weather**: To show the weather at the moment of a log, the app **sends the device's coordinates to the Open-Meteo weather API (open-meteo.com)**. Open-Meteo's handling of data is governed by its terms: https://open-meteo.com/en/terms
- **Sharing display name & device identifier**: The first time you use nearby sharing, the app creates a random identifier and stores it on your device. It is unrelated to hardware or advertising IDs and is regenerated if you reinstall the app. You choose the display name; it defaults to your device name.

### 2. Information that leaves your device

- **To a server**: Only the coordinates sent to the weather API. Log text, photos, and search history are never transmitted to any server and cannot be accessed by the developer.
- **Nearby sharing you start yourself**: Only when you use "Nearby sharing" below, the logs you select are sent **directly to a nearby device** (no server or internet involved).
- **"PC connection", while you have it connected**: Only while a computer is connected via 2-2 below, the program running on **your own computer** can search and read your logs.

### 2-1. Nearby sharing

- **How it works**: When you choose "Share Loop → Send to a nearby device" on a log and pick a receiving device from the list, the logs are transferred device-to-device through Google Play services' Nearby Connections (Bluetooth, Wi-Fi Direct, etc.). Nothing passes through the developer's servers, and the developer cannot see the content.
- **What the other person receives**: the text of the selected log (and the whole chain if other logs continue from it), photos and videos (you can leave them out before sending), repeat settings, your sharing display name and random device identifier. **Location (coordinates and place) is excluded by default** and is sent only if you choose to include it.
- **Receiving**: While "Receive from nearby devices" is on in Settings and the app is open, nearby Loop devices can see your display name. Received logs are saved only if you tap Import; if you decline, nothing is saved.
- **Temporary files**: Files in transit are kept only in the app's private storage and deleted when a transfer finishes or stops (you can also clear them in Settings › Clear sharing temp files).
- Logs delivered to another device are managed by its owner and cannot be recalled by the sender.

### 2-2. PC connection (local network bridge)

- **How it works**: In Settings → "PC connection", you enter your computer's address and connect. The App then connects as a **client to the program running on your computer** (e.g., the Loop plugin for Claude Code). The first time, an 8-digit pairing code confirms both sides; afterwards the App reconnects to the same computer automatically. The computer program only sends journal search queries when you ask for them, and the App answers with results. Nothing passes through the developer's servers.
- **What may be shared**: log text, date and time, weather, the number of photos/videos, and **place names and location coordinates (latitude, longitude)**. Photo and video files themselves are not shared. Logs cannot be changed or deleted.
- **AI services**: The AI tool on the connected computer may send search results to its AI service (e.g., Anthropic), governed by that service's privacy policy.
- **Security**: Communication happens only inside the same Wi-Fi. Only computers that completed the one-time 8-digit pairing code, together with a per-device secret key, can send queries. Local network traffic is not encrypted — do not connect on public Wi-Fi (cafés, airports, etc.). You can disconnect or unpair from the phone at any time.

### 3. Automatic backup

The app uses Android's automatic backup. Your app data (including logs) may be stored in your **Google account backup**, governed by Google's Privacy Policy (https://policies.google.com/privacy). Device-to-device transfers (e.g., Smart Switch) move data only through your own devices and/or Google account.

### 4. Advertising

The App is free and shows ads via Google AdMob.

- Google AdMob may collect information such as the **advertising ID** to serve ads. Google's advertising policies: https://policies.google.com/technologies/ads
- Users in the EEA are shown a consent management (UMP) form.
- You can delete your advertising ID or reset ad personalization in device Settings → Google → Ads.

### 5. Permissions

- **Notifications**: to fire the loops (reminders/alarms) you scheduled
- **Location**: to automatically attach place & weather to logs (can be disabled). On Android 12 and below it is also required by the OS to find nearby devices for nearby sharing.
- **Photos**: to read only the photos you choose to attach
- **Nearby devices (Bluetooth & Wi-Fi)**: to find and connect to nearby devices for nearby sharing. Requested only when you send or turn on receiving.

### 6. Data deletion

- Uninstalling the App deletes all logs and photos stored on the device.
- Backup files created via "Settings → Export" live outside the App and are under your control.
- Google automatic backups can be deleted in device Settings → Google → Backup.

### 7. Children

The App is not directed at children under 13 and does not knowingly collect their information.

### 8. Contact

Contact: `theloopapp.official@gmail.com`
