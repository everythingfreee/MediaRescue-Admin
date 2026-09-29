# MediaRescue Admin 🛡️📱

> **MediaRescue Admin** is a private, open-source, serverless administration dashboard built in Flutter for managing device telemetry, version distribution, and push notifications for the **MediaRescue** Android app. Designed with a **Zero Paid Infrastructure** philosophy, it communicates directly client-side with **Firebase Cloud Firestore** and the **Firebase Cloud Messaging (FCM) v1 HTTP API**.

---

## 🌟 Key Features

* **⚡ Zero Paid Infrastructure (Serverless Architecture)**: Runs entirely client-side without requiring Cloud Functions, Node.js backend servers, or third-party API proxies.
* **🔑 Client-Side OAuth 2.0 FCM v1 Messaging**: Dynamically loads `assets/service_account.json` at runtime via `google_sign_in` & `googleapis_auth` to generate OAuth 2.0 access tokens and dispatch push notifications directly to `https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`.
* **🔒 Strict Auth Guard & Allowlist**: Authenticates via Google Sign-In (`firebase_auth` & `google_sign_in`) and validates user email against an `admin_users/{email}` Firestore allowlist (`active == true`). Unauthorized users are immediately signed out and presented with an access denial alert dialog.
* **📊 Analytical Dashboard & Interactive Charts**: Real-time summary header cards (Total Installed Devices, 30-Day Active Users, Active FCM Tokens) paired with interactive `fl_chart` visualizations for App Version Distribution, Android OS Distribution, and Top Hardware Device Models.
* **🔎 Device & Telemetry Explorer with Multi-Selection Mode**:
  * Paginated/streaming list of device installation documents with UUID/Model search and version dropdown filters.
  * **Multi-Selection Mode**: Long-press any device card to enter multi-select mode. Select multiple devices to **batch delete telemetry documents** from Firestore or **send targeted push notifications** directly to selected devices.
* **📋 Diagnostic Metadata Inspector**: Modal bottom sheet displaying detailed device specs, FCM token status indicators (green/gray dots), token copy actions, and direct targeting shortcuts.
* **📢 Advanced FCM Push Notification Center**:
  * **Target Audience Selection**: Broadcast to ALL devices, Segment by App/Android Version, Send to FCM Topic (e.g. `all_users`, `updates`), or Target Custom/Multiple Tokens (Option D).
  * **Notification Image URL Payload**: Attach banner image URLs with real-time network preview thumbnails.
  * **Custom Data Payload Editor**: Add/remove key-value payload entries (e.g., `action="update_alert"`, `url="https://..."`).
  * **Live Streaming Console Log**: Real-time progress bar, success/failure counts, and timestamped console output with auto-throttling concurrency control.
* **📳 Haptic Feedback & Modern Material Design 3**: Native haptic feedback on button presses, chip selections, tab changes, and card long-presses. Responsive dark mode UI for mobile, tablet, and desktop viewports.

---

## 📂 Project Structure & File Tree

```
mediarescueadmin/
├── assets/
│   └── service_account.json          # Firebase Service Account key (FCM API Admin scope)
├── lib/
│   ├── main.dart                      # Application entry point, Firebase init, Riverpod Scope & AuthGuard
|   ├──firebase_options.dart           # Auto generated when connecting the app to firebase
│   ├── models/
│   │   ├── admin_user_model.dart      # Schema for admin_users/{email} allowlist
│   │   ├── installation_model.dart   # Schema for installations/{installationId} telemetry
│   │   └── notification_payload.dart  # Models for Push Notification state & console log entries
│   ├── providers/
│   │   └── admin_providers.dart       # Riverpod providers (Auth, Telemetry Stream, Filters, FCM Notifier)
│   ├── screens/
│   │   ├── dashboard_screen.dart      # Summary stat cards & fl_chart analytical charts
│   │   ├── device_list_screen.dart     # Searchable/filterable device telemetry list with Multi-Select Mode
│   │   ├── login_screen.dart          # Google Sign-In auth guard & unauthorized error dialog
│   │   ├── main_navigation_screen.dart# Responsive navigation container (BottomBar & NavRail)
│   │   └── notification_screen.dart   # FCM Push Notification Center (Topics, Multi-Tokens, Image URLs)
│   ├── services/
│   │   ├── admin_auth_service.dart    # Google Sign-In & admin allowlist verification service
│   │   ├── analytics_service.dart     # Telemetry metric aggregations & batch delete operations
│   │   └── fcm_v1_service.dart        # OAuth 2.0 token generation & HTTP v1 push dispatch service
│   └── widgets/
│       ├── chart_card.dart            # Donut and Bar Chart components powered by fl_chart
│       ├── device_card.dart           # Installation card item with selection checkboxes and status dots
│       ├── device_detail_bottom_sheet.dart # Diagnostic modal with copy buttons & action triggers
│       ├── key_value_editor.dart      # Dynamic key-value payload input component
│       ├── sending_console_widget.dart# Dark terminal console for live push logs
│       └── stat_card.dart             # Sleek elevation summary metric card
├── pubspec.yaml                       # Flutter dependencies and asset configuration
└── README.md                          # Project documentation
```

