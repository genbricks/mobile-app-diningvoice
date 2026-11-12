# Testing Guide — MacBook M2 Pro

Complete setup and testing instructions for both iOS and Android apps on a MacBook with Apple Silicon (M1/M2/M3/M4).

---

## Prerequisites (One-Time Setup)

### 1. Install Xcode (for iOS)

Xcode is required to build and run iOS apps on the simulator or a physical device.

```bash
# Option A: App Store (recommended — includes simulator runtimes)
# Open App Store → search "Xcode" → Install
# This is a ~12 GB download, allow 30–60 minutes

# Option B: Command line (downloads from Apple CDN)
xcode-select --install   # you already have this
# But you ALSO need the full Xcode.app from the App Store
```

After installing, **launch Xcode once** to accept the license and install components:

```bash
# Accept license from terminal (or just open Xcode.app)
sudo xcodebuild -license accept

# Verify installation
xcodebuild -version
# Expected: Xcode 15.x or 16.x

# Switch active developer directory to Xcode (not CommandLineTools)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Install iOS 17 simulator runtime (if not bundled)
xcodebuild -downloadPlatform iOS
```

**Disk space needed:** ~35 GB total (Xcode + simulator runtimes)

### 2. Install Android Studio (for Android)

```bash
# Option A: Homebrew (recommended)
brew install --cask android-studio

# Option B: Manual download
# https://developer.android.com/studio → Download → Mac (Apple Silicon)
# Drag to /Applications
```

**First launch setup** — open Android Studio and complete the wizard:

1. Choose "Standard" installation type
2. Accept all SDK licenses
3. Let it download: Android SDK, SDK Platform 34, Build Tools, Emulator, Platform Tools
4. This downloads ~5 GB, allow 15–20 minutes

After the wizard finishes:

```bash
# Add Android SDK to your shell (add to ~/.zshrc for persistence)
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

# Reload shell
source ~/.zshrc

# Verify
adb version
# Expected: Android Debug Bridge version 1.0.xx

sdkmanager --version
# Expected: a version number
```

### 3. Install Java (for Android builds)

Android Studio bundles its own JDK, but Gradle command-line builds need one:

```bash
# Install JDK 17 (required for AGP 8.x)
brew install openjdk@17

# Symlink so the system finds it
sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk

# Add to ~/.zshrc
export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"

# Verify
java -version
# Expected: openjdk version "17.x.x"
```

### 4. Create an Android Emulator

```bash
# From Android Studio: Tools → Device Manager → Create Virtual Device
# Recommended for M2 Pro:
#   - Device: Pixel 7 (or Pixel 8)
#   - System Image: API 34 (arm64-v8a) — NOT x86_64
#   - RAM: 2048 MB
#   - Internal Storage: 2048 MB

# Or via command line:
sdkmanager "system-images;android-34;google_apis;arm64-v8a"
avdmanager create avd -n Pixel7_API34 -k "system-images;android-34;google_apis;arm64-v8a" -d "pixel_7"
```

> **Important:** On Apple Silicon, always pick **arm64-v8a** images, not x86_64. x86 images run in emulation and are extremely slow.

### 5. Start the DiningVoice Backend (for local testing)

The mobile apps need the API running. Clone and start the backend:

```bash
# Clone the backend
git clone https://github.com/genbricks/DiningVoice.git /tmp/DiningVoice
cd /tmp/DiningVoice/databricksapp

# Python venv
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Configure (edit with your local Postgres + AI keys)
cp backend/.env.example backend/.env

# Create local database
createdb diningvoice
# Edit backend/.env with POSTGRES_HOST=localhost, POSTGRES_DB=diningvoice, etc.

# Run the API
uvicorn backend.app.main:app --reload --port 8000

# Verify — in another terminal:
curl http://localhost:8000/health
```

If you don't have a local backend, the apps will show network errors on the login screen — this is expected. You can still verify the UI layout and navigation.

---

## Testing the iOS App

### Step 1: Open in Xcode

```bash
cd /Users/nid/mobile-app-diningvoice
open ios/DiningVoice/DiningVoice.xcodeproj
```

> **Note:** The `.xcodeproj` in this repo is a skeleton. On first open, Xcode may need you to add the Swift source files to the target. If the project navigator is empty:
>
> 1. In Xcode, right-click the project → **Add Files to "DiningVoice"**
> 2. Select the entire `DiningVoice/` source folder (App, Models, Views, etc.)
> 3. Check "Create groups" and ensure "Add to targets: DiningVoice" is checked

**Alternative — create a fresh Xcode project and add the source:**

