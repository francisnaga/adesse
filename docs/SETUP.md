# Setup

About 15 minutes. You need a Supabase project, a Google Cloud project (free), and Vercel.

## 1. Supabase

1. Create a project (or use an existing one). Note the **Project URL** and the **publishable / anon key** (Project Settings, API).
2. SQL Editor: paste [`supabase/schema.sql`](../supabase/schema.sql) and run it. It is safe to run again.
3. Authentication, URL Configuration:
   - **Site URL**: your site, e.g. `https://adesse.vercel.app`
   - **Redirect URLs**: add `https://adesse.vercel.app/**` and `http://localhost:3000/**` (change to the port you use)

> **Existing project that was used with an older version?** Run `supabase/reconcile-live.sql` first, then `schema.sql`. Read the header of that file: it removes leftovers that weaken the security rules.

## 2. Google sign-in

1. [Google Cloud Console](https://console.cloud.google.com/) > create a project > APIs & Services > **OAuth consent screen**: User type *External*, app name *Adesse*, your support email, add your site's domain under *Authorized domains*, scopes `openid`, `email`, `profile` (the default ones, no review needed). Then **Publish app**. While it says *Testing*, only listed test users can sign in.
2. Credentials > Create credentials > **OAuth client ID** > *Web application*:
   - Authorized JavaScript origins: `https://adesse.vercel.app`
   - Authorized redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
3. Copy the Client ID and Client secret.
4. Supabase > Authentication > Providers > **Google**: enable, paste both, save.

## 3. Site

`config.js` holds the Supabase URL and anon key. The anon key is public by design; it can only do what Row Level Security allows. In Vercel (Project Settings, Environment Variables) you can set `SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPPORT_EMAIL`; `build-config.js` writes them into `config.js` at deploy time. Never put the `service_role` key anywhere in this repo.

Vercel builds with `npm run build` and serves `public/`. After editing anything in `src/`, run `python3 tools/build.py` and commit `index.html` (Vercel does not run Python).

## 4. Admin tasks (SQL Editor)

**Verify a lecturer** (they can then see the student list and typed-code scans):
```sql
update public.lecturers set verified = true where name = 'Dr Okafor';
```

**Verify automatically by email domain** (everyone signing in with that domain is marked verified):
```sql
insert into public.university_domains (uni, domain) values ('Nigeria Maritime University', 'nmu.edu.ng')
on conflict (uni) do update set domain = excluded.domain;
```
The `uni` text must match the university name exactly as the app shows it.

**Resolve a matric dispute.** See who reported: `select * from public.matric_disputes order by created_at desc;`
Check the rightful owner against school records. To hand the number to the rightful account: delete the wrong student row (`delete from public.students where uni = '...' and matric = '...';`, their scans for it stay in `scans`), then ask the rightful student to sign in and set up again.

## 5. First-run checklist (not covered by automated tests)

- [ ] Open the site in a private window: sign in with Google, pick *Student*, finish setup. You land on the student home.
- [ ] Second Google account on another phone: pick *Lecturer*, finish setup, add a course, start a class.
- [ ] Student scans the QR with the real camera. Student home shows 100%. Lecturer count goes to 1.
- [ ] Student turns on airplane mode, types the 6-digit code, turns airplane mode off. Scan is sent.
- [ ] Sign out the student, sign in again on another browser: the course and scan are back.
- [ ] Third Google account tries the first student's matric number: refused with *Report it*.
- [ ] Settings > Delete account on a throwaway account. Check `auth.users` no longer has it.

## Notes

- **Free tier pausing.** Supabase pauses free projects after about a week with no activity. Restore it from the dashboard, or upgrade, or ping it on a schedule. Pausing is the first thing to check if sign-in suddenly fails.
- **Android.** Google refuses OAuth sign-in inside embedded webviews, which is what a Capacitor app is. For Google Play, wrap the hosted site as a Trusted Web Activity (Bubblewrap or PWABuilder) instead; that runs in Chrome and Google sign-in works. The `android/` folder is a scaffold only; sign-in in it is **not** working.
- **Apple sign-in** is not included. It needs a paid Apple developer account and only matters for an iOS app.
