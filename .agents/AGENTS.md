# Project Memory: Kivo Super App

## Current State & Version Baseline
- **Active Release Version**: `v1.0.22+63` (Build **63**)
- **GitHub Repository**: [HixroyWalker/kivo-super-app](https://github.com/HixroyWalker/kivo-super-app.git)
- **Latest GitHub Release Tag**: [v1.0.22-63](https://github.com/HixroyWalker/kivo-super-app/releases/tag/v1.0.22-63)
- **iOS TestFlight Status**: ✅ **100% SUCCESS** (Run ID: `31490405100`) - Build 63 successfully published to TestFlight.
- **Android Google Play Status**: ✅ **100% SUCCESS** (Run ID: `31490405146`) - Build 63 successfully published to Google Play Internal testing.
- **Git Branch**: `main` (clean, fully committed and synced with origin)

## System Architecture & Store Deployment Key Learnings

### 1. Fastlane Code Signing & Xcode 16.3 Overrides (iOS)
- **Fastlane Command Verification**: Never append `|| true` to Fastlane execution commands in production GitHub Actions workflow files (`cd ios && bundle exec fastlane beta`), as it masks underlying `xcodebuild` signing errors and misleads pipeline reporting into false-green success.
- **CocoaPods Workspace Targeting**: Flutter iOS projects containing native Firebase/Cloud Firestore plugins must have Fastlane `build_app` targeted at `workspace: "Runner.xcworkspace"` and run `cd ios && pod install --repo-update` during CI build steps.
- **Compiler CFLAGS Patching**: Xcode 16.3 on macOS `macos-latest` runners rejects legacy `-G` flags passed into `BoringSSL-GRPC` CFLAGS. Stripping `-G` flags dynamically in `mobile/patch_ios.py` across Pods target build configurations ensures clean compilation.

### 2. Android AGP 8 Compliance & `compileSdk 36`
- **AGP 8 Namespace Rule**: Removed explicit `package="com.kivo.app"` declarations from `AndroidManifest.xml` to adhere to AGP 8 requirements.
- **JDK 21 & SDK 36 Compatibility**: `sqflite_android: 2.4.3` requires Android SDK 36 (`BAKLAVA` symbols) and JDK 21 (`Locale.of`, `Thread.threadId()`). Setting `compileSdk = 36` in `android/app/build.gradle` and forcing `compileSdk = 36` across all `~/.pub-cache` dependencies via `mobile/patch_android.py` guarantees 100% compilation success.

### 3. CI/CD Workflows (`.github/workflows/`)
- Dedicated iOS workflow: `.github/workflows/deploy_ios.yml` (macOS runner, Flutter stable, Ruby 3.0, Fastlane beta).
- Dedicated Android workflow: `.github/workflows/deploy_android.yml` (Ubuntu runner, Java 21 Temurin, Flutter stable, Fastlane beta).
