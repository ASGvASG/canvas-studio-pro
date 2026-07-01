# Release Process

## Versioning
Releases are published from Git tags that follow the pattern `v0.0.1-beta.1`.

## Automation
The workflow in [.github/workflows/build.yml](../.github/workflows/build.yml) builds and uploads the following artifacts:
- Android APK
- Windows ZIP archive
- Linux DEB, RPM, and AppImage packages

## Publishing
Trigger a release by pushing a matching tag and allowing the workflow to complete.
