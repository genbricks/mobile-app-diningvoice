# DiningVoice Mobile App

Native iOS (Swift/SwiftUI) and Android (Kotlin/Jetpack Compose) mobile applications for the [DiningVoice](https://github.com/genbricks/DiningVoice) AI-powered guest feedback platform.

## Overview

DiningVoice captures guest feedback at the table — via voice or text — in any language, then transcribes, translates, scores for sentiment/urgency, and classifies it to a specific department and category so the right team can act the same shift.

This mobile app provides:
- **Voice recording** with real-time waveform visualization
- **Text feedback** submission with AI spell-check
- **Dashboard** with sentiment analytics, department breakdown, and trend charts
- **Submissions** list with full transcription, translation, and sentiment display
- **Incidents** management (admin) — open/close incident tracking
- **Public feedback** form for guest-facing QR code flow
- **Secure auth** with JWT (password + OTP)
- **Dark mode** support
- **Responsive layouts** for phones and tablets

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│   iOS App        │     │  Android App     │
│   Swift/SwiftUI  │     │  Kotlin/Compose  │
│   iOS 17+        │     │  API 26+ (8.0)   │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         │   X-DiningVoice-Auth   │
         └──────────┬─────────────┘
                    │
         ┌──────────▼──────────┐
         │  DiningVoice API    │
         │  FastAPI / Lambda   │
         │  diningvoice-api    │
         │  .genbricks.io      │
         └─────────────────────┘
```

Both apps connect to the same REST API via the `X-DiningVoice-Auth` custom JWT header.

## iOS

### Requirements
- Xcode 15+
- iOS 17.0+
- Swift 5.9+

### Project Structure

```
ios/DiningVoice/DiningVoice/
├── App/                    # App entry point, ContentView, Configuration
├── Models/                 # Codable data models (User, Submission, Analytics, Incident)
├── ViewModels/             # @MainActor ObservableObject view models
├── Views/
│   ├── Auth/               # Login, Register, ForgotPassword
│   ├── Dashboard/          # Analytics dashboard with Swift Charts
│   ├── Feedback/           # Voice recorder, text input, public feedback
│   ├── Submissions/        # Submission list with cards
│   ├── Incidents/          # Incident queue and close flow
│   ├── Settings/           # Account, theme, about
│   └── Shared/             # SentimentBadge, StatCard, AudioWaveform, etc.
├── Services/
│   ├── NetworkService.swift      # async/await networking with URLSession
│   ├── KeychainService.swift     # Secure token storage
│   └── AudioRecorderService.swift # AVAudioRecorder wrapper
├── Utils/                  # AppColors, ThemeManager
├── Extensions/
└── Resources/              # Info.plist
```

### Key Design Decisions

- **SwiftUI-native** — no UIKit bridges; all views are pure SwiftUI
- **MVVM** with `@StateObject` / `@EnvironmentObject` for dependency injection
- **async/await** networking via `URLSession` (no third-party HTTP libraries)
- **Keychain** for secure JWT storage (not UserDefaults)
- **Swift Charts** for dashboard visualizations (donut, line, bar)
- **AVAudioRecorder** with real-time metering for voice feedback
- **Adaptive layout** — views use `LazyVGrid`, `GeometryReader`, and dynamic type for all screen sizes

### Building

Open `ios/DiningVoice/DiningVoice.xcodeproj` in Xcode, select a simulator or device, and build. The API base URL switches between localhost (debug) and production (release) via `Configuration.swift`.

## Android

### Requirements
- Android Studio Hedgehog+
- Kotlin 1.9+
- Minimum SDK 26 (Android 8.0)
- Target SDK 34 (Android 14)

### Project Structure

```
android/app/src/main/java/io/genbricks/diningvoice/
├── DiningVoiceApp.kt          # Hilt application
├── MainActivity.kt            # Single-activity Compose host
├── ui/
│   ├── DiningVoiceNavHost.kt  # Navigation graph + bottom bar
│   ├── theme/Theme.kt         # Material 3 color schemes
│   └── screens/
│       ├── AuthViewModel.kt
│       ├── LoginScreen.kt
│       ├── DashboardScreen.kt
│       ├── RecordScreen.kt
│       ├── SubmissionsScreen.kt
│       ├── IncidentsScreen.kt
│       ├── SettingsScreen.kt
│       └── PublicFeedbackScreen.kt
├── data/
│   ├── api/DiningVoiceApi.kt        # Retrofit API interface
│   ├── model/Models.kt              # Data classes
│   └── repository/AuthRepository.kt # DataStore-backed auth
└── di/AppModule.kt                  # Hilt DI module
```

### Key Design Decisions

- **Jetpack Compose** — fully declarative UI, no XML layouts
- **Material 3** with dynamic theming on Android 12+
- **Hilt** for dependency injection
- **Retrofit + OkHttp** for networking with auth interceptor
- **DataStore** for secure preferences (replaces SharedPreferences)
- **Navigation Compose** for single-activity architecture
- **Edge-to-edge** display with status/nav bar transparency

### Building

```bash
cd android
./gradlew assembleDebug
```

Debug builds use `http://10.0.2.2:8000/api` (emulator localhost); release builds use the production API.

## Mobile UX Adaptations

Compared to the web SPA, the mobile apps make these UX modifications:

1. **Tab bar navigation** instead of sidebar — 4-5 tabs fit phone width cleanly
2. **Pull-to-refresh** on all list/dashboard views
3. **Bottom sheet** for incident close dialog instead of modal
4. **Compact stat cards** — 2-column grid on phone, expanding on tablet
5. **Expandable submission cards** — text truncated to 3-4 lines with "Show more"
6. **Native audio recording** with permission handling and real-time waveform
7. **Segmented control** for sentiment filter (Incidents) instead of route-based tabs
8. **Haptic feedback** on recording start/stop
9. **Safe area** handling for notched displays and Dynamic Island
10. **Dynamic Type** support for accessibility scaling (iOS)
11. **Edge-to-edge** display with transparent system bars (Android)
12. **Deep link** support for `/customer-feedback` QR codes (Android intent filter, iOS universal links)

## API Configuration

Both apps use the `X-DiningVoice-Auth` custom header for JWT authentication, matching the web frontend.

| Setting | iOS | Android |
|---|---|---|
| API Base URL (debug) | `http://localhost:8000/api` | `http://10.0.2.2:8000/api` |
| API Base URL (release) | `https://diningvoice-api.genbricks.io/api` | Same |
| Auth header | `X-DiningVoice-Auth` | Same |
| Request timeout | 30s | 30s |
| Upload timeout | 60s | 60s |

## License

See [LICENSE](LICENSE).
