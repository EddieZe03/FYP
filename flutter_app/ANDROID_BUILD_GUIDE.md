# Android Build & Installation Guide

## Prerequisites
- Flutter SDK installed on Windows
- Android Studio or Android SDK tools installed
- Android phone with USB debugging enabled
- USB cable to connect phone to computer

## Step 1: Enable USB Debugging on Phone

1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go back to **Settings → Developer Options**
4. Enable **USB Debugging**
5. Connect phone to computer via USB cable

## Step 2: Configure API URL

Before building, update the Flask backend URL in your code:

**File: `lib/services/api_service.dart` (Line 7)**

```dart
// Find your Windows PC's IP address:
// Open Command Prompt and run: ipconfig
// Look for "IPv4 Address" (typically 192.168.X.X)

static const String baseUrl = 'http://192.168.X.X:5000';
// Replace X.X with your actual IP address
```

## Step 3: Build APK on Windows

Open Command Prompt/PowerShell and navigate to the flutter_app folder:

```bash
cd /workspaces/FYP/flutter_app

# Install dependencies
flutter pub get

# Build APK (debug version for phone testing)
flutter build apk --debug
```

### Recommended: Run Automatic Environment Check First

Use the included PowerShell scripts to verify setup and run build in one flow:

```powershell
cd /workspaces/FYP/flutter_app

# Check Flutter + Android SDK + adb + doctor status
powershell -ExecutionPolicy Bypass -File .\scripts\check_android_env.ps1

# If check passes, run full debug build pipeline
powershell -ExecutionPolicy Bypass -File .\scripts\build_debug_android.ps1
```

If you prefer double-click or Command Prompt, use the batch wrappers:

```bat
scripts\check_android_env.bat
scripts\build_debug_android.bat
```

The APK will be generated at:
```
flutter_app/build/app/outputs/apk/debug/app-debug.apk
```

## Step 4: Install APK on Phone

**Option A: Using Flutter (Easiest)**
```bash
flutter install
```
This automatically installs the app on your connected phone.

If you want to install the APK manually after building:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Option B: Manual Installation**
```bash
# List connected devices
flutter devices

# Install specific APK manually
adb install build/app/outputs/apk/debug/app-debug.apk
```

## Step 5: Grant Permissions

When you first run the app, Android will ask for:
- ✅ Camera permission (for QR scanning)
- ✅ Internet permission (automatically granted)

Tap **Allow** for camera access.

## Step 6: Connect to Flask Backend

1. Make sure Flask backend is running on your Windows PC:
   ```bash
   python app.py
   ```

2. The Flask app should be running at your PC's IP (e.g., `http://192.168.1.100:5000`)

3. Open Phish Guard app on Android phone and start scanning!

## Building Release APK (Optional)

For distribution, create a release APK:

```bash
flutter build apk --release
```

The release APK will be smaller and faster, but requires signing with your own key.

## Troubleshooting

**App won't connect to Flask backend:**
- Check your PC IP address matches what's in `api_service.dart`
- Make sure Flask app is running: `python app.py`
- Ensure PC and phone are on the same WiFi network
- Firewall may be blocking port 5000; try disabling Windows Firewall temporarily

**Flutter not recognized:**
- Add Flutter to PATH: [https://flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)

**ADB not found:**
- Install Android SDK: [https://developer.android.com/studio](https://developer.android.com/studio)
- Add Android SDK/platform-tools to PATH

**No Android SDK found:**
- Set `ANDROID_HOME` to `C:\Users\<YourUser>\AppData\Local\Android\Sdk`
- Add `%ANDROID_HOME%\platform-tools` to PATH
- Restart terminal and run:
   ```bash
   flutter doctor -v
   ```

**Camera permission denied:**
- Go to **Phone Settings → Apps → Phish Guard → Permissions → Camera**
- Enable camera access
