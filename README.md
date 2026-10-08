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

### Planned (future releases)

- Web-based admin publishing panel (`admin/` — setup guide added separately)
- Push notifications for closing-soon advertisements
- Full-text search across advertisements
- Share an advertisement
- Server-managed categories (no app update needed)
- Urdu localization

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
