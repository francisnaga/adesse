<p align="center">
  <img src="icon-192.png" alt="Adesse Logo" width="100" height="100" style="border-radius: 22px;">
</p>

<h1 align="center">Adesse</h1>

<p align="center">
  <strong>Attendance without the paper.</strong><br>
  Scan class QR codes even when the network drops.
</p>

<p align="center">
  <a href="https://github.com/francisnaga/adesse"><img src="https://img.shields.io/badge/GitHub-francisnaga%2Fadesse-blue?logo=github" alt="GitHub Repo"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
  <a href="https://supabase.com"><img src="https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?logo=supabase" alt="Supabase"></a>
  <a href="https://web.dev/progressive-web-apps/"><img src="https://img.shields.io/badge/PWA-iOS%20%26%20Android-black?logo=pwa" alt="PWA"></a>
</p>

---

## Overview

**Adesse** is a modern, privacy-focused, offline-resilient attendance platform designed specifically for tertiary institutions. Lecturers project rotating, cryptographically signed QR codes during class. Students scan the code using their phone camera—even without cellular data or Wi-Fi in lecture halls—and attendance scans are cryptographically verified locally and automatically synchronized with **Supabase** once internet connectivity resumes.

---

## Key Features

- **Rotating Cryptographic QR & PIN Codes:** Dynamic session codes rotate every 15 seconds using Web Crypto ECDSA signatures, preventing photo-sharing or attendance fraud.
- **Offline-First Guarantee:** Zero network? No problem. Scans are saved securely in browser/app storage and batched to the cloud when connectivity returns.
- **Google & Apple One-Click Sign-In:** Seamless, professional identity verification tied to student matric numbers and lecturer faculty profiles via Supabase Auth.
- **PIN & Passphrase Fallback:** Students without Google/Apple accounts can use matric + 6-digit PIN; lecturers can use encrypted passphrases with client-side key wrapping.
- **Real-Time Live Attendance Counter:** Live counter increments as students scan in the hall, with manual matric entry and full-screen presentation mode.
- **Class List Verification & Carry-Over Review:** Lecturers can paste official rosters. Unlisted students are held for lecturer review rather than rejected.
- **Dual Platform (Android & iOS):** Installable as a Progressive Web App (PWA) with native touch response, safe area padding, and camera scanner, or packagable directly into native Android (`.apk`/`.aab`) and iOS applications via Capacitor.
- **Automated Vercel Deployment:** Pre-configured `vercel.json` with hardened HTTP security headers, PWA caching rules, and automatic environment variable injection.

---

## Architecture & Technology Stack

| Component | Technology |
|---|---|
| **Frontend** | Vanilla HTML5, CSS3 (shadcn-inspired neutral tokens), Modern ES2022 JavaScript |
| **Cryptography** | Web Crypto API (ECDSA P-256 signatures, SHA-256 PIN hashing, AES-GCM key wrapping) |
| **Database & Auth** | Supabase (PostgreSQL 17 with Row Level Security, Supabase Auth with Google & Apple OAuth) |
| **Offline Engine** | Service Worker Cache API & localStorage transaction queue |
| **Scanning** | Native BarcodeDetector API with jsQR fallback |
| **Hosting** | Vercel / GitHub Pages / Cloudflare Pages |
| **Native Packaging** | Capacitor / Android Studio / Apple Xcode |

---

## Vercel Environment Variables

When deploying to [Vercel](https://vercel.com), configure the following environment variables under **Project Settings > Environment Variables**:

| Variable Name | Description | Default / Example Value |
|---|---|---|
| `SUPABASE_URL` | Your Supabase Project REST URL | `https://xbgolunipyuhyparskmu.supabase.co` |
| `SUPABASE_ANON_KEY` | Public anonymous API key from Supabase API settings | `eyJhbGciOi...` |
| `SUPPORT_EMAIL` | Contact email displayed for account recovery & privacy requests | `efobifrancis53@gmail.com` |
| `APP_NAME` | Display name of the application | `Adesse` |

> **How it works on Vercel:** Vercel automatically runs `npm run build` (`node build-config.js`) during deployment, generating the production `config.js` directly from your environment variables. If no environment variables are set, the project safely defaults to the pre-configured project credentials.

---

## Database Schema (PostgreSQL on Supabase)

The database runs on Supabase with Row Level Security enabled across all collections:

- `public.students`: Student profiles, matric numbers, departments, levels, and OAuth account links.
- `public.lecturers`: Faculty profiles and encrypted cryptographic key wrappers.
- `public.sessions`: Attendance sessions with derived keys and timetable metadata.
- `public.scans`: Scanned attendance events with window tokens and device verification signatures.
- `public.lecstate`: Cross-device state synchronizer for lecturer multi-phone roaming.

---

## Quick Start & Local Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/francisnaga/adesse.git
   cd adesse
   ```

2. **Serve locally:**
   ```bash
   npx serve .
   ```
   Open `http://localhost:3000` in your desktop or mobile browser.

---

## Deployment to Vercel

1. Push your repository to GitHub (`francisnaga/adesse`).
2. Visit [Vercel](https://vercel.com/new) and import the repository.
3. In **Environment Variables**, enter `SUPABASE_URL` and `SUPABASE_ANON_KEY` (optional, defaults are already bundled).
4. Click **Deploy**. Vercel will build and deploy the app automatically on every commit.

Detailed instructions for Google Cloud Console and Apple Developer configuration are available in [DEPLOY.md](DEPLOY.md).

---

## License

This project is licensed under the [MIT License](LICENSE).
