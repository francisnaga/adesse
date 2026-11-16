# Adesse: Deployment & Operations Guide

Adesse is an offline-first attendance platform built for higher education, featuring encrypted rotating QR codes, offline local fallback, Supabase backend synchronization, and Google + Apple OAuth authentication.

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

## 2. Authentication: The Part You Play

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

### B. Apple Sign-In Setup (Optional for Web / Required for App Store)
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

## 3. Vercel Deployment

Adesse includes a pre-configured `vercel.json` optimized for PWA caching and security headers.

### Deploying via Vercel Web Dashboard:
1. Go to [vercel.com/new](https://vercel.com/new).
2. Select your GitHub repository: **`francisnaga/adesse`**.
3. Framework Preset: **Other**.
4. Root Directory: `./`.
5. Click **Deploy**.
6. Every time you push to the `main` branch on GitHub, Vercel will automatically redeploy the latest version.

---

## 4. Mobile Apps (iPhone & Android)

Adesse is engineered to work across all platforms:

### Option 1: Instant PWA (No App Store approval needed)
- **iPhone / iOS Safari:** Open your deployed URL, tap the **Share** button, and tap **"Add to Home Screen"**. It launches full-screen with native safe-area insets, app icon, and standalone offline caching.
- **Android Chrome:** Open the URL, tap the browser menu (or the install banner), and tap **"Install App"**.

### Option 2: Native App Store & Google Play Build (Capacitor)
To package Adesse into native `.apk` / `.aab` (Google Play) and Xcode project (iOS App Store):
```bash
npm install @capacitor/core @capacitor/cli @capacitor/android @capacitor/ios
npx cap init Adesse com.adesse.app --web-dir .
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
