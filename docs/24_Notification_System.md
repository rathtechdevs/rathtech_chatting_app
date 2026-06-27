# 24 — Notification System

## Purpose
Define the complete push notification architecture — FCM setup, token management, push payload design, all app states, local notification display, and notification privacy.

---

## 1. Notification Architecture

```
New message inserted in Supabase
        │
        ▼ (database webhook trigger)
Supabase Edge Function: send-push-notification
        │
        ├── Lookup recipient's FCM token (user_devices table)
        ├── Check notification mute settings
        └── Call FCM API → send notification
              │
              ▼ (FCM → APNs / GCM)
        Device OS
              │
              ├── App foreground → FlutterLocalNotifications displays in-app banner
              ├── App background → System tray notification
              └── App terminated → System tray notification
```

---

## 2. FCM Setup

### 2.1 Android Configuration

`android/app/build.gradle`:
```groovy
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.x.x'
}
```

`android/app/src/main/AndroidManifest.xml`:
```xml
<service
    android:name=".SecureChatFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>

<!-- Android 13+ notification permission -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 2.2 iOS Configuration

`ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

APNs provisioning: required in App Store Connect → Capabilities → Push Notifications.

---

## 3. FCM Token Management

### 3.1 Token Registration

```dart
class FcmDataSource {
  Future<void> registerToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await _saveTokenToStorage(token);
    await _upsertTokenToServer(token);
  }

  Future<void> _upsertTokenToServer(String token) async {
    await _supabase.from('user_devices').upsert(
      {
        'user_id': _supabase.auth.currentUser!.id,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id, fcm_token',
    );
  }
}
```

### 3.2 Token Refresh

FCM tokens can be rotated by the system:

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  _fcmDataSource.registerToken();
});
```

### 3.3 Token on Logout

On logout, the FCM token is NOT deleted from `user_devices` immediately (edge function needs it for delivery until the next login). Instead:
- Token is removed when user logs in with a new token (upsert replaces old token)
- Or: add a `logged_out_at` timestamp and filter in edge function

---

## 4. Notification Payload Design

### 4.1 FCM Payload (sent by Edge Function)

```json
{
  "to": "<fcm_token>",
  "notification": {
    "title": "Alex",
    "body": "Sent you a message"
  },
  "data": {
    "type": "new_message",
    "pair_id": "uuid",
    "notification_id": "uuid"
  },
  "apns": {
    "payload": {
      "aps": {
        "content-available": 1,
        "sound": "default",
        "badge": 1
      }
    }
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "messages",
      "sound": "default"
    }
  }
}
```

**Security note:** Message content is NEVER included in the payload. Only the sender's display name and a generic body string.

### 4.2 Data Payload Fields

| Field | Purpose |
|---|---|
| `type` | `new_message` — allows future types (pair_request, system) |
| `pair_id` | Navigate to correct chat on tap |
| `notification_id` | For deduplication (avoid showing twice) |

---

## 5. Handling Notifications in All App States

### 5.1 Foreground State

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // App is in foreground — FCM does NOT show system notification automatically
  // We use FlutterLocalNotifications to show an in-app banner
  _showLocalNotification(message);
});
```

```dart
void _showLocalNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'messages',                    // channel ID
    'Messages',                    // channel name
    channelDescription: 'New message notifications',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );
  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  _localNotifications.show(
    message.hashCode,
    message.notification?.title ?? AppStrings.newMessage,
    message.notification?.body ?? AppStrings.newMessageBody,
    const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    ),
    payload: jsonEncode(message.data),
  );
}
```

### 5.2 Background State

```dart
// This MUST be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System shows the notification automatically from FCM payload
  // We can do background processing here (e.g., update badge count)
  await Firebase.initializeApp();
  // Don't do heavy work here — just log and return quickly
  AppLogger.debug('Background message received: ${message.messageId}');
}

// Registered in main.dart:
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

### 5.3 App Terminated (Cold Start from Notification)

```dart
// In main.dart initialization
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  _handleNotificationTap(initialMessage.data);
}

// App opened from notification tap (background → foreground)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  _handleNotificationTap(message.data);
});
```

```dart
void _handleNotificationTap(Map<String, dynamic> data) {
  if (data['type'] == 'new_message') {
    // Navigate to chat screen
    final router = container.read(routerProvider);
    router.go(AppRoutes.chat);
  }
}
```

---

## 6. Notification Permission

```dart
class NotificationPermissionService {
  Future<bool> requestPermission() async {
    // iOS: explicit permission request
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android 13+: uses flutter_local_notifications to show system dialog
    if (Platform.isAndroid) {
      final permission = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return permission ?? false;
    }

    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}
```

**UX:** Permission requested after first message is received (not immediately on app launch).

---

## 7. Notification Channels (Android)

```dart
void _createNotificationChannels() {
  const channel = AndroidNotificationChannel(
    'messages',                              // ID
    'Messages',                              // Name
    description: 'New message notifications',
    importance: Importance.high,
    playSound: true,
    showBadge: true,
  );

  _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}
```

---

## 8. Notification Mute

Stored in `user_settings.notification_muted_until`. The Edge Function checks this before sending:

```typescript
// In Edge Function: send-push-notification
const settings = await supabase
  .from('user_settings')
  .select('notification_muted_until')
  .eq('user_id', recipientId)
  .single();

if (settings.notification_muted_until &&
    new Date(settings.notification_muted_until) > new Date()) {
  // Muted — don't send push
  return;
}
```

---

## 9. Badge Count

### Android
Badge count shown on app icon via notification payload `badge` field.

### iOS
```dart
// Clear badge when app is opened
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  badge: true,
);
// Reset badge on app foreground
FirebaseMessaging.instance.getAPNSToken().then((_) {
  // iOS badge clear
  _localNotifications.cancelAll();
});
```

---

## 10. Notification Privacy

| Scenario | What User Sees |
|---|---|
| Phone locked | "Alex — Sent you a message" |
| App in background | "Alex — Sent you a message" |
| Notification preview disabled (device setting) | No preview |
| Notification muted | No notification |

**Never shown in notification:**
- Message text content
- Media thumbnails
- Any encrypted data

---

## 11. Supabase Edge Function: `send-push-notification`

```typescript
// supabase/functions/send-push-notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { record } = await req.json()  // message INSERT record from webhook

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )

  // Get pair members
  const { data: pair } = await supabase
    .from('pairs')
    .select('user_a_id, user_b_id')
    .eq('id', record.pair_id)
    .single()

  const recipientId = pair.user_a_id === record.sender_id
    ? pair.user_b_id
    : pair.user_a_id

  // Get recipient's FCM token
  const { data: device } = await supabase
    .from('user_devices')
    .select('fcm_token')
    .eq('user_id', recipientId)
    .single()

  if (!device?.fcm_token) return new Response('No FCM token', { status: 200 })

  // Check mute setting
  const { data: settings } = await supabase
    .from('user_settings')
    .select('notification_muted_until')
    .eq('user_id', recipientId)
    .single()

  if (settings?.notification_muted_until &&
      new Date(settings.notification_muted_until) > new Date()) {
    return new Response('Muted', { status: 200 })
  }

  // Get sender's display name
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('display_name')
    .eq('user_id', record.sender_id)
    .single()

  // Send FCM
  const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      to: device.fcm_token,
      notification: {
        title: profile?.display_name ?? 'SecureChat',
        body: 'Sent you a message',
      },
      data: {
        type: 'new_message',
        pair_id: record.pair_id,
      },
    }),
  })

  return new Response(JSON.stringify({ ok: fcmResponse.ok }), { status: 200 })
})
```
