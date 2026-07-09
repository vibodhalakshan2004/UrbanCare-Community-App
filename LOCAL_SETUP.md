# UrbanCare Community App - Local Setup Guide

This guide explains how to run the UrbanCare app locally with a physical Android phone on your WiFi network.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Frontend Setup](#frontend-setup)
4. [Phone Configuration](#phone-configuration)
5. [Building APK](#building-apk)
6. [Running Tests](#running-tests)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### On Your PC (Development Machine)

#### Required Software
- **Docker Desktop** - For running PostgreSQL + PostGIS and FastAPI backend
  - Download: https://www.docker.com/products/docker-desktop
  - Verify: `docker --version` and `docker-compose --version`

- **Python 3.12+** - For backend development
  - Download: https://www.python.org/downloads/
  - Verify: `python --version`

- **Flutter SDK** - For frontend development
  - Download: https://flutter.dev/docs/get-started/install
  - Verify: `flutter --version`

- **Android SDK** - For building APK (comes with Flutter)
  - Included with: `flutter doctor`
  - Verify: `adb --version`

- **Git** - For version control
  - Download: https://git-scm.com/download/win
  - Verify: `git --version`

#### Network Setup
- **PC IP Address**: Find your local WiFi IP (e.g., 192.168.1.34)
  ```powershell
  ipconfig | Select-String "IPv4 Address"
  ```
  Look for address starting with 192.168.x.x (not 127.0.0.1)

- **Windows Firewall Rule**: Allow port 8000 inbound
  ```powershell
  New-NetFirewallRule -DisplayName "UrbanCare Backend (port 8000)" `
    -Direction Inbound -Protocol TCP -LocalPort 8000 `
    -Action Allow -Profile Any
  ```

#### Verify Network Access
```powershell
# From your PC, verify backend will be accessible
Invoke-RestMethod http://192.168.1.34:8000/
# Should return: (OK) 200
```

### On Your Android Phone

- **Android 7.0+** (API Level 24+)
- **Location permission** enabled
- **Notification permission** enabled
- **Connected to same WiFi network** as PC
- **USB Debugging** enabled (for `adb install`)
  - Settings → Developer Options → USB Debugging

---

## Backend Setup

### 1. Start Docker Containers

Navigate to project root and start the database and backend:

```powershell
cd d:\GitHub\UrbanCare-Community-App
docker-compose up -d
```

**Verify services are running:**
```powershell
docker ps
# Should show:
# - urbancare-community-app-db-1 (PostgreSQL + PostGIS)
# - urbancare-community-app-backend-1 (FastAPI)
```

### 2. Check Database Health

```powershell
# List all tables (should be 14 tables)
docker exec urbancare-community-app-db-1 psql -U postgres -d urbancare_db -c "\dt"

# Expected tables:
# users, citizens, authorities, locations, complaints, complaint_images,
# complaint_verifications, complaint_status_updates, notifications,
# activity_logs, analytics, geofences, leaderboard, status_updates
```

### 3. Verify Backend API

```powershell
# Get API health status
curl http://192.168.1.34:8000/

# Should return: (OK) 200

# List all endpoints
curl http://192.168.1.34:8000/docs
# Opens Swagger UI in browser
```

**Backend runs on:** `http://192.168.1.34:8000`

---

## Frontend Setup

### 1. Install Flutter Dependencies

```powershell
cd d:\GitHub\UrbanCare-Community-App\frontend
flutter pub get
flutter pub upgrade
```

### 2. Configure API Endpoint

The app uses environment variable `API_BASE_URL` to configure backend connection:

```dart
// File: frontend/lib/core/config/env.dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

This is set during APK build (explained below).

### 3. Enable Location Services

Ensure location permissions are configured:
- **Android**: `android/app/src/main/AndroidManifest.xml` includes:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  ```

---

## Phone Configuration

### 1. Connect to WiFi

1. On your phone, connect to the same WiFi network as your PC
2. Note your phone's IP (Settings → WiFi → Connected network → IP address)

### 2. Verify Network Connectivity

From PC PowerShell, ping your phone:
```powershell
# Replace with your phone's actual IP
ping 192.168.1.50

# Should see replies (not timeouts)
```

### 3. Verify Backend Accessibility from Phone

On your PC, ensure backend is accessible:
```powershell
Invoke-RestMethod http://192.168.1.34:8000/
# Should return (OK) 200
```

---

## Building APK

### 1. Clean Previous Build

```powershell
cd d:\GitHub\UrbanCare-Community-App\frontend
flutter clean
```

### 2. Build Release APK

The `--dart-define` flag passes your PC's IP to the app at build time:

```powershell
flutter build apk --release `
  --dart-define=API_BASE_URL=http://192.168.1.34:8000
```

**Replace `192.168.1.34` with your actual PC IP address**

This command:
- Compiles Dart to native ARM code
- Bundles all assets and dependencies
- Signs APK with debug key
- Outputs to: `frontend/build/app/outputs/flutter-apk/app-release.apk`

**Build time:** 2-5 minutes  
**APK size:** ~50 MB

### 3. Locate Built APK

```powershell
ls frontend/build/app/outputs/flutter-apk/app-release.apk
```

---

## Installing & Running on Phone

### 1. Connect Phone to PC (USB)

Plug phone into PC with USB cable.

### 2. Enable USB Debugging Transfer

On phone: Settings → Developer Options → USB Debugging → Allow

### 3. Verify adb Recognizes Phone

```powershell
adb devices
# Should show: [device serial number]  device
```

### 4. Uninstall Old App (if exists)

```powershell
adb uninstall com.urbancare.urbancare_frontend
```

### 5. Install APK

```powershell
adb install -r `
  "d:\GitHub\UrbanCare-Community-App\frontend\build\app\outputs\flutter-apk\app-release.apk"
```

**Output should say:** `Success`

### 6. Launch App on Phone

```powershell
adb shell am start -n com.urbancare.urbancare_frontend/.MainActivity
```

Or manually: Open app launcher → UrbanCare

---

## Testing the App

### Test 1: Sign Up

1. Open app
2. Tap "Sign Up"
3. Enter:
   - Name: Test User
   - Email: test@example.com
   - Password: Test123!
   - Role: Citizen
4. Tap "Sign Up"
5. **Expected:** Login screen appears, no 500 errors

### Test 2: Login

1. Enter credentials from signup above
2. Tap "Login"
3. **Expected:** Home screen loads with map and "Nearby Complaints" list

### Test 3: Verify Location Permission

1. App should prompt for location permission
2. Tap "Allow"
3. **Expected:** Blue dot appears on map showing your current location

### Test 4: Submit Complaint

1. Tap + button (create complaint)
2. Select complaint type (e.g., Pothole)
3. Enter description
4. Take photo or upload from gallery
5. Tap "Submit"
6. **Expected:** Complaint appears in list with status "Reported"

### Test 5: Geofence Notifications

1. Go to home screen
2. Leave app open
3. Walk/drive within 120m of any complaint location
4. **Expected:** Notification appears with complaint details

### Test 6: Duplicate Prevention

1. Receive notification from nearby complaint
2. Dismiss notification
3. Leave geofence (walk away)
4. Re-enter geofence within 1 hour
5. **Expected:** Notification does NOT appear again (prevented)
6. Wait 1+ hour and re-enter
7. **Expected:** Notification DOES appear again

### Test 7: Background Notifications

1. Receive notification from nearby complaint
2. Close app completely (swipe from recents)
3. Walk away from complaint location
4. Walk back within 120m
5. **Expected:** Notification still appears (background detection working)

---

## Troubleshooting

### ❌ Backend Won't Start

**Error:** `docker-compose up` fails or containers crash

**Solutions:**
1. Ensure Docker Desktop is running
   ```powershell
   docker ps
   ```

2. Check container logs:
   ```powershell
   docker logs urbancare-community-app-backend-1 | Select-Object -Last 20
   ```

3. Rebuild containers:
   ```powershell
   docker-compose down
   docker-compose up -d --build
   ```

### ❌ Phone Can't Reach Backend

**Error:** App shows "Connection refused" or network errors

**Solutions:**
1. Verify PC IP is correct:
   ```powershell
   ipconfig | Select-String "IPv4 Address"
   ```

2. Verify firewall rule exists:
   ```powershell
   Get-NetFirewallRule -DisplayName "*UrbanCare*"
   ```

3. Test connectivity from PC:
   ```powershell
   Invoke-RestMethod http://192.168.1.34:8000/
   ```

4. Rebuild APK with correct IP:
   ```powershell
   flutter build apk --release `
     --dart-define=API_BASE_URL=http://[YOUR_PC_IP]:8000
   ```

5. Clear app cache:
   ```powershell
   adb shell pm clear com.urbancare.urbancare_frontend
   ```

### ❌ APK Build Fails

**Error:** `flutter build apk` returns errors

**Solutions:**
1. Clean build:
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.34:8000
   ```

2. Check Flutter setup:
   ```powershell
   flutter doctor
   ```
   Address any ❌ items shown

3. Update dependencies:
   ```powershell
   flutter pub upgrade
   ```

### ❌ Notifications Don't Appear

**Error:** App doesn't send push notifications

**Solutions:**
1. Check location permission:
   - Settings → Apps → UrbanCare → Permissions → Location → Allow all the time

2. Check notification permission:
   - Settings → Apps → UrbanCare → Permissions → Notifications → Allow

3. Verify nearby complaints exist:
   - Open app → Check "Nearby Complaints" list
   - If empty, create a new complaint near your location

4. Check background settings (Android 12+):
   - Settings → Apps → UrbanCare → Battery → Not restricted
   - Settings → Apps → UrbanCare → App startup → Allow

### ❌ App Crashes on Startup

**Error:** "Unfortunately, UrbanCare has stopped"

**Solutions:**
1. Check logs:
   ```powershell
   adb logcat | Select-String "urbancare"
   ```

2. Reinstall:
   ```powershell
   adb uninstall com.urbancare.urbancare_frontend
   adb install -r "path/to/app-release.apk"
   ```

3. Clear app data:
   ```powershell
   adb shell pm clear com.urbancare.urbancare_frontend
   ```

### ❌ Map Shows Blank

**Error:** Map appears but shows no tiles or location marker

**Solutions:**
1. Verify location permission is granted (all the time)

2. Check app has fetched location:
   - Open app → Wait 10 seconds → Check if blue dot appears

3. Reinstall APK:
   ```powershell
   adb uninstall com.urbancare.urbancare_frontend
   adb install -r "path/to/app-release.apk"
   ```

### ❌ Login Returns 500 Error

**Error:** "Internal Server Error" on login screen

**Solutions:**
1. Check backend logs:
   ```powershell
   docker logs urbancare-community-app-backend-1 | Select-Object -Last 50
   ```

2. Verify database:
   ```powershell
   docker exec urbancare-community-app-db-1 psql -U postgres -d urbancare_db -c "SELECT COUNT(*) FROM users;"
   ```

3. Restart containers:
   ```powershell
   docker-compose restart
   ```

4. Check user exists:
   ```powershell
   docker exec urbancare-community-app-db-1 psql -U postgres -d urbancare_db `
     -c "SELECT * FROM users WHERE email='test@example.com';"
   ```

---

## Development Workflow

### Making Code Changes

#### Backend Changes
```powershell
# Edit FastAPI code in Backend/app/
# Changes auto-reload if using hot-reload

# Restart to apply
docker-compose restart backend
```

#### Frontend Changes
```powershell
# Edit Flutter code in frontend/lib/

# Option 1: Run on Android device (live reload)
cd frontend
flutter run

# Option 2: Rebuild APK for final testing
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.1.34:8000
adb install -r "build/app/outputs/flutter-apk/app-release.apk"
```

### Viewing Logs

**Backend Logs:**
```powershell
docker logs urbancare-community-app-backend-1 -f
```

**Database Logs:**
```powershell
docker logs urbancare-community-app-db-1 -f
```

**Phone Logs:**
```powershell
adb logcat | Select-String "urbancare"
```

---

## Network Diagram

```
┌─────────────────────────────────────────┐
│         Your Local WiFi Network         │
│         (192.168.1.0/24)                │
└─────────────────────────────────────────┘
         ▲                          ▲
         │                          │
    192.168.1.34              192.168.1.50
    (Your PC)                 (Your Phone)
         │                          │
    ┌────▼──────────┐          ┌────▼──────────┐
    │  Docker       │          │   UrbanCare   │
    │  ┌─────────┐  │          │   App         │
    │  │Backend  │  │◄─────────┤   (APK)       │
    │  │:8000    │  │ HTTP API │               │
    │  └────┬────┘  │          └───────────────┘
    │       │       │
    │  ┌────▼────┐  │
    │  │Database │  │
    │  │:5432    │  │
    │  └─────────┘  │
    └───────────────┘
```

---

## FAQ

**Q: Can I use an emulator instead of a physical phone?**
A: Yes, but geofence testing requires real GPS. Emulator GPS is simulated.

**Q: How do I change the backend IP?**
A: Find your PC IP with `ipconfig`, then rebuild:
```powershell
flutter build apk --release --dart-define=API_BASE_URL=http://[NEW_IP]:8000
```

**Q: Where are database files stored?**
A: In Docker volume at: `C:\ProgramData\Docker\volumes`

**Q: Can I debug on multiple phones?**
A: Yes, all phones on same WiFi can install the same APK.

**Q: How do I stop everything?**
A: 
```powershell
docker-compose down  # Stops containers but preserves data
docker-compose down -v  # Stops and deletes database volume
```

---

## Support

For issues or questions:
1. Check **Troubleshooting** section above
2. Review backend logs: `docker logs urbancare-community-app-backend-1`
3. Review phone logs: `adb logcat`
4. Check WiFi connectivity on both devices

---

## Next Steps

After successful setup:
1. ✅ Test all features on phone
2. ✅ Create and verify complaints
3. ✅ Test geofence notifications
4. ✅ Verify duplicate prevention
5. ✅ Test background notifications

---

**Last Updated:** 2026-07-04  
**Version:** 1.0.0
