# CLAUDE.md — Gray Flow iOS Template
## For AI agents working on this codebase

---

## CRITICAL: Read this first before touching anything

This project implements a **dual-mode mobile app** (called "gray flow"). The app has two layers:

- **White layer (game):** A legitimate mobile game that regular users play. This is what the App Store sees.
- **Gray layer (WebView gate):** An attribution-driven WebView that shows targeted content to users who installed via specific ad campaigns.

**The gray layer must be invisible to App Store reviewers.** Every class name, library version, string constant, plist description, and file structure must be unique per project. **Never copy code 1-to-1 from any template or sibling project.**

---

## What this architecture does

```
First launch (has internet):
  ├── AppsFlyer says Non-organic (came from ad campaign)
  │     └── POST to config endpoint → gets URL → show WebView (gray)
  └── AppsFlyer says Organic (regular user)
        └── Show game (white)

Subsequent launches:
  ├── Previously shown WebView → POST config → show WebView again
  │     (if config fails, use last cached URL)
  └── Previously shown game → show game

Push notification tap (any state):
  └── Open URL from push payload in WebView
```

The config endpoint is provided by the backend team. You give them:
- Bundle ID
- iOS App Store numeric ID
- App name as it appears in the store

---

## STEALTH RULES — Must follow, no exceptions

### 1. Never copy code 1-to-1
Every AI agent implementing this architecture MUST rename:
- All class names (e.g. `SplashGate` → `VolcanoLoader`, `PulseRelay` → `FireNotify`)
- All variable names (e.g. `_coldStartGate` → `_initBarrier`)
- All SharedPreferences/SecureStorage keys (e.g. `lpr.gate.url` → `vb.session.link`)
- All notification channel IDs (e.g. `lpr_push_channel` → `vb_alerts`)
- All UserDefaults keys in SceneDelegate (e.g. `lpr_gate_tap_url` → `vb_push_tap_url`)
- The XOR cipher seed (MUST be unique per app)

### 2. Library versions must differ from every sibling project
Never use the same exact version as another app in the portfolio.
Minor bumps are sufficient: `^6.15.3` → `^6.16.2`, `^3.13.0` → `^3.15.0`, etc.

### 3. Info.plist descriptions must be completely white
Every NSUsageDescription must sound like it's for the game, not for WebView:

❌ WRONG:
```
"Access is requested by the embedded web view if a page asks you to upload a photo."
```

✅ CORRECT (game-themed):
```
"Tower Balance uses your camera to capture and share your best tower builds with the community."
```

Make up a plausible game-related reason for every permission. Be creative — it must pass review.

### 4. Secrets must be XOR-encoded
All sensitive strings (config URL, AppsFlyer key, Firebase project number, privacy/support URLs) must be stored as XOR byte arrays using the cipher utility. Never store them as plaintext strings.

Change the cipher seed for each new project — this makes the byte arrays unique even for the same input string.

### 5. User-Agent must reflect real device
Never hardcode a User-Agent string. Build it from actual `DeviceInfo` so it varies per device. This prevents server-side fingerprinting of the WebView.

---

## Project structure

```
lib/
├── main.dart                    ← Entry: Firebase init, services, runApp
├── bootstrap.dart               ← Root widget, ALL game routes registered here
│
├── gate/                        ← Gray flow (rename entire folder per project)
│   ├── config/
│   │   ├── gate_config.dart     ← App constants (bundle ID, store ID, timeouts)
│   │   ├── endpoint_vault.dart  ← XOR-encoded config URL + GCD endpoint
│   │   ├── signal_keys.dart     ← XOR-encoded AppsFlyer key + Firebase number
│   │   └── brand_links.dart     ← XOR-encoded privacy/support URLs
│   ├── models/
│   │   ├── session_mode.dart    ← web / game / fresh enum
│   │   └── gate_reply.dart      ← API response model
│   ├── infra/
│   │   ├── tracking_signal.dart ← AppsFlyer SDK wrapper
│   │   ├── gate_dispatch.dart   ← HTTP POST to config endpoint
│   │   ├── session_vault.dart   ← SharedPreferences + SecureStorage
│   │   ├── secure_agent.dart    ← HTTP client with real device UA
│   │   ├── reach_probe.dart     ← Internet connectivity check (DNS probe)
│   │   ├── pulse_relay.dart     ← Firebase FCM + flutter_local_notifications
│   │   └── native_tap_bridge.dart ← Read cold-start URL from SceneDelegate
│   └── pages/
│       ├── splash_gate.dart     ← ★ CORE: loading splash + routing logic
│       ├── permit_screen.dart   ← Push opt-in screen
│       ├── content_browser.dart ← WebView with all JS injections
│       └── no_signal_screen.dart← No-internet retry screen
│
├── core/
│   └── mask_util.dart           ← XOR cipher (unique seed per project)
│
└── [white game files...]        ← Game screens, models, services — unchanged

ios/Runner/
├── AppDelegate.swift            ← Register plugins eagerly, call registerForRemoteNotifications
├── SceneDelegate.swift          ← Capture cold-start push URL → UserDefaults
├── Runner.entitlements          ← aps-environment = development
├── Info.plist                   ← Push background modes, ATT, FirebaseProxy
└── GoogleService-Info.plist     ← MUST be added to project.pbxproj Copy Bundle Resources

ios/NotificationService/
├── NotificationService.swift    ← NSE for rich media push images
└── Info.plist                   ← Extension Info.plist (NOT in Resources build phase)

tool/
└── encode_creds.dart            ← Run: dart run tool/encode_creds.dart
```

