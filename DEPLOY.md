# Muster: Deployment & Operations Guide

Muster is an offline-first attendance platform built for higher education, featuring encrypted rotating QR codes, offline local fallback, Supabase backend synchronization, and Google + Apple OAuth authentication.

---

## 1. Supabase Backend Status: COMPLETE

The database tables and Row Level Security (RLS) policies are already deployed and active on your project (`xbgolunipyuhyparskmu`):

| Table | Purpose | RLS Policy |
|---|---|---|
| `students` | Student profiles (matric, name, dept, level, OAuth user ID) | Read / Write enabled |
| `lecturers` | Lecturer profiles & wrapped cryptographic key pairs | Read / Write enabled |
| `sessions` | Active and historical lecture sessions with derived keys | Read / Write enabled |
| `scans` | Authenticated student attendance scans (signatures & win) | Protected & synced |
| `lecstate` | Encrypted cross-device sync state for lecturer devices | Signature-verified |

Your `config.js` is automatically configured with:
- **Project URL:** `https://xbgolunipyuhyparskmu.supabase.co`
- **Anon Public Key:** Configured

---

## 2. Vercel Deployment & Environment Variables

Muster includes a pre-configured `vercel.json` and a build script (`build-config.js`) that automatically compiles `config.js` from your Vercel Environment Variables upon each deployment.

### Setting Up Environment Variables in Vercel:
When importing your project at [vercel.com/new](https://vercel.com/new) (or under **Project Settings > Environment Variables**), add:

1. **`SUPABASE_URL`**:
   ```
   https://xbgolunipyuhyparskmu.supabase.co
   ```
2. **`SUPABASE_ANON_KEY`**:
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhiZ29sdW5pcHl1aHlwYXJza211Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ4MjI1NzYsImV4cCI6MjExMDM5ODU3Nn0.1jrk7apaQw-ds4FNgZZhmvaKgQZoK69HIi1c6WTTz8o
   ```
3. **`SUPPORT_EMAIL`**:
   ```
   efobifrancis53@gmail.com
   ```

### Deploy Steps:
1. Go to [vercel.com/new](https://vercel.com/new).
2. Select your GitHub repository: **`francisnaga/adesse`**.
3. Build Command: `npm run build` (detected automatically).
4. Output Directory: `public` (configured in `vercel.json`).
5. Click **Deploy**.
6. Every time you push to `main` on GitHub, Vercel will rebuild and deploy the latest version automatically.

---

## 3. Authentication: Google & Apple Sign-In

To activate Google & Apple one-click sign-in in your Supabase Dashboard:

### A. Google Sign-In Setup (5 minutes)
1. Go to [Google Cloud Console](https://console.cloud.google.com/) > **APIs & Services** > **Credentials**.
2. Click **Create Credentials** > **OAuth client ID**.
3. Application type: **Web application**.
4. Under **Authorized redirect URIs**, add:
   ```
   https://xbgolunipyuhyparskmu.supabase.co/auth/v1/callback
   ```
5. Copy your **Client ID** and **Client Secret**.
6. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/xbgolunipyuhyparskmu/auth/providers) > **Authentication** > **Providers** > **Google**:
   - Toggle **Enable Google provider** to ON.
   - Paste **Client ID** and **Client Secret**.
   - Click **Save**.

### B. Apple Sign-In Setup
1. In your [Apple Developer Account](https://developer.apple.com/account/resources/identifiers/list/serviceId), create a **Services ID**.
2. Configure **Sign In with Apple**:
   - Domains: your Vercel deployment domain (e.g. `adesse.vercel.app`).
   - Return URL:
     ```
     https://xbgolunipyuhyparskmu.supabase.co/auth/v1/callback
     ```
3. Open Supabase Dashboard > **Authentication** > **Providers** > **Apple**:
   - Toggle **Enable Apple provider** to ON.
   - Enter your Service ID, Team ID, Key ID, and Private Key.
   - Click **Save**.

---

## 4. Mobile Apps (iPhone & Android)

Muster is engineered to work across all platforms:

### Option 1: Instant PWA (Zero App Store friction)
- **iPhone / iOS Safari:** Open your deployed URL, tap the **Share** button, and tap **"Add to Home Screen"**. It launches full-screen with native safe-area insets, app icon, and standalone offline caching.
- **Android Chrome:** Open the URL, tap the browser menu (or the install banner), and tap **"Install App"**.

### Option 2: Native App Store & Google Play Build (Capacitor)
To package Muster into native `.apk` / `.aab` (Google Play) and Xcode project (iOS App Store):
```bash
npm install @capacitor/core @capacitor/cli @capacitor/android @capacitor/ios
npx cap init Muster com.adesse.app --web-dir .
npx cap add android
npx cap add ios
npx cap sync
npx cap open android   # Launches Android Studio to build APK
npx cap open ios       # Launches Xcode to build iOS App
```

---

## 5. Operations & Support

- **Forgotten Student PIN / Lost Phone:** If a student signed in with Google/Apple, signing in on their new phone instantly restores their records. If they registered with PIN only, verify their identity with their department and find their row in the `students` table in Supabase.
- **Lecturer Multi-Device Continuity:** Lecturers signing in with Google/Apple or their email passphrase instantly restore their active courses, live attendance records, and past classes across any number of devices.
