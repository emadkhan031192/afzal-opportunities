# Afzal Opportunities

An advertisement-discovery Android app by **Afzal E Services** — browse jobs,
scholarships, admissions and other announcements in a modern,
streaming-inspired interface where every advertisement's headline and last
date is easy to see.

- Package ID: `com.afzaleservices.opportunities`
- Version: `1.0.0+1`
- Platform: Android (Flutter & Dart)

## Features

### Implemented in v1.0

- **Discovery feed** — branded Afzal E Services header, featured advertisement
  card, "Closing soon" rail, category filters (Jobs / Scholarships /
  Admissions / Other), sort by relevance or nearest deadline, pull-to-refresh,
  and loading / empty / error states.
- **Advertisement cards** — headline, organization, category, poster thumbnail,
  last date, remaining time, bookmark control, tap to open details. Only
  active advertisements appear in the feed.
- **Deadline engine (Asia/Karachi)** — `NEW`, `N DAYS LEFT`, `CLOSING SOON`,
  `CLOSING TOMORROW`, `LAST DATE TODAY`, `EXPIRED`, and
  `LAST DATE NOT SPECIFIED`. Advertisements stay active through 23:59:59 PKT
  on their last date; expired items are hidden from the feed but kept for
  admin/archive and labelled in saved items.
- **Advertisement details** — full headline, organization, category, complete
  description, poster, last date + remaining time, location, publication date,
  official source and application links opened safely in an external browser.
  Official information is visually distinguished from the administrator's
  description.
- **Saved advertisements** — local bookmarks persisted across restarts, keyed
  by stable advertisement ID. No account required.
- **Themes** — night (dark) and white (light) modes with the Afzal E Services
  brand palette; the user's choice persists across restarts.
- **Backend** — Cloud Firestore integration (`advertisements` collection);
  when Firebase is not configured the app runs in clearly-labelled demo mode
  so it always builds and runs.
- **Quality** — unit, widget and integration tests; `dart format`,
  `flutter analyze` and `flutter test` gates; GitHub Actions release-APK
  workflow.

### Implemented in v1.3.0

- **Notifications** — opt-in local notifications for new advertisements and
  closing-soon reminders on saved ads (1–2 days left). Works without the
  Blaze plan via periodic background checks (Workmanager, hourly when
  online). Promotional notifications are always opt-in. Manage everything
  in Settings.
- **Urdu language option** — full English/Urdu localization of the app
  interface with proper right-to-left layout; the choice persists.
  (Advertisement content itself stays as published by the admin.)
- **Dark mode** — the theme toggle now lives in Settings; the v1.2.0 pastel
  cards are category-tinted (Jobs blue, Scholarships mint, Admissions amber,
  Other rose) with dark-mode variants.
- **Deadline badges** — urgency-colored badges (mint → amber → red) promoted
  to the headline position on cards and details.
- **Share** — share any advertisement or teaching vacancy (title, deadline,
  short description, link) via the system share sheet.
- **Settings** — appearance, language, notification preferences, and the
  Afzal E Services WhatsApp Channel link, reachable from the header.

### Private Teaching Jobs module (v1.3.0)

- **Public browsing** — new "Teaching Jobs" tab; browse approved vacancies
  without logging in. Search plus District, Subject, Qualification and
  Experience filters; saved teaching jobs (separate bookmark list).
- **Vacancy details** — key facts (subjects, qualification, experience,
  positions, salary when provided, employment type), urgency badge,
  description, how-to-apply instructions, and share button. Missing data is
  labelled, never invented.
- **Organization accounts** — email/password registration with email
  verification; institution profile (pending admin review); vacancy
  submission form with validation (submissions start as *pending*, never
  auto-publish); dashboard with vacancy statuses; material edits to an
  approved vacancy send it back for re-approval.
- **Teacher accounts** — email/password registration with email
  verification; private-by-default profile (pending admin review);
  CV upload UI is present but disabled until the Blaze storage upgrade —
  the blocker is explained in-app.
