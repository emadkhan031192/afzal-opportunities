# Setup — Afzal Opportunities

## Prerequisites

- Flutter SDK 3.35 or newer (Dart 3.9+). Install from
  <https://docs.flutter.dev/get-started/install>
- Android SDK with platform 34+ and build-tools (installed via Android Studio)
- A Firebase project (only needed for production data; the app runs in
  **demo mode** with bundled sample advertisements when Firebase is not
  configured)

## 1. Get the code and install dependencies

```bash
git clone https://github.com/<your-username>/afzal-opportunities.git
cd afzal-opportunities
flutter pub get
```

## 2. Generate the Android project (first time only)

The `android/` directory is intentionally not committed. Generate it with:

```bash
flutter create --platforms=android \
  --org com.afzaleservices \
  --project-name opportunities .
```

This produces the package ID `com.afzaleservices.opportunities`.

## 3. Configure Firebase (production)

Without this step the app runs in **demo mode** (see
`lib/services/demo_ads.dart`).

1. Create a project in the [Firebase console](https://console.firebase.google.com).
2. Add an Android app with package name `com.afzaleservices.opportunities`.
3. Download `google-services.json` into `android/app/`
   (this file is git-ignored — never commit it).
4. Install the FlutterFire CLI and configure:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This regenerates `lib/services/firebase_config.dart` with your real
   project values.
5. In the Firebase console, create a **Cloud Firestore** database and add a
   collection named `advertisements` with documents shaped like:

   | field          | type      | notes                              |
   | -------------- | --------- | ---------------------------------- |
   | title          | string    | required                           |
   | organization   | string    | required                           |
   | category       | string    | `jobs` \| `scholarships` \| `admissions` \| `other` |
   | description    | string    | required                           |
   | location       | string    | optional                           |
   | posterUrl      | string    | optional, Firebase Storage URL     |
   | sourceUrl      | string    | optional, official source (https)  |
   | applicationUrl | string    | optional, apply link (https)       |
   | publishedAt    | timestamp | server timestamp                   |
   | lastDate       | string    | optional, `YYYY-MM-DD`             |
   | status         | string    | `draft` \| `published` \| `archived` |
   | isFeatured     | boolean   | optional                           |
   | createdAt      | timestamp | server timestamp                   |
   | updatedAt      | timestamp | server timestamp                   |
   | createdBy      | string    | admin uid                          |

6. Apply Firestore security rules so **only authenticated administrators**
   can write, while published ads are publicly readable:

   ```firestore
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /advertisements/{adId} {
         allow read: if resource.data.status == 'published';
         allow write: if request.auth != null
           && request.auth.token.admin == true;
       }
     }
   }
   ```

   The `admin` custom claim is set on administrator accounts via the Admin
   SDK (see `admin/README.md`). Never rely on hiding buttons in the UI —
   the rules above are the real enforcement.

7. Create matching **Storage** rules so only admins can upload posters and
   everyone can read them.

## 4. Run the app

```bash
flutter run
```

## 5. Quality gates (run before every commit)

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
