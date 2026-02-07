import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:to_do_app/models/task.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> requestExactAlarmsPermission() async {
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  await androidPlugin?.requestExactAlarmsPermission();
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (Platform.isAndroid) {
      // Ask user to allow exact alarms (opens system settings if needed)
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    try {
      // Try scheduling exact alarm
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // If exact alarms are denied, fallback to inexact
      print("Exact alarms not permitted, scheduling inexact: $e");

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            'Task Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  static Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
  }

  /// Call once in main()
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);
  }

  /// 🔐 Permission check (Android + iOS)
  static Future<bool> hasPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      return await android?.areNotificationsEnabled() ?? false;
    }

    // iOS: no reliable runtime check → assume granted after request
    if (Platform.isIOS) {
      return true;
    }

    return false;
  }

  /// Ask permission (call from settings page)
  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// 🔔 Show notification safely
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    final allowed = await hasPermission();
    if (!allowed) return; // 🚫 no permission → no noise

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'tasks_channel',
        'Tasks',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

enum TaskAlertType { overdue, lessThan12h, lessThan48h, started, completed }

TaskAlertType? getTaskAlert(Task task) {
  final now = DateTime.now();

  if (task.isDone) return TaskAlertType.completed;

  if (now.isAfter(task.endsAt)) {
    return TaskAlertType.overdue;
  }

  final hoursLeft = task.endsAt.difference(now).inHours;

  if (hoursLeft <= 12) return TaskAlertType.lessThan12h;
  if (hoursLeft <= 48) return TaskAlertType.lessThan48h;

  if (now.isAfter(task.startsAt)) return TaskAlertType.started;

  return null;
}

int notificationIdFromString(String value) {
  return value.hashCode & 0x7fffffff; // always positive int
}

void notifyForTask(Task task) {
  final alert = getTaskAlert(task);
  if (alert == null) return;

  switch (alert) {
    case TaskAlertType.overdue:
      NotificationService.show(
        id: notificationIdFromString(task.id),
        title: 'Task Overdue 🚨',
        body: '${task.title} is overdue!',
      );
      break;

    case TaskAlertType.lessThan12h:
      NotificationService.show(
        id: notificationIdFromString(task.id),
        title: 'Urgent ⏰',
        body: '${task.title} is due in less than 12 hours',
      );
      break;

    case TaskAlertType.lessThan48h:
      NotificationService.show(
        id: notificationIdFromString(task.id),
        title: 'Reminder 📌',
        body: '${task.title} is due soon',
      );
      break;

    case TaskAlertType.started:
      NotificationService.show(
        id: notificationIdFromString(task.id),
        title: 'Task Started ▶️',
        body: '${task.title} has started',
      );
      break;

    case TaskAlertType.completed:
      NotificationService.show(
        id: notificationIdFromString(task.id),
        title: 'Completed ✅',
        body: 'You completed ${task.title}',
      );
      break;
  }
}

void onTaskCompleted(Task task) async {
  int notificationIdFromString(String value) {
    return value.hashCode & 0x7fffffff; // always positive int
  }

  // Cancel pending reminders
  for (int i = 1; i <= 4; i++) {
    await NotificationService.cancel(notificationIdFromString(task.id) + i);
  }

  // Fire completion notification
  try {
    NotificationService.show(
      id: notificationIdFromString(task.id),
      title: 'Completed ✅',
      body: 'You completed ${task.title}',
    );
  } catch (e) {
    null;
  }
}

void scheduleTaskNotifications(Task task) {
  final now = DateTime.now();
  final end = task.endsAt;

  // 🔴 Overdue (at exact end time)
  try {
    NotificationService.schedule(
      id: notificationIdFromString(task.id) + 1,
      title: 'Task Overdue 🚨',
      body: '${task.title} is overdue',
      dateTime: end,
    );
  } catch (e) {
    null;
  }

  // 🟠 Less than 12 hours
  try {
    if (end.subtract(const Duration(hours: 12)).isAfter(now)) {
      NotificationService.schedule(
        id: notificationIdFromString(task.id) + 2,
        title: 'Urgent ⏰',
        body: '${task.title} is due in 12 hours',
        dateTime: end.subtract(const Duration(hours: 12)),
      );
    }

    // 🟡 Less than 48 hours
    if (end.subtract(const Duration(hours: 48)).isAfter(now)) {
      NotificationService.schedule(
        id: notificationIdFromString(task.id) + 3,
        title: 'Reminder 📌',
        body: '${task.title} is due in 48 hours',
        dateTime: end.subtract(const Duration(hours: 48)),
      );
    }

    // ▶️ Started
    if (task.startsAt.isAfter(now)) {
      NotificationService.schedule(
        id: notificationIdFromString(task.id) + 4,
        title: 'Task Started ▶️',
        body: '${task.title} has started',
        dateTime: task.startsAt,
      );
    }
  } catch (e) {
    null;
  }
}
