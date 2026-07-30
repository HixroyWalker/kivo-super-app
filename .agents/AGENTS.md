# Project Memory: Kivo Super App

## Current State & Version Baseline
- **Active Release Version**: `v1.0.4+5`
- **GitHub Repository**: [HixroyWalker/kivo-super-app](https://github.com/HixroyWalker/kivo-super-app.git)
- **Latest GitHub Release**: [v1.0.4+5 Release](https://github.com/HixroyWalker/kivo-super-app/releases/tag/v1.0.4%2B5)
- **Git Branch**: `main` (clean, fully committed and synced with origin)

## Architectural & Feature Summary

### 1. Mobile App (`mobile/`)
- **Framework**: Flutter (Material 3).
- **Core Modules**:
  - `auth`: Google Sign-In & Apple Sign-In routines.
  - `dashboard`: Total JMD wallet balance display, quick service grid, Lynk Top-Up flow.
  - `accounting`: **Full QuickBooks Suite**:
    - Multi-tab interface (Overview, Invoices, Expenses, P&L & GCT Tax).
    - Auto-calculates 15% Jamaican GCT output vs input tax.
    - Expense categorization & invoice creation modals.
    - CSV/PDF export.
  - `messaging`: **Full WhatsApp Suite**:
    - Multimodal message support: Text, Voice Notes (interactive player), Photos, Documents, and In-Chat Money Transfers.
    - Double blue-tick read receipts (`✓✓`).
    - Audio voice call action bar.
    - Live contact search and online green status indicators.

### 2. Backend Services (`backend/`)
- **Runtime**: Node.js Express API on GCP Cloud Run.
- **Firebase**: Firebase Admin SDK with Firestore & FCM notification dispatch.
- **Routes**:
  - `/api/auth`: Login & session handling.
  - `/api/wallet`: P2P balances & Lynk webhooks.
  - `/api/accounting`: Ledger, invoices, expenses, P&L aggregation.
  - `/api/messaging`: Multimodal messages, read receipts, voice call signaling.
  - `/api/notifications`: FCM device tokens and admin push broadcasts.
  - `/api/admin`: Staff fee overrides with strict `req.user.role === 'ADMIN'` protection.

### 3. CI/CD & Infrastructure (`codemagic.yaml` & `terraform/`)
- **Codemagic**: Automated `flutter-ios-android-release` pipeline building `.ipa` and `.aab` bundles on tag push.
- **Terraform**: GCP & Cloudflare IaC scripts in `terraform/`.
