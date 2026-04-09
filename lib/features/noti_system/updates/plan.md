# 🔔 Notification & Updates System

A production-grade, fully extensible **Notification & Updates** feature for Flutter, built with **Riverpod**, **GoRouter**, and a clean layered architecture. Designed to scale to millions of users with real-time support, server-driven UI, and a fully decoupled action system.

---

## 📋 Table of Contents

1. [Feature Overview](#-feature-overview)
2. [Folder Structure](#-folder-structure)
3. [Architecture Overview](#-architecture-overview)
4. [Layer-by-Layer Code Guide](#-layer-by-layer-code-guide)
   - [Data Layer — Models](#1-data-layer--models)
   - [Data Layer — Action System](#2-data-layer--action-system)
   - [Data Layer — Repository](#3-data-layer--repository)
   - [Data Layer — Mock Data](#4-data-layer--mock-data)
   - [Domain Layer — Services](#5-domain-layer--services)
   - [Application Layer — Riverpod Providers](#6-application-layer--riverpod-providers)
   - [Presentation Layer — Widgets](#7-presentation-layer--widgets)
   - [Presentation Layer — Screens](#8-presentation-layer--screens)
   - [Presentation Layer — Navigation](#9-presentation-layer--navigation)
5. [Developer Guide](#-developer-guide)
   - [Installation & Setup](#installation--setup)
   - [Integrating into Your App](#integrating-into-your-app)
   - [Registering Action Handlers](#registering-action-handlers)
   - [Adding a New Notification Type](#adding-a-new-notification-type)
   - [Adding a New Action Type](#adding-a-new-action-type)
   - [Switching to Remote Repository](#switching-to-remote-repository)
   - [Real-Time / WebSocket Support](#real-time--websocket-support)
   - [Push Notifications (Firebase)](#push-notifications-firebase)
6. [User Guide](#-user-guide)
   - [Notification List Screen](#notification-list-screen)
   - [Notification Detail Screen](#notification-detail-screen)
   - [Actions & Buttons](#actions--buttons)
7. [Data Flow Diagram](#-data-flow-diagram)
8. [Design Decisions & Principles](#-design-decisions--principles)
9. [Extending the System](#-extending-the-system)
10. [Dependencies](#-dependencies)
11. [FAQ](#-faq)

---

## 🌟 Feature Overview

| Capability | Status |
|---|---|
| Multiple notification types (system, promo, alert, transaction, update, social) | ✅ |
| Priority-based visual indicators (high / medium / low) | ✅ |
| Read / unread state management | ✅ |
| Optional media (image, GIF, video placeholder) | ✅ |
| Multiple action buttons per notification | ✅ |
| Navigate, Callback, API, ExternalLink action types | ✅ |
| Riverpod AsyncNotifier with pagination | ✅ |
| Hero animations (list → detail) | ✅ |
| GoRouter integration | ✅ |
| Staggered entry animations | ✅ |
| Extensible metadata map | ✅ |
| Swappable local / remote repository | ✅ |
| WebSocket / real-time ready | ✅ (Stream API) |
| Firebase push notification ready | ✅ (stub entry points) |

---

## 📁 Folder Structure

```
lib/
└── features/
    └── updates/
        ├── data/
        │   ├── models/
        │   │   ├── notification_model.dart          # Core Freezed model
        │   │   ├── notification_type.dart           # NotificationType enum
        │   │   ├── notification_priority.dart       # NotificationPriority enum
        │   │   └── notification_media.dart          # Media model + enum
        │   ├── actions/
        │   │   ├── notification_action.dart         # Abstract base class
        │   │   ├── navigate_action.dart             # Navigate to a route
        │   │   ├── callback_action.dart             # Trigger a named handler
        │   │   ├── api_action.dart                  # Trigger an API call
        │   │   └── external_link_action.dart        # Open a URL
        │   ├── repositories/
        │   │   ├── notification_repository.dart     # Abstract interface
        │   │   ├── local_notification_repository.dart  # Mock/local impl
        │   │   └── remote_notification_repository.dart # Future API impl
        │   └── datasources/
        │       └── mock_notification_data.dart      # Sample notifications
        ├── domain/
        │   └── services/
        │       ├── action_dispatcher.dart           # Executes all actions
        │       ├── action_handler_registry.dart     # Callback key→fn map
        │       └── notification_service.dart        # (extend as needed)
        ├── application/
        │   └── providers/
        │       ├── notification_providers.dart      # All Riverpod providers
        │       ├── notification_list_notifier.dart  # AsyncNotifier + state
        │       └── notification_controller.dart     # Read/clear operations
        └── presentation/
            ├── screens/
            │   ├── notification_list_screen.dart    # Main list + app bar
            │   └── notification_detail_screen.dart  # Full detail + actions
            ├── widgets/
            │   ├── notification_tile.dart           # List card widget
            │   ├── notification_action_button.dart  # Filled/Outlined button
            │   ├── notification_media_widget.dart   # Image/GIF/Video
            │   ├── priority_indicator.dart          # Colored left bar
            │   └── unread_badge.dart                # Blue dot indicator
            └── navigation/
                └── updates_routes.dart              # GoRouter route defs
```

---

## 🏛 Architecture Overview

This feature follows a strict **4-layer clean architecture**:

```
┌─────────────────────────────────────────────────┐
│  PRESENTATION  (screens, widgets, navigation)   │
│  Only reads state. Dispatches actions.          │
├─────────────────────────────────────────────────┤
│  APPLICATION   (Riverpod providers, notifiers)  │
│  Orchestrates state. Calls domain/repo.         │
├─────────────────────────────────────────────────┤
│  DOMAIN        (ActionDispatcher, Registry)     │
│  Pure business rules. No Flutter/UI deps.       │
├─────────────────────────────────────────────────┤
│  DATA          (models, actions, repositories)  │
│  Pure data structures. Knows nothing of UI.     │
└─────────────────────────────────────────────────┘
```

**Rule of thumb:**
- Widgets **never** navigate directly
- Models **never** hold `Function()` references
- Business logic **never** lives inside widget `build()` methods
- Repositories **never** depend on providers

---

## 📘 Layer-by-Layer Code Guide

### 1. Data Layer — Models

#### `notification_model.dart`

The core data object. Uses **Freezed** for immutability and `copyWith` support.

```dart
@freezed
class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required String id,
    required NotificationType type,
    required String title,
    required String description,
    required DateTime timestamp,
    @Default(false) bool isRead,
    @Default(NotificationPriority.medium) NotificationPriority priority,
    NotificationMedia? media,
    @Default([]) List<NotificationAction> actions,
    @Default({}) Map<String, dynamic> metadata,
  }) = _NotificationModel;
}
```

**Key fields explained:**

| Field | Type | Purpose |
|---|---|---|
| `id` | `String` | Unique identifier — also used as Hero animation tag |
| `type` | `NotificationType` | Controls badge/icon rendering |
| `priority` | `NotificationPriority` | Drives the color bar on the left of each tile |
| `media` | `NotificationMedia?` | Optional image/gif/video — nullable means no media |
| `actions` | `List<NotificationAction>` | Buttons rendered on tile and detail screen |
| `metadata` | `Map<String, dynamic>` | Arbitrary key-value pairs for future expansion |

**Why Freezed?** Freezed gives you:
- Compile-safe `copyWith` (used heavily in the notifier)
- `==` equality (Riverpod's state comparisons rely on this)
- JSON serialisation via `json_serializable`
- Pattern matching with sealed classes (future-ready)

---

#### `notification_type.dart`

```dart
enum NotificationType {
  system, promo, alert, update, social, transaction, custom,
}
```

Add new types here. The `type` field is used by widgets to render the correct icon or badge color. Extend the `_typeIcon()` helper in `notification_tile.dart` when you add a new type.

---

#### `notification_priority.dart`

```dart
enum NotificationPriority { low, medium, high }
```

Drives `PriorityIndicator` color:
- `high` → red (`#E53935`)
- `medium` → orange (`#FB8C00`)
- `low` → green (`#43A047`)

---

#### `notification_media.dart`

```dart
class NotificationMedia {
  final String url;
  final NotificationMediaType type; // image | gif | video
  final String? thumbnailUrl;
  final String? altText;
}
```

Used by `NotificationMediaWidget`. When `type` is `video`, a play-button placeholder renders (wire in `video_player` package when needed).

---

### 2. Data Layer — Action System

The action system is the most critical design in this feature. **Actions are pure data** — they describe *what to do*, but contain no code. Execution always happens in `ActionDispatcher`.

#### `notification_action.dart` — Abstract Base

```dart
abstract class NotificationAction {
  final String label;      // button text
  final String actionType; // routing key for dispatcher
  final bool isPrimary;    // FilledButton vs OutlinedButton
}
```

All concrete actions extend this. The `actionType` string is how `ActionDispatcher` routes to the correct handler.

---

#### `navigate_action.dart`

**Use when:** tapping the button should push a named GoRouter route.

```dart
NavigateAction(
  label: 'View Order',
  route: '/orders/detail',
  params: {'orderId': '84729'},
  isPrimary: true,
)
```

`params` is passed as `extra` to GoRouter's `push()`. Receive it in your route builder via `state.extra as Map<String, dynamic>`.

---

#### `callback_action.dart`

**Use when:** tapping should trigger app-side logic (e.g. snooze, share, dismiss) that has no corresponding route.

```dart
CallbackAction(
  label: 'Remind Later',
  handlerKey: 'snooze_update',   // key registered in ActionHandlerRegistry
  payload: {'hours': 24},
)
```

> ⚠️ **Critical:** Never put a `Function()` directly on the model. Store only the string `handlerKey`. The actual function lives in `ActionHandlerRegistry`, registered at app startup.

---

#### `api_action.dart`

**Use when:** tapping should directly trigger a backend API call.

```dart
ApiAction(
  label: 'Secure Account',
  endpoint: '/api/account/lock',
  method: 'POST',
  body: {'reason': 'suspicious_login'},
)
```

Inject your `Dio` or `http` client inside `ActionDispatcher.dispatch()` for the `ApiAction` case.

---

#### `external_link_action.dart`

**Use when:** tapping should open a URL in the system browser.

```dart
ExternalLinkAction(
  label: 'Claim Offer',
  url: 'https://yoursite.com/offer?ref=notif',
  isPrimary: true,
)
```

Wire `url_launcher` in `ActionDispatcher` for the `ExternalLinkAction` case.

---

### 3. Data Layer — Repository

#### `notification_repository.dart` — Interface

```dart
abstract class NotificationRepository {
  Future<List<NotificationModel>> fetchNotifications({int page, int limit});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> addNotification(NotificationModel notification);
  Future<void> clearNotifications();
  Stream<List<NotificationModel>> watchNotifications();
}
```

The `Stream` on `watchNotifications()` is the **WebSocket entry point**. Implement it with a `StreamController` locally or connect it to a WebSocket channel remotely — the rest of the system is already wired to consume it.

---

#### `local_notification_repository.dart` — Local/Mock

- Backed by an in-memory `List<NotificationModel>` seeded from `mock_notification_data.dart`
- Uses a `StreamController.broadcast()` to emit updates after mutations
- Simulates network latency with `Future.delayed(400ms)` on fetch
- Safe to use in development and testing

---

#### `remote_notification_repository.dart` — Stub

A `throw UnimplementedError()` stub. Replace each method with your actual API client calls. To activate: change `notificationRepositoryProvider` in `notification_providers.dart` from `LocalNotificationRepository()` to `RemoteNotificationRepository()`.

---

### 4. Data Layer — Mock Data

`mock_notification_data.dart` exports a `List<NotificationModel>` with 5 sample notifications demonstrating all types, priorities, media, and every action type. Use these as templates when building your own notifications.

---

### 5. Domain Layer — Services

#### `action_handler_registry.dart`

A **singleton** registry mapping string keys to `Future<void> Function(Map<String, dynamic>)` handlers.

```dart
// Register (do this once at app startup)
ActionHandlerRegistry.instance.register(
  'snooze_update',
  (payload) async {
    final hours = payload['hours'] as int? ?? 24;
    // schedule local notification...
  },
);

// Resolve (done internally by ActionDispatcher)
final handler = ActionHandlerRegistry.instance.resolve('snooze_update');
```

This is the **only** place `Function()` references live in the system.

---

#### `action_dispatcher.dart`

The single execution gateway for all notification actions. Uses **Dart 3 exhaustive switch** on action type:

```dart
Future<void> dispatch(NotificationAction action) async {
  switch (action) {
    case NavigateAction(:final route, :final params):
      router.push(route, extra: params);

    case CallbackAction(:final handlerKey, :final payload):
      final handler = registry.resolve(handlerKey);
      await handler?.call(payload);

    case ApiAction(:final endpoint, :final method, :final body):
      // inject your API client here

    case ExternalLinkAction(:final url):
      // url_launcher here
  }
}
```

**Why this pattern?** Every new action type forces you to handle it here at compile time (exhaustive switch). You cannot accidentally forget to implement an action's behaviour.

---

### 6. Application Layer — Riverpod Providers

#### `notification_providers.dart`

Declares all Riverpod providers:

| Provider | Type | Purpose |
|---|---|---|
| `notificationRepositoryProvider` | `Provider<NotificationRepository>` | Swap local ↔ remote here |
| `notificationListProvider` | `AsyncNotifierProvider` | Full list state + pagination |
| `actionHandlerRegistryProvider` | `Provider` | Singleton registry |
| `actionDispatcherProvider` | `Provider<ActionDispatcher>` | Wired dispatcher |
| `unreadCountProvider` | `Provider<int>` | Derived unread badge count |

---

#### `notification_list_notifier.dart`

`NotificationListState` holds:

```dart
class NotificationListState {
  final List<NotificationModel> notifications;
  final bool isLoadingMore;   // shows bottom spinner
  final bool hasReachedEnd;   // stops further page requests
  final int currentPage;
}
```

**Available methods on the notifier:**

```dart
// Mark one notification read (also called on tile tap)
ref.read(notificationListProvider.notifier).markAsRead('notif_001');

// Mark all read (called from app bar button)
ref.read(notificationListProvider.notifier).markAllAsRead();

// Trigger pagination (called from scroll listener)
ref.read(notificationListProvider.notifier).loadMore();

// Pull-to-refresh
ref.read(notificationListProvider.notifier).refresh();
```

---

### 7. Presentation Layer — Widgets

#### `notification_tile.dart`

The list card. Responsibilities:
- Renders priority bar, title, description, timestamp, unread badge
- Renders media preview if present
- Renders action buttons if present
- Wraps the entire card in a `Hero` widget tagged `notification_card_{id}`
- Wraps the title in a separate `Hero` tagged `notification_title_{id}`
- On tap: calls `markAsRead()` then navigates to detail via `UpdatesRoutes.goDetail()`
- Implements a custom `flightShuttleBuilder` for a smooth fade transition

---

#### `notification_action_button.dart`

Renders `FilledButton` when `action.isPrimary == true`, `OutlinedButton` otherwise. Both call `dispatcher.dispatch(action)` on press. Styling is driven entirely by the action model — the widget has no hardcoded labels or routes.

---

#### `notification_media_widget.dart`

- Uses `cached_network_image` for image/GIF (with shimmer placeholder and error fallback)
- Renders a dark play-button placeholder for video type
- `isExpanded: true` is passed from the detail screen for full-height display
- `isExpanded: false` (default) used in the list tile for 160px preview

---

#### `priority_indicator.dart`

A 4dp-wide colored vertical bar rendered at the left edge of each tile. Color is derived from `NotificationPriority` via a switch expression.

---

#### `unread_badge.dart`

Renders a 10dp filled circle in `colorScheme.primary` when `isRead == false`. Returns `SizedBox.shrink()` (zero space) when read — no layout shift.

---

### 8. Presentation Layer — Screens

#### `notification_list_screen.dart`

- `CustomScrollView` with `SliverAppBar` (collapses on scroll)
- App bar shows dynamic unread count badge
- "Mark all read" text button and refresh icon button in app bar actions
- `SliverList` with `SliverChildBuilderDelegate` for lazy rendering
- Scroll listener at bottom triggers `loadMore()` when within 200px of end
- Each tile wrapped in `AnimatedNotificationTile` for staggered fade+slide entry (60ms delay per index)
- Empty state renders a centred icon + text when list is empty

---

#### `notification_detail_screen.dart`

- `SliverAppBar` with `expandedHeight: 280` when media exists, `120` when not
- Media fills the expanded area via `Hero` tag `notification_media_{id}`
- Title appears as the `FlexibleSpaceBar` title with `Hero` tag `notification_title_{id}`
- Full description with `lineHeight: 1.7` for readability
- Metadata section auto-renders any key-value pairs from `notification.metadata`
- `_StickyActions` bottom sheet renders action buttons pinned above the safe area

---

### 9. Presentation Layer — Navigation

#### `updates_routes.dart`

```dart
abstract class UpdatesRoutes {
  static const list   = '/updates';
  static const detail = '/updates/detail';

  static void goDetail(BuildContext context, NotificationModel n) {
    context.push(detail, extra: n);
  }

  static List<GoRoute> routes = [ /* list + detail GoRoute */ ];
}
```

Add `UpdatesRoutes.routes` to your top-level `GoRouter` configuration:

```dart
GoRouter(
  routes: [
    ...UpdatesRoutes.routes,
    // your other routes
  ],
)
```

---

## 🛠 Developer Guide

### Installation & Setup

**1. Add dependencies to `pubspec.yaml`:**

```yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  go_router: ^14.0.0
  cached_network_image: ^3.3.0
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
```

**2. Run code generation:**

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `notification_model.freezed.dart` and `notification_model.g.dart`.

---

### Integrating into Your App

**Step 1 — Wrap your app in `ProviderScope`:**

```dart
void main() {
  runApp(const ProviderScope(child: MyApp()));
}
```

**Step 2 — Register your GoRouter routes:**

```dart
final router = GoRouter(
  routes: [
    ...UpdatesRoutes.routes,
    // other routes...
  ],
);
```

**Step 3 — Register action handlers before the app renders:**

```dart
void main() {
  _registerActionHandlers();
  runApp(const ProviderScope(child: MyApp()));
}

void _registerActionHandlers() {
  ActionHandlerRegistry.instance
    ..register('snooze_update', (payload) async {
      final hours = payload['hours'] as int? ?? 24;
      // schedule local notification
    })
    ..register('share_notification', (payload) async {
      final url = payload['url'] as String?;
      // Share.share(url ?? '');
    });
}
```

**Step 4 — Wire the dispatcher with your router instance:**

In `notification_providers.dart`, replace the placeholder with your actual router:

```dart
final actionDispatcherProvider = Provider<ActionDispatcher>((ref) {
  final registry = ref.read(actionHandlerRegistryProvider);
  final router = ref.read(routerProvider); // your GoRouter provider
  return ActionDispatcher(router: router, registry: registry);
});
```

**Step 5 — Navigate to the updates screen:**

```dart
// From anywhere in your app
context.push(UpdatesRoutes.list);

// Or use it as a named destination in your BottomNavigationBar
```

---

### Registering Action Handlers

Any `CallbackAction` with a `handlerKey` must be registered before that notification can be actioned. Registration is idempotent — re-registering a key replaces the previous handler.

```dart
// lib/app/action_handlers.dart

void registerAllActionHandlers() {
  final registry = ActionHandlerRegistry.instance;

  registry.register('snooze_update', (payload) async {
    final hours = payload['hours'] as int;
    await NotificationScheduler.snooze(Duration(hours: hours));
  });

  registry.register('mark_as_favorite', (payload) async {
    final id = payload['notificationId'] as String;
    await FavoritesRepository.add(id);
  });

  registry.register('share_notification', (payload) async {
    final text = payload['shareText'] as String? ?? '';
    await Share.share(text);
  });
}
```

Then call `registerAllActionHandlers()` in `main()` before `runApp()`.

---

### Adding a New Notification Type

**Step 1 — Add to the enum:**

```dart
// notification_type.dart
enum NotificationType {
  system, promo, alert, update, social, transaction, custom,
  reminder,  // ← add here
}
```

**Step 2 — Handle in tile icon (optional):**

In `notification_tile.dart`, extend the icon switch to cover `reminder`:

```dart
IconData _typeIcon(NotificationType type) => switch (type) {
  NotificationType.alert       => Icons.warning_rounded,
  NotificationType.promo       => Icons.local_offer_rounded,
  NotificationType.transaction => Icons.receipt_long_rounded,
  NotificationType.reminder    => Icons.alarm_rounded,  // ← add
  _                            => Icons.notifications_rounded,
};
```

**Step 3 — Create a notification with the new type:**

```dart
NotificationModel(
  id: 'reminder_001',
  type: NotificationType.reminder,
  title: 'Dentist Appointment',
  description: 'Your appointment is tomorrow at 10 AM.',
  timestamp: DateTime.now(),
  priority: NotificationPriority.high,
)
```

---

### Adding a New Action Type

**Step 1 — Create the action class:**

```dart
// data/actions/share_action.dart
class ShareAction extends NotificationAction {
  const ShareAction({
    required super.label,
    required this.shareText,
    super.isPrimary,
  }) : super(actionType: 'share');

  final String shareText;

  @override
  Map<String, dynamic> toJson() => {
    'actionType': actionType,
    'label': label,
    'shareText': shareText,
    'isPrimary': isPrimary,
  };
}
```

**Step 2 — Handle in `ActionDispatcher`:**

```dart
case ShareAction(:final shareText):
  await Share.share(shareText);
```

**Step 3 — Use it on a notification:**

```dart
ShareAction(
  label: 'Share',
  shareText: 'Check out this offer: https://example.com',
)
```

---

### Switching to Remote Repository

Only one line changes in `notification_providers.dart`:

```dart
// Before (local/mock)
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => LocalNotificationRepository(),
);

// After (remote API)
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => RemoteNotificationRepository(
    apiClient: ref.read(dioProvider), // inject your Dio instance
  ),
);
```

Implement the 6 methods in `RemoteNotificationRepository` using your API client. The rest of the system — providers, UI, actions — is completely unaffected.

---

### Real-Time / WebSocket Support

The `watchNotifications()` method on `NotificationRepository` returns a `Stream<List<NotificationModel>>`. To enable real-time updates:

**In `RemoteNotificationRepository`:**

```dart
final _wsChannel = WebSocketChannel.connect(
  Uri.parse('wss://yourapi.com/notifications/stream'),
);

@override
Stream<List<NotificationModel>> watchNotifications() =>
    _wsChannel.stream
        .map((event) => (jsonDecode(event) as List)
            .map((j) => NotificationModel.fromJson(j))
            .toList());
```

**In `NotificationListNotifier.build()`**, subscribe to the stream:

```dart
@override
Future<NotificationListState> build() async {
  final repo = ref.read(notificationRepositoryProvider);
  
  // subscribe to real-time stream
  final sub = repo.watchNotifications().listen((updated) {
    state = AsyncData(NotificationListState(notifications: updated));
  });
  
  ref.onDispose(sub.cancel);
  
  final initial = await repo.fetchNotifications();
  return NotificationListState(notifications: initial);
}
```

---

### Push Notifications (Firebase)

When a Firebase push notification arrives, create a `NotificationModel` from the payload and call `addNotification()`:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final container = ProviderContainer(); // or use your existing container
  final repo = container.read(notificationRepositoryProvider);
  
  repo.addNotification(NotificationModel(
    id: message.messageId ?? UniqueKey().toString(),
    type: NotificationType.values.byName(
      message.data['type'] ?? 'system',
    ),
    title: message.notification?.title ?? '',
    description: message.notification?.body ?? '',
    timestamp: DateTime.now(),
    priority: NotificationPriority.values.byName(
      message.data['priority'] ?? 'medium',
    ),
  ));
});
```

The stream in `LocalNotificationRepository` (or your remote implementation) will push the update to `NotificationListNotifier` automatically.

---

## 👤 User Guide

### Notification List Screen

When you open the **Updates** screen, you will see a list of all your notifications, from newest to oldest.

**Reading the list:**

- A **blue dot** on the right side of a notification means it is unread
- The **colored bar** on the left edge indicates priority:
  - 🔴 Red bar = High priority (urgent, requires attention)
  - 🟠 Orange bar = Medium priority (informational)
  - 🟢 Green bar = Low priority (FYI)
- The **timestamp** in the top-right of each card shows how long ago it arrived (e.g. "5m ago", "2h ago", "Mar 12")
- If a notification has an **image or banner**, it previews below the description
- **Action buttons** may appear at the bottom of the card for quick actions

**Interacting with the list:**

- **Tap any notification** to open its full detail view. It will also be automatically marked as read.
- **"Mark all read"** in the top-right clears all unread indicators at once
- **↺ Refresh button** reloads the notification list from the server
- **Scroll to the bottom** to automatically load older notifications (pagination)

---

### Notification Detail Screen

Tapping a notification opens the full detail view with a smooth animation.

- If the notification has a **media image**, it fills the top of the screen in an immersive hero view
- The **full description** is displayed below, with comfortable reading spacing
- If there are any **extra details** (metadata), they appear as a labelled list below the description
- A **priority chip** and **type chip** appear at the top of the content area
- A **sticky action bar** at the bottom of the screen shows all available action buttons — these stay visible even as you scroll through long content

Press the **back arrow** (top-left) to return to the list.

---

### Actions & Buttons

Notifications can contain one or more action buttons. These appear both in the list tile (as a preview) and at the bottom of the detail screen.

| Button style | Meaning |
|---|---|
| **Filled / solid button** | Primary action — the main recommended action |
| **Outlined button** | Secondary action — optional or destructive |

**What actions can do:**
- **Navigate** — opens a screen in the app (e.g. "View Order", "Review Activity")
- **Open link** — opens a webpage in your browser (e.g. "Claim Offer")
- **API action** — secures your account or performs a backend operation immediately (e.g. "Secure Account")
- **Callback** — performs an in-app operation (e.g. "Remind Later" sets a reminder)

---

## 🔄 Data Flow Diagram

```
Firebase / API / Mock
        │
        ▼
NotificationRepository
  └── fetchNotifications()
  └── markAsRead()
  └── watchNotifications() ──► Stream (real-time)
        │
        ▼
NotificationListNotifier (AsyncNotifier)
  └── NotificationListState
        │ { notifications, isLoadingMore, hasReachedEnd, currentPage }
        │
        ▼
notificationListProvider  ◄── unreadCountProvider (derived)
        │
        ▼
NotificationListScreen
  └── NotificationTile (per item)
        │ onTap ─► markAsRead() + navigate
        │
        ▼
NotificationDetailScreen
  └── _StickyActions
        │ onPressed ─► ActionDispatcher.dispatch(action)
                           │
                           ├─► NavigateAction  ─► GoRouter.push()
                           ├─► CallbackAction  ─► ActionHandlerRegistry.resolve()
                           ├─► ApiAction       ─► HTTP client
                           └─► ExternalLink    ─► url_launcher
```

---

## 🎨 Design Decisions & Principles

### Why Freezed for models?

Freezed generates `==` equality, `hashCode`, `toString`, and `copyWith` for all models. Riverpod's state management relies on `==` comparisons to decide when to rebuild widgets. Without Freezed, updating a single `isRead` field would require manually implementing `copyWith` and `==` across every model — error-prone at scale.

### Why no Function() in models?

Flutter's widget tree can be rebuilt at any time. Storing `Function()` references in models means:
1. They can't be serialised/deserialised (breaks push notification reconstruction)
2. They create invisible dependencies that are hard to test and trace
3. They cause subtle memory leaks when widgets are disposed

The `handlerKey` + `ActionHandlerRegistry` pattern keeps models as pure data while allowing full flexibility at dispatch time.

### Why a dispatcher instead of direct navigation?

If every widget calls `context.push('/route')` directly:
- Adding analytics logging to every action requires touching every widget
- Testing requires a real `BuildContext`
- The same action button behaves differently across different widgets

With a single `ActionDispatcher`, you add analytics in one place, inject a mock dispatcher in tests, and every action is guaranteed to behave identically regardless of where in the widget tree it is triggered.

### Why three Hero tags per notification?

A single Hero tag on the entire card would cause the card to fly across the screen — visually jarring. Three targeted tags produce professional results:
- `notification_card_{id}` — the container shape morphs
- `notification_title_{id}` — the text slides and scales naturally
- `notification_media_{id}` — the image expands into the detail header

The custom `flightShuttleBuilder` uses a `FadeTransition` to prevent the intermediate "morphing rectangle" flash that default Hero transitions produce.

### Why `AsyncNotifier` instead of `StateNotifier`?

`AsyncNotifier` (Riverpod 2.x) is the modern replacement for `StateNotifier<AsyncValue<T>>`. It:
- Has a single typed `state` that is always `AsyncValue<NotificationListState>`
- Provides a clean `build()` method for initial load (mirrors FutureProvider)
- Makes pagination and error handling significantly cleaner

---

## 🚀 Extending the System

### Notification Grouping (threads)

Add a `threadId` field to `NotificationModel`. In `NotificationListNotifier`, add a grouping method that returns `Map<String, List<NotificationModel>>`. Render a `SliverStickyHeader` per thread in the list screen.

### A/B Testing Different Tile Layouts

Add a `layoutVariant` field to `NotificationModel` (e.g. `'compact'`, `'expanded'`, `'card_with_cta'`). In `NotificationTile.build()`, switch on `layoutVariant` and render a different widget tree. The variant can be controlled server-side.

### Server-Driven UI

Make `NotificationModel.metadata` carry a full JSON UI descriptor. Add a `ServerDrivenTileRenderer` widget that parses the metadata map and builds Flutter widgets at runtime. This allows your backend to change tile layouts without an app update.

### Notification Channels / Topics

Add a `channelId` field and a separate `NotificationChannelRepository` that manages user-level mute/unmute preferences per channel. Filter notifications client-side in `NotificationListNotifier` based on muted channels before surfacing to the UI.

---

## 📦 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.5.0 | State management |
| `riverpod_annotation` | ^2.3.0 | Code generation annotations |
| `freezed_annotation` | ^2.4.0 | Immutable model generation |
| `json_annotation` | ^4.9.0 | JSON serialisation |
| `go_router` | ^14.0.0 | Declarative navigation |
| `cached_network_image` | ^3.3.0 | Image caching with placeholders |
| `intl` | ^0.19.0 | Date/time formatting |
| `build_runner` | ^2.4.0 | Code generation runner (dev) |
| `freezed` | ^2.5.0 | Freezed code generator (dev) |
| `json_serializable` | ^6.8.0 | JSON code generator (dev) |

**Optional (wire up yourself):**
- `url_launcher` — for `ExternalLinkAction`
- `share_plus` — for a share callback action
- `firebase_messaging` — for push notification ingestion
- `web_socket_channel` — for real-time streaming
- `dio` — for `ApiAction` HTTP calls

---

## ❓ FAQ

**Q: How do I show a notification count badge on the bottom navigation bar?**

```dart
// Watch the derived provider from any widget
final count = ref.watch(unreadCountProvider);
// Use `count` in your NavigationBar badge
```

**Q: Can I add notifications programmatically from elsewhere in the app?**

```dart
// From anywhere with access to a WidgetRef or ProviderContainer:
ref.read(notificationRepositoryProvider).addNotification(
  NotificationModel(id: 'my_id', type: NotificationType.system, ...),
);
```

**Q: How do I write tests for the notifier?**

```dart
test('markAsRead updates isRead', () async {
  final container = ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(
        MockNotificationRepository(),
      ),
    ],
  );
  await container.read(notificationListProvider.future);
  await container.read(notificationListProvider.notifier).markAsRead('notif_001');
  final state = container.read(notificationListProvider).value!;
  expect(state.notifications.first.isRead, isTrue);
});
```

**Q: The mock data always looks the same. How do I reset it?**

Call `clearNotifications()` on the repository, then `refresh()` on the notifier. In tests, override the repository provider with a fresh `MockNotificationRepository`.

**Q: How do I deep-link directly to a notification detail from a push notification tap?**

In your `FirebaseMessaging.onMessageOpenedApp` handler, parse the notification ID from the payload and call:

```dart
context.push(UpdatesRoutes.detail, extra: reconstructedNotificationModel);
```

Or navigate to the list and let the user tap the highlighted notification.

**Q: Why does `actionDispatcherProvider` need my router instance?**

`ActionDispatcher` must hold a reference to `GoRouter` to call `router.push()`. Pass your router as `extra` in a provider, or use Riverpod's `ref.read(routerProvider)` if you've registered your `GoRouter` as a provider. This is the only place in the feature that has a dependency on your app's navigation setup.

---

## 📝 License

This system is part of your application codebase. Adapt, extend, and modify freely.

---

*Built for production. Designed for scale. Documented for your team.*