---

## 🗄️ Firestore Data Schema

### Collection 1: `installations/{installationId}`
Records device telemetry metadata reported by the MediaRescue Android application.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `installationId` | `String` | Unique installation identifier / UUID |
| `appVersion` | `String` | Installed app release version (e.g., `"1.5.0"`) |
| `androidVersion` | `String` | Android OS release/SDK version (e.g., `"Android 14"`) |
| `deviceModel` | `String` | Device hardware model (e.g., `"Google Pixel 8 Pro"`) |
| `fcmToken` | `String` | Firebase Cloud Messaging device registration token |
| `lastAppOpen` | `Timestamp` / `String` | Timestamp of the last app launch |
| `updatedAt` | `Timestamp` | Firestore document update timestamp |

### Collection 2: `admin_users/{email}`
Allowlist database controlling administrator access to the dashboard. The document ID **must be the lowercase email address** of the administrator.

| Field Name | Type | Description |
| :--- | :--- | :--- |
| `active` | `Boolean` | `true` if authorized, `false` to disable access |
| `role` | `String` | Role descriptor (e.g., `"super_admin"`, `"admin"`) |

---

## 🚀 Setup & Execution Guide

### Prerequisites
1. **Flutter SDK**: Install Flutter version `3.10.0` or higher.
2. **Firebase Project**: A Firebase Project with Cloud Firestore enabled.
3. **Google Service Account**:
   * Navigate to **Google Cloud Console** -> **IAM & Admin** -> **Service Accounts**.
   * Create a Service Account with the role: **Firebase Cloud Messaging API Admin**.
   * Generate and download the JSON key.
   * Save the file as `assets/service_account.json`.

> [!WARNING]
> Never commit `assets/service_account.json` to public version control repositories. Add `assets/service_account.json` to your `.gitignore`.

### Installation Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/everythingfreee/MediaRescue-Admin.git
   cd MediaRescue-Admin
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS/macOS) is placed in the respective platform folders or initialized via `firebase_core`.

4. **Add Admin Email to Firestore Allowlist**:
   In your Firebase Console -> Cloud Firestore, create a document in `admin_users`:
   * **Document ID**: `your.email@gmail.com` (must be lowercase)
   * **Fields**:
     ```json
     {
       "active": true,
       "role": "super_admin"
     }
     ```

5. **Run the Dashboard**:
   ```bash
   flutter run
   ```

---

## 🔍 SEO, AEO & GEO Technical FAQ

### Q1: How does Option D handle multiple FCM tokens?
**Answer**: Option D allows administrators to paste single or multiple FCM tokens separated by commas, spaces, or newlines. `PushNotificationNotifier` parses and deduplicates the input string, reporting the parsed token count in real-time, and dispatches FCM v1 notifications in asynchronous batches with concurrency control.

### Q2: How does Multi-Selection Mode work on the Device List Screen?
**Answer**: Administrators can long-press any device card to enter Multi-Selection Mode. Cards display checkboxes, and a contextual header bar displays the count of selected devices. From this bar, administrators can either batch delete selected installation documents from Cloud Firestore or pre-fill Option D to send targeted push notifications to all selected devices.

---

## 📄 License

This project is open-source under the MIT License.
