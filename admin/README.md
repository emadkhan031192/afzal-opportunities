# Afzal Opportunities — Admin Panel

A static, single-page web app used by Afzal E Services administrators to publish
and manage the advertisements shown in the **Afzal Opportunities** Android app.

There is **no build step**: `index.html` + `styles.css` + `app.js` can be served
from any static host (Firebase Hosting is configured in `firebase.json`).

## What it does

- **Secure sign-in** with email + password (Firebase Authentication).
- **Admin gate:** after sign-in the panel checks for an `/admins/{uid}` document
  in Firestore. Accounts without that document are signed straight back out.
- **Dashboard tabs:** Published · Drafts · Archived · Expired
  (expired = published ads whose last date is before today in Asia/Karachi).
- **Advertisement editor** with live preview card:
  - poster image upload (JPG/PNG/WebP, ≤ 5 MB) with progress bar → stored in
    Firebase Storage at `posters/{adId}/{filename}`
  - headline, organization, category, description, last date (optional),
    official source URL, application URL, location, "featured" flag
  - client-side validation (required fields, `YYYY-MM-DD` date, `https://` URLs)
  - **Save as draft** or **Publish** (sets `publishedAt` via server timestamp)
- **Ad management:** edit, publish/unpublish, archive, delete
  (delete also removes the ad's poster folder; prefer *archive* to keep history).

## Prerequisites

1. A Firebase project (see `docs/firebase-setup.md` for the full walkthrough).
2. **Authentication** → Sign-in method → **Email/Password** enabled.
3. **Cloud Firestore** database created, with `firestore.rules` deployed.
4. **Firebase Storage** enabled, with `storage.rules` deployed.

## Configuration

Open `admin/app.js` and replace the `FIREBASE_CONFIG` placeholder at the top
with the web-app config from your Firebase project:

> Firebase Console → Project settings → Your apps → Web app (`</>`)

```js
const FIREBASE_CONFIG = {
  apiKey: "AIzaSy...",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "1234567890",
  appId: "1:1234567890:web:abcdef123456",
};
```

This config is **public by design** (it only identifies the project). Security
comes from the Firestore/Storage rules, not from hiding this object.

## Creating the FIRST administrator

The rules grant write access only to users with a document at
`/admins/{uid}`. That document **cannot** be created from the app or this
panel — it must be created manually in the Firebase Console:

1. Firebase Console → **Authentication** → **Users** → **Add user**.
   Enter the admin's email and a strong password → **Add user**.
2. Click the new user and copy its **User UID**.
3. Go to **Firestore Database** → **Start collection** → collection ID: `admins`.
4. Document ID: paste the **User UID** from step 2.
5. Add fields:
   - `email` (string) → the admin's email
   - `createdAt` (timestamp) → click the timestamp icon and use "now" / server value
6. **Save.** That account can now sign in to this panel.

To add more admins later, repeat the steps (or have an existing admin do it —
there is deliberately no self-registration).

## Deploying the rules

From the repository root, with the Firebase CLI installed and logged in:

```bash
firebase use --add            # select your Firebase project (one-time)
firebase deploy --only firestore:rules,storage
```

## Hosting the panel

Option A — Firebase Hosting (already configured in `firebase.json`):

```bash
firebase deploy --only hosting
```

Your panel is then live at `https://<your-project-id>.web.app`.

Option B — any static host (Netlify, Vercel, GitHub Pages, a plain web server):
upload the contents of the `admin/` folder as-is.

> **Do not** expose the panel URL publicly more than necessary. The panel
> itself enforces nothing — the Firestore/Storage rules do — but keeping the
> login page unlisted reduces nuisance sign-in attempts.

## Teaching review queues (Private Teaching Jobs module)

The dashboard topbar has a **Teaching review** button opening a separate
moderation view with three queues:

- **Organizations** (`teachingOrganizations`) — filters: pending / approved /
  suspended / rejected. Actions: Approve, Reject (optional reason), Suspend,
  Reactivate.
- **Teachers** (`teacherProfiles`) — same filters and actions. A CV is only
  ever shown as "attached / not attached" — the private `cvStoragePath` is
  never rendered as a link.
- **Vacancies** (`teachingVacancies`) — filters: pending / approved /
  rejected / expired (expired = flagged `expired`, or approved with a past
  application deadline). Actions: Approve & publish (sets `publishedAt`),
  Reject (optional reason), Unpublish (back to pending), Expire, and Edit
  (title / description / deadline correction only).

The queue-tab badges show pending counts (the review workload). All writes
use server timestamps and are enforced by Firestore rules; permission
failures appear as error toasts.

## Daily workflow

1. **+ New advertisement** → fill in the fields → watch the **live preview**.
2. Upload the poster (progress bar; replaces any previous upload).
3. **Save as draft** to keep working, or **Publish** to make it live in the app
   immediately — no app update needed.
4. Use the tabs to review **Published**, fix **Drafts**, **Archive** outdated
   ads, and check **Expired** (published ads past their last date, still in
   Asia/Karachi time) for renewal or archiving.

## Security notes

- **Never** put passwords, API secrets, or service-account JSON in this panel
  or in the repository. The `FIREBASE_CONFIG` object is public-safe.
- Hiding admin buttons in this UI is **not** the security boundary.
  `firestore.rules` and `storage.rules` reject every non-admin write
  server-side, including writes crafted outside this panel.
- The `/admins` collection is not listable and not writable from any client;
  only single-document reads by the owning signed-in user are allowed.
- Poster uploads are limited to images ≤ 5 MB, enforced both in the UI and in
  `storage.rules`.
- All URLs entered (source/application links) must be `https://`; the app
  validates again before opening them and never treats ad text as code.
