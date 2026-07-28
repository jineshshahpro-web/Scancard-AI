# Release checklist

## Before your first build
- [ ] Run `flutter create .` to generate native `android/`, `ios/`, `web/` projects
- [ ] `flutter pub get`
- [ ] `flutterfire configure` (generates `lib/core/config/firebase_options.dart`)
- [ ] Apply the permission snippets in `PERMISSIONS.md`
- [ ] Add real app icon assets at `assets/icons/app_icon.png` (1024×1024),
      `assets/icons/app_icon_fg.png` (adaptive icon foreground), and
      `assets/icons/splash_logo.png`, then run:
      ```
      dart run flutter_launcher_icons
      dart run flutter_native_splash:create
      ```
- [ ] `dart run build_runner build --delete-conflicting-outputs` (Drift/Freezed/json_serializable/Riverpod codegen)

## Firebase / backend
- [ ] Firestore security rules restrict `contacts/{id}` reads/writes to
      `request.auth.uid == resource.data.ownerId`
- [ ] Firebase Storage rules restrict `card_images/{ownerId}/**` to the
      owning user
- [ ] Enable Email/Password and Google sign-in providers in the
      Firebase console (Authentication → Sign-in method)
- [ ] Enable Crashlytics in the Firebase console

## Android (Play Store)
- [ ] Set `applicationId` in `android/app/build.gradle`
- [ ] Generate an upload keystore and configure signing in
      `android/app/build.gradle` (`signingConfigs.release`)
- [ ] Set `versionCode` / `versionName` (mirrors `pubspec.yaml`'s
      `version: x.y.z+build`)
- [ ] Target the latest required API level (`compileSdkVersion`,
      `targetSdkVersion`)
- [ ] `flutter build appbundle --release`
- [ ] Complete Play Console's Data Safety form (camera, contacts,
      email/photos collected — declare accordingly since this app reads
      contacts and uploads card images)

## iOS (App Store)
- [ ] Set Bundle ID + Team in Xcode signing settings
- [ ] Bump `CFBundleShortVersionString` / `CFBundleVersion`
- [ ] `flutter build ipa --release`
- [ ] Complete App Privacy details in App Store Connect (camera,
      contacts, user content)

## AI provider keys
- [ ] Never ship `GEMINI_API_KEY`/`OPENAI_API_KEY` hard-coded — inject
      via `--dart-define-from-file=secrets.json` in your CI build step,
      or proxy AI calls through a backend (Cloud Function) so the key
      never ships inside the client binary at all (recommended for a
      public release).

## QA pass
- [ ] Fresh install → sign up → scan a card → verify OCR + AI parsing
- [ ] Airplane mode: scan, save, confirm it appears instantly and
      syncs once connectivity returns
- [ ] Dark mode toggle in Settings persists after app restart
- [ ] Export CSV/PDF/VCF and confirm files open correctly on another
      device
- [ ] Rotate/backgrounded app during camera capture doesn't crash
- [ ] VoiceOver / TalkBack pass over primary flows (auth, scan, save)
