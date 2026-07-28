# Platform permissions

Run `flutter create .` once at the project root first (this regenerates
the native `android/`, `ios/`, and `web/` folders this scaffold left
empty in Step 1). Then apply the snippets below.

## Android — `android/app/src/main/AndroidManifest.xml`

Add inside `<manifest>`, above `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.WRITE_CONTACTS" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<uses-feature android:name="android.hardware.camera" android:required="true" />
```

Set `minSdkVersion 21` (ML Kit / CameraX requirement) in
`android/app/build.gradle`.

## iOS — `ios/Runner/Info.plist`

Add these keys (required — App Store review rejects camera/contacts
usage without a description):

```xml
<key>NSCameraUsageDescription</key>
<string>ScanCard AI needs camera access to scan business cards.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>ScanCard AI needs photo library access to import card photos.</string>
<key>NSContactsUsageDescription</key>
<string>ScanCard AI needs contacts access to save scanned contacts to your phone.</string>
```

## Firebase config files

- Android: place `google-services.json` (from `flutterfire configure`)
  in `android/app/`.
- iOS: place `GoogleService-Info.plist` in `ios/Runner/`.

Both are already in `.gitignore` — never commit real keys for a public
repo.
