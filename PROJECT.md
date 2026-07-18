# Refind — Project Overview

> **Refind** is a cross-platform "read-it-later" / bookmark-manager app that helps users
> save links, organize them into collections, and — most importantly — actually come back
> to them via smart reminders and revisit analytics. Save a link from any app's share sheet,
> and Refind nudges you to revisit it before it disappears into the backlog.

- **App name:** Refind (`refind_app`)
- **Version:** 1.2.0 (build 5)
- **Flutter SDK:** Dart `^3.9.2`
- **Firebase project:** `myrefindapp`
- **Platforms:** Android, iOS, Web (Firebase Hosting)

---

## What the app does

| Capability | Description |
|---|---|
| **Save links** | Paste a URL, or share directly from another app via the OS share sheet (`receive_sharing_intent`). Link metadata (title, description, image, domain) is auto-fetched with `metadata_fetch`. |
| **Collections** | Group saved links into folders. Users get 3 default collections seeded on first launch; collections can be pinned. |
| **Smart reminders** | Backend schedules push notifications (via OneSignal) nudging users to revisit saved links, respecting quiet hours and a configurable cadence. |
| **Analytics** | Revisit rate, backlog count, current streak, weekly saved/revisited, reminder effectiveness, top sources/collections — rendered with `fl_chart`. |
| **Weekly recap** | A scheduled Cloud Function sends a weekly summary push notification. |
| **Subscriptions** | Free vs. Premium plans via RevenueCat (`purchases_flutter`). Free tier is capped at 20 posts and 3 collections; Premium is effectively unlimited. |
| **Admin panel** | In-app admin dashboard for managing users, sending push notifications, and app settings. |
| **App update gate** | Forces/prompts updates by comparing installed version against a remote config. |

---

## Tech stack

**Client (Flutter)**
- State management: `provider` (`ChangeNotifier` controllers) + lightweight singleton controllers
- Auth: `firebase_auth` + `google_sign_in` (starts **anonymous**, upgradeable to Google)
- Data: `cloud_firestore`
- Analytics: `firebase_analytics`
- Notifications: `onesignal_flutter`
- Payments: `purchases_flutter` (RevenueCat)
- UI/misc: `google_fonts`, `fl_chart`, `flutter_html`, `html_editor_enhanced`, `url_launcher`, `permission_handler`, `shared_preferences`, `device_info_plus`, `package_info_plus`, `intl`

**Backend (Firebase)**
- **Cloud Functions** (Node 24, `functions/index.js`) — reminder scheduling & delivery
- **Firestore** — users, collections, posts, reminders, notification queue
- **Firebase Hosting** — web build + landing page
- **RevenueCat** — subscription entitlements
- **OneSignal** — push delivery
- **OpenRouter** — used server-side (secret configured) for generating notification copy

---

## Project layout

```
RefindApp/
├── refind_app/          ← the Flutter app (this project)
│   ├── lib/
│   ├── functions/       ← Firebase Cloud Functions (Node.js)
│   ├── android/ ios/ web/
│   └── firebase.json
├── infographics/        ← marketing / design assets
└── web-landing/         ← standalone marketing landing page
```

### `lib/` structure (feature-first)

```
lib/
├── main.dart                     # Entry point: Firebase + OneSignal init, share-intent handling
├── firebase_options.dart         # Generated Firebase config
│
├── core/                         # Shared foundation
│   ├── constants/                # app_constants.dart
│   ├── model/app_user_model.dart # AppUser (profile, usage counts, plan, entitlements)
│   ├── theme/                    # colors, text styles, AppTheme (light/dark), ThemeController
│   ├── utils/                    # device_info_helper, url_launcher
│   └── widgets/                  # primary_button, shared UI
│
├── features/                     # One folder per feature
│   ├── auth/                     # AuthController + AuthService (anon → Google upgrade)
│   ├── home/                     # Home feed, link details, save-from-share screens
│   ├── collection/               # Collections CRUD + details
│   ├── saved_posts/              # SavedPost model, controller, service
│   ├── reminders/                # ReminderService (calls Cloud Functions) + OneSignal init
│   ├── analytics/                # Analytics models, service, screen, charts
│   ├── settings/                 # User settings (notifications, quiet hours, cadence)
│   ├── subscription/             # Paywall / plan screen
│   ├── limitGuard/               # UsageProvider — enforces free-tier limits
│   ├── appUpdate/                # Version-gate screen
│   └── splash/                   # Splash / bootstrap
│
├── admin/                        # Admin-only dashboard
│   ├── dashboard/  users/  notification/  settings/
│
├── navigation/bottom_nav.dart    # 4-tab bottom nav: Home · Collections · Analytics · Settings
└── services/                     # app_version_service, in_app_purchase_service (RevenueCat)
```