1. Xcode → File → New → Project → iOS → App
2. Product Name: `DiningVoice`, Organization: `io.genbricks`, Interface: SwiftUI, Language: Swift
3. Save into `ios/DiningVoice/` (replacing the skeleton)
4. Delete the auto-generated ContentView.swift and DiningVoiceApp.swift
5. Drag the existing source folders (App, Models, Views, ViewModels, Services, Utils) into the project navigator
6. Ensure all `.swift` files are checked under Target Membership

### Step 2: Configure signing

1. Select the project in the navigator → **Signing & Capabilities** tab
2. Set **Team** to your Apple Developer account (free or paid)
3. Set **Bundle Identifier** to `io.genbricks.diningvoice`

For simulator-only testing, you can use "Sign to Run Locally" (no Apple Developer account needed).

### Step 3: Select a simulator

In the Xcode toolbar, pick a simulator from the device dropdown:

| Test scenario | Simulator to use |
|---|---|
| Standard phone | iPhone 15 |
| Small phone | iPhone SE (3rd gen) |
| Large phone | iPhone 15 Pro Max |
| Tablet | iPad Pro 11-inch |
| Dynamic Island | iPhone 15 Pro |

### Step 4: Build and run

```
⌘ + R  (or Product → Run)
```

Build time: ~30 seconds first build, ~5 seconds incremental.

### Step 5: Test each screen

| # | Screen | What to test |
|---|---|---|
| 1 | **Login** | Both Password and OTP tabs render, form validation works, error banner shows on bad credentials |
| 2 | **Register** | Modal presents, password match validation, field layout on small screens |
| 3 | **Dashboard** | Stats grid (2 columns on phone, wider on iPad), charts render, department breakdown expands/collapses, pull-to-refresh, filter dropdown |
| 4 | **Record** | Talk/Type cards display side by side, mic permission prompt appears, voice mode shows waveform + timer, text mode shows character count |
| 5 | **Submissions** | Empty state when no data, cards show sentiment badges + truncated text, "Show more" expands, delete confirmation, infinite scroll |
| 6 | **Incidents** | Segmented control switches sentiment, stat cards update, incident cards show status chips, close sheet presents from bottom |
| 7 | **Settings** | User info card, theme toggle cycles light/dark/system, sign out confirmation |
| 8 | **Tab bar** | All 4-5 tabs visible, icons and labels fit, active tint color is purple |
| 9 | **Dark mode** | Toggle in Settings, all screens have proper contrast, charts remain readable |
| 10 | **Rotation** | iPad landscape works, phone stays portrait |

### Step 6: Test on physical device (optional)

1. Connect iPhone via USB
2. Trust the computer on the phone
3. Select the phone in the device dropdown
4. Build & Run (⌘R) — first run requires unlocking Developer Mode on the phone (Settings → Privacy → Developer Mode)

---

## Testing the Android App

### Step 1: Open in Android Studio

```bash
# Open Android Studio, then:
# File → Open → navigate to /Users/nid/mobile-app-diningvoice/android/
# Click "Open"
```

Or from terminal:

```bash
open -a "Android Studio" /Users/nid/mobile-app-diningvoice/android/
```

### Step 2: Wait for Gradle sync

Android Studio will download dependencies on first open. This takes 2–5 minutes. Watch the bottom status bar for "Gradle sync finished."

If it fails:
- Check `File → Project Structure → SDK Location` points to your Android SDK
- Check `File → Settings → Build → Gradle → Gradle JDK` is set to JDK 17

### Step 3: Create/start an emulator

1. **Tools → Device Manager** (right sidebar)
2. Click **Create Virtual Device**
3. Pick **Pixel 7** → Next
4. Pick **API 34 (arm64-v8a)** system image → Download if needed → Next
5. Name it, leave defaults → Finish
6. Click the **▶ Play** button next to the device to boot it

Test on multiple screen sizes:

