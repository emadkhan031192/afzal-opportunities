# Firebase Setup — Afzal Opportunities

Complete step-by-step guide to wire up the Firebase backend used by the
**Afzal Opportunities** Android app and the web admin panel (`admin/`).

Estimated time: 20–30 minutes (one-time).

---

## 0. What you are setting up

| Piece | Firebase product | Purpose |
|---|---|---|
| Admin sign-in | Authentication (Email/Password) | Only admins can publish ads |
| Advertisement records | Cloud Firestore (`advertisements/…`) | The app's feed, updated live |
| Poster images | Firebase Storage (`posters/{adId}/…`) | Original ad posters |
| Security | `firestore.rules` + `storage.rules` | Public reads published ads only; writes are admin-only |

---

## 1. Create the Firebase project

1. Go to <https://console.firebase.google.com> and sign in.
2. **Add project** → name it e.g. `afzal-opportunities` → Continue.
3. Google Analytics is optional for v1 — you may disable it.
4. **Create project** and wait for provisioning.

## 2. Register the Android app

1. In the project overview click the **Android** icon ("Add an app").
2. **Android package name:** `com.afzaleservices.opportunities`
   (must match the app's package ID exactly).
3. App nickname: `Afzal Opportunities` (optional).
4. **Debug signing certificate SHA-1:** optional for v1 (needed later for
   Google Sign-In / Dynamic Links; not required now) → **Register app**.
5. **Download `google-services.json`.**
   > ⚠️ **Never commit this file.** It is already listed in the repo's
   > `.gitignore`. Keep a backup copy somewhere safe outside the repository.
6. Place it at `android/app/google-services.json` in your local checkout when
   building, then **Continue** → **Continue** (SDK steps are handled by the
   FlutterFire / Gradle setup in the app repo).

## 3. Connect the Flutter app (`flutterfire configure` or manual)

**Option A — automatic (recommended):**

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=<your-project-id>
```

Select **Android** when prompted. This generates
`lib/firebase_options.dart` for the app.

**Option B — manual:** copy the values from the downloaded
`google-services.json` into the app's Firebase options file as documented in
`docs/setup.md` (owned by the app team).

The app runs in **demo mode with clearly labelled sample data** until a real
configuration is present; it never ships with fabricated credentials.

## 4. Enable Email/Password authentication

1. Firebase Console → **Build** → **Authentication** → **Get started**.
2. **Sign-in method** tab → **Email/Password** → **Enable** → **Save**.
3. Leave "Email link (passwordless sign-in)" disabled.

## 5. Create Firestore and deploy the rules

1. Console → **Build** → **Firestore Database** → **Create database**.
2. Choose **Start in production mode** (we deploy our own rules next).
3. Pick the region closest to your users (e.g. `asia-south1` for Pakistan) —
   **this cannot be changed later.**
4. From the repository root, install the Firebase CLI once and deploy:

```bash
npm install -g firebase-tools
firebase login
firebase use --add          # select your project id (one-time)
firebase deploy --only firestore:rules
```

This installs `firestore.rules`, which enforces:

- **Public:** may `get`/`list` only advertisements with `status == "published"`.
- **Admins** (users with an `/admins/{uid}` document): full read/write on
  advertisements, with server-side validation of required fields, the fixed
  category set, and the `draft | published | archived` statuses.
- **Nobody** may write to `/admins` from a client; users may only read their
  own admin document.

Verify: Console → Firestore → **Rules** tab should show the deployed rules.

## 6. Enable Storage and deploy the rules

1. Console → **Build** → **Storage** → **Get started** → same region as
   Firestore → **Done**.
2. Deploy the rules from the repo root:

```bash
firebase deploy --only storage
```

`storage.rules` enforces:

- **Public read** of `posters/**` (the app must display posters without login).
- **Admin-only writes** (same `/admins/{uid}` check), images only
  (`image/*` content type), **under 5 MB**.

## 7. Create the first administrator account

The admin panel (`admin/`) signs in with email + password, but sign-in alone
grants nothing — the account must also have an `/admins/{uid}` document.
Create it manually in the console:

1. **Authentication** → **Users** → **Add user** → enter email + strong
   password → **Add user**.
2. Click the new user row and **copy the User UID**.
3. **Firestore Database** → **Start collection** → collection ID `admins` → Next.
4. Document ID: **paste the User UID** → fields:
   - `email` — string — the admin's email address
   - `createdAt` — timestamp — use "now"
5. **Save.**

To add further admins later, repeat these steps. There is deliberately no
self-registration flow.

## 8. Configure and open the admin panel

1. Open `admin/app.js` and replace the `FIREBASE_CONFIG` placeholder with your
   web-app config:
   Console → Project settings (⚙) → **Your apps** → `</>` **Add app** →
   copy the `firebaseConfig` object.
2. Serve the `admin/` folder. Quickest options:

```bash
# Firebase Hosting (configured in firebase.json):
firebase deploy --only hosting
# → https://<your-project-id>.web.app

# …or any static host / local preview:
cd admin && python3 -m http.server 8080
# → http://localhost:8080
```

3. Sign in with the admin account from step 7. You should land on the
   dashboard with empty Published/Drafts/Archived/Expired tabs.

## 9. Publish the first ad and check the app

1. In the panel: **+ New advertisement** → fill headline, organization,
   category, description → set a last date → upload a poster → **Publish**.
2. In Firestore, confirm `advertisements/{id}` has `status: "published"` and a
   server `publishedAt` timestamp.
3. Open the Android app (configured per step 3): the ad should appear in the
   feed immediately — **no app update required**.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Admin panel shows "not registered as an administrator" after sign-in | The `/admins/{uid}` document is missing or the document ID doesn't exactly match the Auth UID (step 7). |
| `PERMISSION_DENIED` writing an ad | Not signed in as admin, or rules not deployed: re-run `firebase deploy --only firestore:rules,storage`. |
| App shows no ads / empty feed | No `published` ads yet; or the app's Firebase config points at a different project; check `google-services.json` package name. |
| Poster upload fails | File > 5 MB or not JPG/PNG/WebP; Storage rules not deployed; Storage not enabled. |
| `google-services.json` missing at build time | Re-download from Project settings → Your apps → Android app. Never commit it. |
| Deadline labels look off by a day | Labels are computed in **Asia/Karachi (UTC+5, no DST)** on both app and panel; confirm `lastDate` is stored as `YYYY-MM-DD`. |
| `firebase deploy` asks for a project | Run `firebase use --add` once to link the local repo to the project. |

## Rotating / removing an admin

Delete that user's document at `/admins/{uid}` in the Firestore console —
their sign-in keeps working for nothing admin-related, and all writes are
rejected immediately by the rules. Optionally also disable/delete the user in
**Authentication**.