- **Admin review** — the web admin panel gains Organizations, Teachers and
  Vacancies queues (approve / reject with reason / suspend / reactivate /
  unpublish / expire).
- **Security** — Firestore rules: public reads limited to approved
  vacancies; organizations/teachers can only touch their own records and
  can never self-approve; the admin gate reuses the existing
  `admins/{uid}` registry. **The updated `firestore.rules` must be
  published in the Firebase console** (see `docs/private-teaching-jobs-prompt.md`
  §13 and the manual step below).

### Planned (future releases)

- In-app job applications (direct contact + links are supported today)
- Server-triggered push notifications (requires Blaze)
- CV uploads (requires Blaze storage upgrade)
- Play Store release with a real keystore

## Screenshots

> Placeholder — screenshots will be added under `docs/screenshots/` after
> the first release build.

## Installation (developers)

```bash
git clone https://github.com/<your-username>/afzal-opportunities.git
cd afzal-opportunities
flutter pub get

# Generate the Android project (not committed to the repo):
flutter create --platforms=android \
  --org com.afzaleservices \
  --project-name opportunities .

flutter run
```

Full instructions: [`docs/setup.md`](docs/setup.md).

## Firebase setup

See [`docs/setup.md`](docs/setup.md) for the complete walkthrough and
[`docs/firebase-setup.md`](docs/firebase-setup.md) for the Firebase console
steps (added separately). Until Firebase is configured the app runs in demo
mode — no fake credentials are ever committed.

### Manual step: publish the teaching-module security rules

The repository's `firestore.rules` now covers the teaching collections
(`teachingOrganizations`, `teacherProfiles`, `teachingVacancies`), but
rules only take effect once published in the Firebase console:

1. Sign in to the Firebase console as the project owner
   (`emadkhan031192@gmail.com`).
2. Open **Firestore Database → Rules**.
3. Paste the full contents of the repository's `firestore.rules` and
   click **Publish**. Confirm the success message.

Until this is done, the teaching tab shows approved vacancies only after
the rules allow public reads, and organization/teacher writes will fail
with "Missing or insufficient permissions". The admin panel surfaces
these errors instead of crashing.

## Admin panel

The web-based admin publishing panel lives in `admin/` — setup and usage are
documented in [`admin/README.md`](admin/README.md) (added separately).
Administrators sign in with Firebase Authentication; write access is enforced
by Firestore security rules, never by the app UI alone.

## Building the APK

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

- Signed release builds: [`docs/release.md`](docs/release.md)
- GitHub Actions (automatic on push to `main`): `.github/workflows/android-apk.yml`
- Codemagic alternative: [`docs/codemagic.md`](docs/codemagic.md)

## Installing the APK (testers)

1. Download the `afzal-opportunities-android-apk` artifact from a successful
   GitHub Actions run (**Actions** tab → latest green run → **Artifacts**).
2. Copy the APK to your Android phone.
3. Open it and allow **Install unknown apps** when prompted.
4. Open **Afzal Opportunities** and browse.

> CI-built APKs without your keystore are debug-signed: perfect for testing,
> but they cannot be uploaded to Google Play. See
> [`docs/release.md`](docs/release.md) for proper release signing.

## Project structure

```text
lib/
  main.dart                 # bootstrap: bindings, Firebase (guarded), prefs
  app.dart                  # AfzalApp: MaterialApp + theme wiring
  core/
    theme/                  # brand colors, light/night ThemeData, controller
    constants/              # categories, keys, contact info
    utils/                  # deadline engine (PKT), safe URL handling
  models/                   # Advertisement (validated fromJson)
  services/                 # Firestore service, bookmarks, demo data
  screens/                  # main shell, home, details, saved
  widgets/                  # cards, badges, chips, state views
test/                       # unit + widget tests
integration_test/           # on-device smoke test
docs/                       # setup, release, codemagic guides
```

## Security notes

- No secrets are committed: keystores, `key.properties` and
  `google-services.json` are all git-ignored.
- Advertisement text from Firestore is never treated as executable code;
  only `http(s)` URLs with a valid host are opened, in the external browser.