---

## Data model (Firestore)

```
users/{uid}
  ├─ profile: name, email, photoUrl, isAnonymous
  ├─ usage:   totalPostsCreated, totalCollectionsCreated
  ├─ plan:    plan ('free'|'premium'), isPro, entitlements[], rcAppUserId
  ├─ meta:    appVersion, deviceType, platform, createdAt, lastSeen
  ├─ settings: { notificationsEnabled, quiet hours, defaultReminder, ... }
  ├─ collections/{collectionId}   → name, description, isDefault, isPinned, userId, createdAt
  └─ posts/{postId}               → SavedPost (title, url, image, domain, tags, collectionId,
                                      reminderCount, visitCount, lastVisitedAt, createdAt)

reminders/{userId}_{postId}       → status, scheduledAt, post snapshot
notification_queue/{jobId}        → userId, postId, scheduledTime, status (pending/sent/cancelled)
```

**Key models:** `AppUser`, `SavedPost`, `CollectionModel`, `AnalyticsModel` (+ collection/reminder/source/weekly stats), `UserSettingsModel`, `UsageModel`, `AppUpdateModel`.

---

## Cloud Functions (`functions/index.js`)

| Export | Trigger | Purpose |
|---|---|---|
| `scheduleReminder` | HTTPS | Called by the app when a post is saved; enqueues reminder jobs honoring quiet hours & cadence |
| `cancelReminders` | HTTPS | Cancels queued reminders for a post |
| `processNotifications` | Schedule (every minute) | Sends due notifications from `notification_queue` via OneSignal |
| `cleanupNotifications` | Schedule | Purges old/processed queue entries |
| `weeklyRecap` | Schedule | Weekly summary push per user |
| `testProcessNow` / `testWeeklyRecap` | HTTPS | Manual test triggers |

**Secrets used:** `onesignalApiKey`, `onesignalAppId`, `openRouterApiKey`.

The app calls the functions at `https://us-central1-myrefindapp.cloudfunctions.net`
(see `lib/features/reminders/reminder_service.dart`).

---

## Key architectural notes

- **Anonymous-first auth:** App signs the user in anonymously on launch (`AuthController.initAuth`),
  seeds default collections, and configures RevenueCat. Google sign-in later *upgrades* the same
  account and re-links RevenueCat.
- **Freemium limits** are enforced client-side via `UsageProvider` (`limit = premium ? ∞ : 20 posts`,
  `collectionLimit = premium ? ∞ : 3`), backed by the `totalPostsCreated` / `plan` fields streamed
  live from the user's Firestore doc.
- **Share-intent flow:** `main.dart` listens to `ReceiveSharingIntent` and routes shared links to
  `SaveLinkFromIntentScreen`, so users can save from any app without opening Refind first.
- **Reminders are server-driven:** the client only *requests* scheduling; all timing, quiet-hours
  logic, and delivery run in Cloud Functions + a Firestore-backed `notification_queue`.
- **Theming:** `ThemeController` (light/dark) with a centralized `AppColors` / `AppTheme`.

---

## Getting started

```bash
cd refind_app

# 1. Install Flutter deps
flutter pub get

# 2. Run the app (device/emulator)
flutter run

# 3. Cloud Functions (separate)
cd functions
npm install
npm run serve        # local emulator
npm run deploy       # deploy to Firebase (myrefindapp)
```

**Requirements**
- Flutter with Dart `^3.9.2`
- Firebase CLI + access to the `myrefindapp` project
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) — already referenced in `firebase.json`
- Node 24 for Cloud Functions
- OneSignal, RevenueCat, and OpenRouter credentials for full functionality

---

## Notable observations / TODOs

- `lib/core/constants/app_constants.dart` is currently empty.
- The root `README.md` is still the default Flutter template — this `PROJECT.md` supersedes it.
- `AppUser.copyWith` has a likely bug: `email: email ?? this.name` (should be `this.email`).
- There are no substantive tests yet (only the default `test/` scaffold).