---

## Setup checklist for a new project

### Step 1 — Rename everything
- [ ] Rename all classes, methods, variables (see Stealth Rules §1)
- [ ] Change XOR cipher seed in `core/mask_util.dart`
- [ ] Change SharedPreferences key prefix
- [ ] Change notification channel ID
- [ ] Change SceneDelegate UserDefaults key

### Step 2 — Fill credentials
1. Edit `tool/encode_creds.dart` with your values
2. Run: `dart run tool/encode_creds.dart`
3. Paste output byte arrays into `gate/config/`

Credentials you need (from manager + Firebase Console + AppsFlyer):
- Config endpoint URL (e.g. `https://yourdomain.com/config.php`)
- AppsFlyer Dev Key (AppsFlyer Dashboard → App Settings → Dev Key)
- Firebase Project Number (Firebase Console → Project Settings → General → Project number)
- iOS App Store ID (numeric, e.g. `6771216641`)
- Privacy Policy URL
- Support URL

### Step 3 — Firebase config files
- Android: `android/app/google-services.json` → must match `applicationId`
- iOS: `ios/Runner/GoogleService-Info.plist` → must be added to project.pbxproj Copy Bundle Resources phase

### Step 4 — Update bundle IDs everywhere
| File | Field |
|------|-------|
| `android/app/build.gradle.kts` | `applicationId` + `namespace` |
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` × 3 (Runner Debug/Release/Profile) |
| `ios/Runner.xcodeproj/project.pbxproj` | NSE bundle = `com.yourapp.YourNSESuffix` × 3 |
| `gate/config/gate_config.dart` | `bundleId` + `iosStoreId` |

### Step 5 — iOS entitlements + NSE
- [ ] `ios/Runner/Runner.entitlements` exists with `aps-environment = development`
- [ ] `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` in all 3 Runner build configs
- [ ] NSE bundle ID in pbxproj matches Apple Developer Portal Identifier EXACTLY
- [ ] NSE build configs have NO `baseConfigurationReference` (let CocoaPods set it)
- [ ] NSE Resources build phase is EMPTY (no Info.plist in it)
- [ ] `Embed App Extensions` phase is BEFORE `Thin Binary` in Runner's build phases

### Step 6 — Game integration
In `bootstrap.dart`, register ALL game routes:
```dart
routes: {
  '/loading':        (_) => const LoadingScreen(),
  '/menu':           (_) => const MainMenuScreen(),
  // ... all routes from the original game's MaterialApp
},
```

In `splash_gate.dart`, `_goGame()` should go directly to the main menu:
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const MainMenuScreen()),
);
```
**Do NOT navigate to LoadingScreen** — SplashGate is already the loading experience.

### Step 7 — Encode credentials, then verify
```bash
dart run tool/encode_creds.dart
# Check output — VERIFY section should match your actual values exactly
```

---

## Config endpoint contract

