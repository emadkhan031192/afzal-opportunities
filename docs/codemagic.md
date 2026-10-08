# Codemagic CI alternative — Afzal Opportunities

[Codemagic](https://codemagic.io) can build the release APK without you
running anything locally. Use it as an alternative (or complement) to the
GitHub Actions workflow in `.github/workflows/android-apk.yml`.

## 1. Connect the repository

1. Sign in to Codemagic and add the `afzal-opportunities` GitHub repository.
2. Create a new workflow from the sample below
   (`codemagic.yaml` at the repository root).

## 2. Sample `codemagic.yaml`

```yaml
workflows:
  android-apk:
    name: Android release APK
    max_build_duration: 60
    instance_type: mac_mini_m2
    environment:
      flutter: stable
      java: 17
      groups:
        # optional: add your keystore variables here for signed builds
        - keystore_credentials
    scripts:
      - name: Generate Android project
        script: |
          flutter create --platforms=android \
            --org com.afzaleservices \
            --project-name opportunities .
      - name: Install dependencies
        script: flutter pub get
      - name: Check formatting
        script: dart format --set-exit-if-changed lib test
      - name: Analyze
        script: flutter analyze
      - name: Run tests
        script: flutter test
      - name: Build release APK
        script: flutter build apk --release
    artifacts:
      - build/app/outputs/flutter-apk/app-release.apk
```

## 3. Signed builds on Codemagic

1. In Codemagic: **Teams → Integrations → Code signing identities** —
   upload your `afzal-upload-key.jks` (see `docs/release.md`).
2. Add an environment variable group (e.g. `keystore_credentials`) with:
   - `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
   - `KEYSTORE_PATH` pointing at the uploaded keystore
3. Add a pre-build script that writes `android/key.properties` from those
   variables. Unsigned debug-key APKs are fine for testing but cannot be
   uploaded to Google Play.

## 4. Which CI to use?

|                        | GitHub Actions | Codemagic |
| ---------------------- | -------------- | --------- |
| Cost                   | Free tier generous | Free tier available |
| Config lives in repo   | Yes (`.github/workflows/`) | Yes (`codemagic.yaml`) |
| macOS builds           | Paid runners   | Included  |
| Signing setup          | Encrypted secrets | Built-in code-signing UI |

Both produce the identical artifact:
`build/app/outputs/flutter-apk/app-release.apk`.
