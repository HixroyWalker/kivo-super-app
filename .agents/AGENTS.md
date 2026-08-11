# Project Memory: Kivo Super App

## Current State & Version Baseline
- **Active Release Version**: `v1.0.22+44`
- **GitHub Repository**: [HixroyWalker/kivo-super-app](https://github.com/HixroyWalker/kivo-super-app.git)
- **Latest GitHub Release**: [v1.0.22+44 Release](https://github.com/HixroyWalker/kivo-super-app/releases/tag/v1.0.22%2B44)
- **Git Branch**: `main` (clean, fully committed and synced with origin)

## Architectural & Feature Summary

### 1. Mobile App (`mobile/`)
- **Framework**: Flutter (Material 3).
- **Core Modules**:
  - `auth`: Google & Apple Sign-In routines, Hardware Device Binding (`device_lock_service.dart`), mandatory 6-Digit PIN & Native Biometrics (FaceID/TouchID) challenge, and 1-tap remote active sessions revocation (`sessions_screen.dart`).
  - `merchant`: Merchant Business KYC Portal (`merchant_kyc_screen.dart`) supporting TRN, COJ Certificate of Incorporation, Director ID, and Proof of Address document uploads with AI OCR verification engine.
  - `dashboard`: Total JMD wallet balance display, quick service grid, Lynk Top-Up flow.
  - `accounting`: **Full QuickBooks Suite**:
    - Multi-tab interface (Overview, Invoices, Expenses, P&L & GCT Tax).
    - Auto-calculates 15% Jamaican GCT output vs input tax.
    - Interactive Profit & Loss bar charts protected by biometric lock.
    - Expense categorization, invoice creation modals, and CSV/PDF export.
  - `messaging`: **Full WhatsApp Suite**:
    - Multimodal message support: Text, Voice Notes (interactive player), Photos, Documents, and In-Chat Money Transfers.
    - Double blue-tick read receipts (`✓✓`), audio voice calls, contact search, and green online status.
  - `theme`: Custom Dark Mode theme tokens (`dark_theme.dart`).

### 2. Backend Services (`backend/`)
- **Runtime**: Node.js Express API on GCP Cloud Run.
- **Firebase**: Firebase Admin SDK with Firestore & FCM notification dispatch.
- **Routes**:
  - `/api/auth`: Login, device hardware UUID lock verification, active sessions query, and session revocation.
  - `/api/wallet`: P2P balances, admin fee splits, and Lynk webhooks.
  - `/api/accounting`: Ledger, invoices, expenses, P&L aggregation.
  - `/api/messaging`: Multimodal messages, read receipts, voice call signaling.
  - `/api/notifications`: FCM device tokens and admin push broadcasts.
  - `/api/admin`: Staff fee overrides, global P2P transfer fee thresholds, merchant sales commission overrides, sub-account billing, and KYC review approvals.

### 3. CI/CD & Store Automation (`codemagic.yaml` & `fastlane`)
- **Codemagic**: Automated `flutter-ios-android-release` pipeline executing `flutter create .` ➔ `flutter build appbundle` ➔ `flutter build ipa` on tag push (`v1.0.7+11`).
- **Fastlane Automation**:
  - **iOS (`mobile/ios/fastlane`)**: Automated Xcode code-signing and direct TestFlight deployment (`upload_to_testflight`).
  - **Android (`mobile/android/fastlane`)**: Automated Google Play Console Internal Track deployment (`upload_to_play_store`).
- **GCP Cost Optimization**: Cloud Run `--concurrency=80`, `--cpu-throttling`, and `--min-instances=0` configured in `cloudbuild.yaml`.

## Deployment Standard Operating Procedure (SOP)
- **Mandatory Deployment Method**: **Option 2 (Fastlane Direct CLI Automation)**.
- **Deployment Strategy & Operational Memory Directive
- **Primary Deployment Strategy**: Option 2 (Direct Local Terminal Deployment via Fastlane & Flutter CLI).
- **Complementary OTA Strategy**: Option 3 (Self-Hosted Server-Driven UI & Firebase Remote Config).
- **Execution Protocol**: 
  1. For release updates, execute Fastlane directly via local terminal (`cd mobile/android && fastlane beta` / `cd mobile/ios && fastlane beta`).
  2. If any cloud CI or remote workflow attempt encounters build or signing friction, fallback immediately to local terminal Fastlane execution.
  3. Keep server-driven configuration active for instant zero-downtime FinTech updates in Jamaica. (`v1.x.x+N`), and deploy directly to **Apple TestFlight** and **Google Play Console (Internal Track)** without requesting manual web console steps.
