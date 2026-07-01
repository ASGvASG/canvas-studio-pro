# Getting Started

## Requirements
- Flutter SDK 3.24 or newer
- Android Studio or the Android SDK for APK builds
- A Linux desktop environment for packaging validation
- Windows SDK for native Windows builds

## Local Development
```bash
flutter pub get
flutter run
```

## Build Commands
```bash
flutter build apk --release
flutter build windows --release
flutter build linux --release --target-platform=linux-x64
```

## Release Checklist
- Confirm the Git tag is present.
- Push the tag to trigger GitHub Actions.
- Review the generated release assets in GitHub Releases.