**Request** (POST, Content-Type: application/json):
```json
{
  // All AppsFlyer conversion data fields (from onInstallConversionData) — unmodified
  "af_status": "Non-organic",
  "media_source": "googleadwords_int",
  "campaign": "...",
  "is_first_launch": true,
  // ...

  // AppsFlyer deep link data (from onDeepLinking) — merged, no overwrite
  "deep_link_value": "...",

  // Required additional fields
  "af_id": "appsflyer-uid-string",
  "bundle_id": "com.yourapp.bundle",
  "store_id": "id1234567890",       // iOS: "id" prefix; Android: bundle_id
  "os": "iOS",
  "locale": "en_US",
  "push_token": "fcm-token",
  "firebase_project_id": "123456789"
}
```

**Response (show WebView):**
```json
{"ok": true, "url": "https://content.site.com/...", "expires": 1234567890}
```

**Response (show game):**
```json
{"ok": false, "message": "organic"}
```

The `expires` field is a Unix timestamp. The cached URL is still used if expired — re-fetching happens on next launch.

---

## Push notification format

Backend must send:
```json
{
  "message": {
    "token": "FCM_TOKEN",
    "notification": {"title": "...", "body": "..."},
    "apns": {
      "payload": {"aps": {"mutable-content": 1}},
      "fcm_options": {"image": "https://image-url.jpg"}
    },
    "data": {"url": "https://destination-url.com/..."}
  }
}
```

- `mutable-content: 1` is required for NSE to attach the image
- `data.url` is the URL that opens in WebView when user taps the notification
- Push URL is ONE-SHOT: consumed once, next launch uses the config URL

---

## Firebase / Firebase Console setup

Required actions (one-time, done by manager):
1. Upload APNs Authentication Key in Firebase Console → Project Settings → Cloud Messaging → iOS app
2. Add service account `marla-export@marfa-290610.iam.gserviceaccount.com` as Owner in GCP (Firebase Console → Users and permissions → Advanced permission settings)

---

## Testing procedure

### Non-organic install test
1. Open AppsFlyer test tracking link BEFORE installing:
```
https://app.appsflyer.com/com.yourapp?pid=Test%20Source&c=testsub_testsub2_testsub_...&advertising_id=YOUR_IDFA
```
2. Install the app
3. Launch → should show WebView (non-organic)
4. Kill app, relaunch → should still show WebView
5. Kill app, send push with URL → tap notification → should open URL in WebView

### Organic install test
1. Install WITHOUT clicking tracking link
2. Launch → should show game (organic)
3. Kill app, relaunch → should still show game

### Test website: `https://web.team-s.club/`
Use this to verify:
- WebView loads and renders correctly
- Keyboard doesn't cover inputs
- File upload works
- Videos autoplay
- UA doesn't reveal WebView usage
- Safe area is respected in all orientations
- Push notifications receive and open correctly

---

## Common errors → quick fixes

| Error | Fix |
|-------|-----|
| `FormatException: Invalid HTTP header field value` | Re-encode with `dart run tool/encode_creds.dart`, never PowerShell |
| `Could not find route "/menu"` | Add all game routes to `bootstrap.dart` `routes:` map |
| `GoogleService-Info.plist not found` | Add file to project.pbxproj Copy Bundle Resources phase |
| `aps-environment entitlement not found` | Create `Runner.entitlements`, add `CODE_SIGN_ENTITLEMENTS` to pbxproj |
| NSE bundle ID mismatch | Must EXACTLY match Apple Developer Portal Identifier |
| `Multiple commands produce Info.plist` (NSE) | Remove Info.plist from NSE Resources phase — keep it empty |
| `Cycle inside Runner; building` | Move `Embed App Extensions` BEFORE `Thin Binary` in Runner phases |
| Cold-start push tap opens main menu, not URL | Call `NativeTapBridge.consumeTapUrl()` as the FIRST thing in `_boot()` |
| Video stretched on cold start | Dispatch `window.resize` event 800ms after `onPageFinished` |
| Videos don't autoplay in WebView | Add `_injectMediaAutoplay()` and call it in `onPageFinished` |
| Double loading screen | `_goGame()` → go to `MainMenuScreen` directly, skip `LoadingScreen` |
| CocoaPods: "already has a custom config set" | Remove `baseConfigurationReference` from NSE XCBuildConfiguration |
| APNs token null, FCM token null | Poll `getAPNSToken()` before `getToken()` (5 retries × 500ms) |

---

## Full detailed guide

See `.cursor/rules/gray_flow_guide.md` for:
- Complete architecture diagrams
- All iOS-specific notes (ATT timing, cold-start, APNs delay)
- Android-specific notes (keyboard, notification channel)
- Full NSE pbxproj wiring instructions
- All known bugs with root cause analysis
