# Fresh Project - Build & Deployment Guide

## 1. Web App (Admin Dashboard)

### Prerequisites
- Node.js 18+ (recommended 20 LTS)
- npm 9+

### Steps

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

**Output:** `dist/` folder — deploy to any static host (Vercel, Netlify, Supabase Hosting).

---

## 2. Web FCM Notifications Setup

### Requirements
- **Firebase Project** with Cloud Messaging enabled
- Firebase Admin SDK private key (JSON)

### Steps
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable Cloud Messaging (FCM)
3. Generate a private key: Project Settings → Service Accounts → Generate new private key
4. Copy the private key JSON content
5. In Supabase Dashboard → Edge Functions → select `send-fcm-notification`
6. Replace the `FCM_SERVICE_ACCOUNT` constant in the function with your Firebase project details

### VAPID Key (Web Push)
1. In Firebase Console → Cloud Messaging → Web configuration → Generate key pair
2. Use the VAPID key in your web app when requesting permission

---

## 3. Flutter Branch POS - Windows (.exe)

### Step 1: Install Prerequisites

| Tool | Purpose | Installation |
|------|---------|--------------|
| **Flutter SDK** | Flutter framework | [Download](https://docs.flutter.dev/get-started/install/windows) |
| **Visual Studio 2022** | C++ build tools for Windows | [Download](https://visualstudio.microsoft.com/vs/) |
| **Windows SDK** | Windows development headers | Included with VS |

### Step 2: Verify Setup
Open **PowerShell as Administrator**:

```powershell
# Check Flutter installation
flutter doctor

# Expected output must include:
#   [✓] Windows (Windows • windows • x64)
#   [✓] Visual Studio (latest version)
#   [✓] Android toolchain (for Android build)
```

If `[✓] Windows` is **missing**:
```powershell
flutter config --enable-windows-desktop
```

If `[✗] Visual Studio`:
1. Open Visual Studio Installer
2. Modify your VS 2022 installation
3. Check **"Desktop development with C++"** workload
4. Install (3-5 GB)

### Step 3: Build the EXE

```powershell
# Navigate to the project
cd C:\Users\IRAQ\SOFT\Desktop\fresh-app\branch_pos

# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build for Windows in release mode
flutter build windows --release
```

### Step 4: Locate the EXE
After successful build, the executable is at:
```
C:\Users\IRAQ\SOFT\Desktop\fresh-app\branch_pos\build\windows\x64\runner\Release\branch_pos.exe
```

**To put it on your Desktop:**
```powershell
Copy-Item "build\windows\x64\runner\Release\branch_pos.exe" "$env:USERPROFILE\Desktop\"
```

### Step 5: Run the App
Double-click `branch_pos.exe` on your Desktop.

> **Note:** The app will show a black console window in the background — this is normal (it's the Flutter engine). You can hide it but don't close it while the app is running.

### Common Build Errors & Fixes

| Error | Cause | Solution |
|-------|-------|----------|
| `flutter: command not found` | Flutter not in PATH | Add Flutter bin to PATH, or restart terminal |
| `MSBuild tools not found` | Visual Studio C++ not installed | Install Visual Studio with "Desktop development with C++" |
| `Unable to find package` | pub get failed | Run `flutter pub get` again, or delete `.dart_tool` and retry |
| `linker error: unresolved external symbol` | Missing Windows SDK | Open Visual Studio Installer → Modify → Add "Windows SDK" |
| `git: command not found` | Git not installed (Flutter needs it) | Install Git from [git-scm.com](https://git-scm.com) |
| `PlatformException` at runtime | SQLite FFI not found | Run `flutter clean && flutter pub get && flutter build windows --release` |

---

## 4. Flutter Branch POS - Android (.apk)

```powershell
flutter build apk --release
```
**Output:** `build\app\outputs\flutter-apk\app-release.apk`

---

## 5. Running the DOS Batch Shortcut

The project includes `Run_Branch_POS.bat` which can be double-clicked to run the POS quickly:

**Create/update `Run_Branch_POS.bat`:**
```batch
@echo off
cd /d "C:\Users\IRAQ\SOFT\Desktop\fresh-app\branch_pos"
flutter run -d windows
pause
```

---

## 6. Supabase Edge Functions Deployment

```bash
# Install Supabase CLI
npm install -g supabase

# Login
supabase login

# Link project
supabase link --project-ref pftjlvtdzokbzuioqfug

# Deploy the send-fcm-notification function
supabase functions deploy send-fcm-notification

# Deploy other functions
supabase functions deploy handle-order-completion
supabase functions deploy notify-arrival
```

---

## 7. Database Migrations

```bash
# Apply all pending migrations
supabase db push

# Or apply manually from the Supabase Dashboard SQL Editor
```

Migrations are in `supabase/migrations/`:
- `20240601_create_user_fcm_tokens.sql` — FCM tokens table
- `20240610_create_notification_trigger.sql` — Order notification trigger
- `create_delivery_zones.sql` — Delivery zones schema

---

## 8. SQL to Add `access_code` Column to Branches (For POS)

```sql
ALTER TABLE branches 
ADD COLUMN IF NOT EXISTS access_code TEXT UNIQUE;

-- Generate codes for existing branches
UPDATE branches 
SET access_code = 'FRESH-' || UPPER(SUBSTRING(REPLACE(id::text, '-', ''), 1, 6)) 
WHERE access_code IS NULL;
```

---

## 9. Environment Variables (.env)

Ensure the web app `.env` file has:

```
VITE_SUPABASE_URL=https://pftjlvtdzokbzuioqfug.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 10. Supporting Files

- **Service Worker:** `public/firebase-messaging-sw.js` — handles background push notifications for the web app
- **FCM Provider:** `src/lib/fcmProvider.tsx` — React context for auto-registering FCM tokens
- **Edge Function:** `supabase/functions/send-fcm-notification/index.ts` — FCM HTTP v1 API integration
