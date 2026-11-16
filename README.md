# Adesse

> Attendance without the paper. Scan class QR codes even when the network drops.

[![GitHub Repo](https://img.shields.io/badge/GitHub-francisnaga%2Fadesse-blue?logo=github)](https://github.com/francisnaga/adesse)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Supabase](https://img.shields.io/badge/Supabase-Database%20%26%20Auth-3ECF8E?logo=supabase)](https://supabase.com)
[![PWA](https://img.shields.io/badge/PWA-iOS%20%26%20Android-black?logo=pwa)](https://web.dev/progressive-web-apps/)

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
- **Automated Vercel Deployment:** Pre-configured `vercel.json` with hardened HTTP security headers and PWA caching rules.

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

3. **Configuration:**
   Ensure `config.js` points to your Supabase instance:
   ```javascript
   window.ADESSE_CONFIG = {
     supabaseUrl: 'https://xbgolunipyuhyparskmu.supabase.co',
     supabaseAnonKey: 'YOUR_ANON_KEY',
     supportEmail: 'efobifrancis53@gmail.com',
     appName: 'Adesse'
   };
   ```

---

## Deployment to Vercel

1. Push your repository to GitHub (`francisnaga/adesse`).
2. Visit [Vercel](https://vercel.com/new) and import the repository.
3. Deploy! Vercel will use the included `vercel.json` automatically.

Detailed instructions for Google Cloud Console and Apple Developer configuration are available in [DEPLOY.md](DEPLOY.md).

---

## License

This project is licensed under the [MIT License](LICENSE).
