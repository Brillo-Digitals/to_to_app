import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:to_do_app/models/task.dart';


const _kChannelId = 'task_channel';
const _kChannelName = 'Task Notifications';


class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false, // ask explicitly later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap — e.g. navigate to the task detail screen.
    // Use a GlobalKey<NavigatorState> or a router to navigate.
  }

  /// Returns `true` if the user has granted notification permission.
  static Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? false;
    }

    if (Platform.isIOS) {
      // v20: renamed from IOSFlutterLocalNotificationsPlugin
      final darwin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final settings = await darwin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    return false;
  }

  /// Asks the OS for notification permission.
  /// Call this from your onboarding or settings screen.
  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }

    if (Platform.isIOS) {
      final darwin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await darwin?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Shows a notification immediately.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!await hasPermission()) return;

    // v20: show() uses named parameters
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _buildDetails(),
    );
  }

  /// Schedules a notification at [dateTime].
  /// Silently skips past datetimes.
  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!await hasPermission()) return;

    // Don't schedule in the past.
    if (dateTime.isBefore(DateTime.now())) return;

    final tzDate = tz.TZDateTime.from(dateTime, tz.local);

    // Try exact alarm first, fall back to inexact if permission is denied.
    try {
      // v20: zonedSchedule() uses named parameters
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (e) {
      debugPrint('[NotificationService] Exact alarm denied, using inexact: $e');

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Cancels a single notification by id.
  // v20: cancel() uses named `id` parameter
  static Future<void> cancel(int id) => _plugin.cancel(id: id);

  /// Cancels all pending notifications.
  static Future<void> cancelAll() => _plugin.cancelAll();


  static NotificationDetails _buildDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}

/// Converts a task's string id into a stable positive int notification id.
int _idFor(String taskId, {int offset = 0}) =>
    (taskId.hashCode & 0x7fffffff) + offset;

/// Schedules up to 4 future notifications for a task:
///   +1 → at exact end time   (overdue)
///   +2 → 12 h before end
///   +3 → 48 h before end
///   +4 → at start time
///
/// Safe to call on both task create and update — old notifications are
/// cancelled first so you never get duplicates.
Future<void> scheduleTaskNotifications(Task task) async {
  // Always cancel existing ones first to avoid duplicates on edit.
  await cancelTaskNotifications(task);

  final now = DateTime.now();
  final end = task.endsAt;

  // Overdue — fires at the exact moment the task ends.
  await NotificationService.schedule(
    id: _idFor(task.id, offset: 1),
    title: 'Task Overdue 🚨',
    body: '${task.title} is overdue!',
    dateTime: end,
  );

  // 12-hour warning.
  final twelveHourMark = end.subtract(const Duration(hours: 12));
  if (twelveHourMark.isAfter(now)) {
    await NotificationService.schedule(
      id: _idFor(task.id, offset: 2),
      title: 'Urgent ⏰',
      body: '${task.title} is due in 12 hours',
      dateTime: twelveHourMark,
    );
  }

  // 48-hour warning.
  final fortyEightHourMark = end.subtract(const Duration(hours: 48));
  if (fortyEightHourMark.isAfter(now)) {
    await NotificationService.schedule(
      id: _idFor(task.id, offset: 3),
      title: 'Reminder 📌',
      body: '${task.title} is due in 48 hours',
      dateTime: fortyEightHourMark,
    );
  }

  // Started.
  if (task.startsAt.isAfter(now)) {
    await NotificationService.schedule(
      id: _idFor(task.id, offset: 4),
      title: 'Task Started ▶️',
      body: '${task.title} has started',
      dateTime: task.startsAt,
    );
  }
}

/// Cancels all scheduled notifications for [task].
Future<void> cancelTaskNotifications(Task task) async {
  for (int offset = 1; offset <= 4; offset++) {
    await NotificationService.cancel(_idFor(task.id, offset: offset));
  }
}

// Call this when the user marks a task as complete.
Future<void> onTaskCompleted(Task task) async {
  // Cancel all pending reminders.
  await cancelTaskNotifications(task);

  await NotificationService.show(
    id: _idFor(task.id),
    title: 'Completed ✅',
    body: 'You completed "${task.title}"',
  );
}

void onTaskCreated(Task task) async {
  await scheduleTaskNotifications(task);
}

void onTaskUpdated(Task task) async {
  await scheduleTaskNotifications(task);
}

void onCheckboxTapped(Task task) async {
  await onTaskCompleted(task);
}

void onTaskDeleted(Task task) async {
  await cancelTaskNotifications(task);
}
