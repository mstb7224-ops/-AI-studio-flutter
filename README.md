# AI Studio — DailyGlo Flutter Android App

This repository is the Flutter Android user-app project for DailyGlo. It includes Supabase authentication, mobile/email login, member status, payment submission, discount lookup, private payment screenshot upload, paid-member prediction access, and logout. The APK can be built from an Android phone through GitHub Actions; Android Studio is not required on the phone.

## Build from a phone

1. Open this repository on GitHub.
2. Open **Actions**.
3. Select **Build Flutter Android APK**.
4. Press **Run workflow** and choose `release` or `debug`.
5. When the run finishes, open the run summary and download the APK artifact.

## Repository secrets

For Supabase-enabled builds, add these repository secrets under **Settings → Secrets and variables → Actions**:

- `SUPABASE_URL`: `https://xewxigpmvuxkuqtxhxha.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY`: the Supabase publishable key

Never add a Supabase service-role key to this repository or to the Flutter application.

## Local development

On a computer with Flutter installed:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"
```

The app uses the public publishable key only. Production release still requires verification of Storage bucket `iqama_documents`, RLS policies, secure server-side discount redemption, and payment validation as described in the master prompt. Never add a Supabase service-role key to this repository.