| Test scenario | Virtual device |
|---|---|
| Standard phone | Pixel 7 (6.3") |
| Small phone | Pixel 4a (5.8") |
| Large phone | Pixel 7 Pro (6.7") |
| Tablet | Pixel Tablet (10.95") |
| Foldable | Pixel Fold (7.6" inner) |

### Step 4: Build and run

Click the green **▶ Run** button in the toolbar (or `Ctrl + R`).

Build time: ~90 seconds first build (Gradle downloads + compiles), ~15 seconds incremental.

### Step 5: Test each screen

Same test matrix as iOS above, plus:

| # | Android-specific test |
|---|---|
| 1 | **Edge-to-edge** — content draws behind status bar, no overlap with system bars |
| 2 | **Back button** — hardware/gesture back navigates correctly from each screen |
| 3 | **Dark mode** — toggle phone-wide: Settings → Display → Dark theme, app follows system |
| 4 | **Material You** — on API 31+ emulator, app picks up wallpaper-based dynamic colors |
| 5 | **Microphone permission** — Record screen asks for permission, handles denial gracefully |
| 6 | **Rotation** — phone locks to portrait, tablet supports landscape |
| 7 | **Deep link** — `adb shell am start -a android.intent.action.VIEW -d "https://diningvoice.genbricks.io/customer-feedback"` opens the public feedback screen |

### Step 6: Test on physical device (optional)

1. Enable **Developer Options** on phone: Settings → About Phone → tap "Build Number" 7 times
2. Enable **USB Debugging** in Developer Options
3. Connect via USB, trust the computer
4. The phone appears in the device dropdown → Run

### Step 7: Command-line build (CI)

```bash
cd /Users/nid/mobile-app-diningvoice/android

# Debug APK
./gradlew assembleDebug

# The APK is at:
ls -la app/build/outputs/apk/debug/app-debug.apk

# Install on connected device/emulator
adb install app/build/outputs/apk/debug/app-debug.apk

# Run tests
./gradlew test
```

---

## Testing Both Platforms Side by Side

Run the iOS Simulator and Android Emulator simultaneously — the M2 Pro handles both easily:

```bash
# Terminal 1: Start the backend
cd /tmp/DiningVoice/databricksapp
source venv/bin/activate
uvicorn backend.app.main:app --reload --port 8000

# Terminal 2: Start Android emulator
emulator -avd Pixel7_API34 &

# Terminal 3: Open Xcode and run iOS
open /Users/nid/mobile-app-diningvoice/ios/DiningVoice/DiningVoice.xcodeproj
# Press ⌘R

# Terminal 4: Build and install Android
cd /Users/nid/mobile-app-diningvoice/android
./gradlew installDebug
```

---

## Network Configuration Notes

| Platform | Debug API URL | Why |
|---|---|---|
| iOS Simulator | `http://localhost:8000/api` | Simulator shares the Mac's network stack |
| Android Emulator | `http://10.0.2.2:8000/api` | `10.0.2.2` is the emulator's alias for the host machine's `localhost` |
| Physical iOS device | Change to your Mac's LAN IP | E.g. `http://192.168.1.x:8000/api` in `Configuration.swift` |
| Physical Android device | Change to your Mac's LAN IP | E.g. in `app/build.gradle.kts` debug `buildConfigField` |

To find your Mac's LAN IP:

```bash
ipconfig getifaddr en0
```

---

## Troubleshooting

### iOS

| Problem | Solution |
|---|---|
| "No such module" errors | Product → Clean Build Folder (⇧⌘K), then Build again |
| Simulator not listed | Xcode → Settings → Platforms → download iOS 17 runtime |
| Signing error | Use "Sign to Run Locally" for simulator, or add your Apple ID in Xcode → Settings → Accounts |
| Microphone not working in simulator | Simulator uses Mac's mic — allow in System Settings → Privacy → Microphone → Xcode |
| Charts not rendering | Requires iOS 16+ (Swift Charts). Ensure deployment target is iOS 17 |

### Android

| Problem | Solution |
|---|---|
| Gradle sync fails | File → Invalidate Caches → Restart |
| "SDK not found" | File → Project Structure → SDK Location → set Android SDK path |
| Emulator won't start | Ensure you picked arm64-v8a image, not x86_64 |
| "INSTALL_FAILED_INSUFFICIENT_STORAGE" | Wipe emulator data: Device Manager → ⋮ → Wipe Data |
| Network error on emulator | Ensure `android:usesCleartextTraffic="true"` is in AndroidManifest.xml (it is) |
| Hilt errors | Rebuild Project (Build → Rebuild Project) |

---

## Software Summary

| Software | Version | Size | Purpose |
|---|---|---|---|
| **Xcode** | 15.x or 16.x | ~12 GB | iOS build toolchain + simulator |
| **iOS Simulator Runtime** | iOS 17.x | ~7 GB | Run iOS app without a phone |
| **Android Studio** | Hedgehog+ | ~1.5 GB | Android IDE + emulator manager |
| **Android SDK** (Platform 34) | API 34 | ~3 GB | Android build tools + system images |
| **JDK 17** | 17.x | ~300 MB | Gradle builds |
| **Total** | | **~24 GB** | |

All tools are free. No paid Apple Developer account is needed for simulator testing.
