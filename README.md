# Kivo Super App

This repository contains the full monorepo for the Kivo Super App, built with Flutter, Node.js, and Google Cloud Platform.

## Directory Structure

*   `mobile/`: The cross-platform Flutter application.
*   `backend/`: The Node.js Express API.
*   `terraform/`: Infrastructure as Code (IaC) to provision GCP and Cloudflare.

## 1. Local Development Setup

### Backend (Node.js)
1.  Navigate to the backend directory: `cd backend`
2.  Install dependencies: `npm install`
3.  Set up your Firebase Admin SDK service account credentials.
4.  Run the development server: `npm run dev` (Ensure you have nodemon installed, or use `npm start`)

### Mobile (Flutter)
1.  Ensure you have the Flutter SDK installed and configured.
2.  Navigate to the mobile directory: `cd mobile`
3.  Initialize the native iOS and Android wrappers (since they were excluded from version control to save space):
    ```bash
    flutter create .
    ```
4.  Generate native app icons:
    ```bash
    flutter pub run flutter_launcher_icons
    ```
5.  Run the app on a connected device or emulator: `flutter run`

## 2. Infrastructure Deployment (Terraform)

You can provision the entire GCP and Cloudflare infrastructure using Terraform.

1.  Navigate to the terraform directory: `cd terraform`
2.  Initialize Terraform: `terraform init`
3.  Provide the necessary API keys and variables (GCP Project ID, Cloudflare API Token).
4.  Review the infrastructure plan: `terraform plan`
5.  Apply the configuration: `terraform apply`

## 3. CI/CD & Publishing

*   **Backend**: The backend is configured to automatically deploy to Google Cloud Run via Google Cloud Build. See `backend/cloudbuild.yaml`.
*   **Mobile**: The mobile app is configured to deploy to the Apple App Store and Google Play Store using Fastlane. See `mobile/fastlane/Fastfile`.
