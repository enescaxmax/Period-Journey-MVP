# Period Journey

Period Journey is a Riverpod-powered cycle & period tracking MVP built with Flutter. It supports fast daily logging, a monthly calendar, and insight cards while staying resilient when Firebase isn’t configured.

## Project structure

```
lib/
  app/
  features/
    auth/
    onboarding/
    cycle/
      data/
      presentation/
  shared/
    utils/
    widgets/
```

Key state flows:
- `shared/providers.dart` bootstraps Firebase initialization and exposes auth streams.
- `features/cycle/data/` contains repositories for Firestore and the in-memory mock plus Riverpod providers.
- `features/cycle/presentation/` includes the home dashboard, log editor, calendar, and stats screens.

## Getting started

1. [Install Flutter](https://docs.flutter.dev/get-started/install) 3.22 or newer and run:
   ```bash
   flutter doctor
   ```
2. Install project dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app in mock mode (no Firebase configured):
   ```bash
   flutter run
   ```
   The app defaults to an in-memory repository and guest mode; no backend setup is required for local UX testing.

## Firebase setup (optional but recommended)

1. Install the FlutterFire CLI if you haven’t already:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Configure Firebase for the project (replace the platform flags with the ones you need):
   ```bash
   flutterfire configure --project=<your-project-id> --platforms=android,ios
   ```
   This generates `firebase_options.dart` under `lib/`. Commit that file or keep it locally according to your workflow.
3. Add platform config files:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
4. Rebuild the app. When Firebase initializes successfully, signing in migrates any local guest history to Firestore automatically.

### Firestore security rules

Use the rules below (stored in `firestore.rules`) to scope data per user:
```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;

      match /cycles/{docId} { allow read, write: if request.auth != null && request.auth.uid == uid; }
      match /logs/{docId}   { allow read, write: if request.auth != null && request.auth.uid == uid; }
    }
  }
}
```
Publish them with:
```bash
firebase deploy --only firestore:rules
```

## Running tests

```bash
flutter test
```

## Feature notes & TODOs

- Guest mode is always available; sign in with email/password or Google when Firebase is configured.
- Local onboarding answers persist in `SharedPreferences` and sync to Firestore on login.
- TODO: add notification reminders.
- TODO: add partner read-only sharing.
- TODO: upgrade calendar visuals to a full heatmap.

## Troubleshooting

- If `firebase_options.dart` is missing, the app silently falls back to the mock repository.
- When updating package versions, re-run `flutter pub get` and `flutter test` to confirm compatibility.
