import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _log = Logger('NotificationService');

  final FlutterLocalNotificationsPlugin _plugin;
  GlobalKey<NavigatorState>? _navigatorKey;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_resolveTimezone()));

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Restore scheduled notifications from config
    await _restoreNotifications();
  }

  Future<void> scheduleMealReminder(String mealSlot, int hour, int minute) async {
    final id = _notificationId(mealSlot);
    final body = _bodyForSlot(mealSlot);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      null, // no title — just the body as a gentle nudge
      body,
      scheduledDate,
      details,
      payload: mealSlot,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    _log.fine('Scheduled $mealSlot reminder at $hour:$minute (id=$id)');
  }

  Future<void> cancelMealReminder(String mealSlot) async {
    final id = _notificationId(mealSlot);
    await _plugin.cancel(id);
    _log.fine('Cancelled $mealSlot reminder (id=$id)');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _log.fine('Cancelled all notifications');
  }

  // --- Private helpers ---

  int _notificationId(String mealSlot) {
    switch (mealSlot) {
      case 'breakfast':
        return 1;
      case 'lunch':
        return 2;
      case 'dinner':
        return 3;
      case 'snack':
        return 4;
      default:
        return 0;
    }
  }

  String _bodyForSlot(String mealSlot) {
    switch (mealSlot) {
      case 'breakfast':
        return 'Good morning — want to log breakfast?';
      case 'lunch':
        return 'Lunchtime — want to log something?';
      case 'dinner':
        return 'Dinner time — what did you have?';
      case 'snack':
        return 'Snack check-in — anything to log?';
      default:
        return 'Time to log a meal?';
    }
  }

  AddMealType? _mealTypeForSlot(String? slot) {
    switch (slot) {
      case 'breakfast':
        return AddMealType.breakfastType;
      case 'lunch':
        return AddMealType.lunchType;
      case 'dinner':
        return AddMealType.dinnerType;
      case 'snack':
        return AddMealType.snackType;
      default:
        return null;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    final mealType = _mealTypeForSlot(response.payload);
    final nav = _navigatorKey?.currentState;
    if (nav != null) {
      nav.pushNamed(
        NavigationOptions.addMealRoute,
        arguments: AddMealScreenArguments(mealType, DateTime.now()),
      );
    }
  }

  Future<void> _restoreNotifications() async {
    try {
      final configRepo = locator<ConfigRepository>();
      for (final slot in ['breakfast', 'lunch', 'dinner', 'snack']) {
        final enabled = await configRepo.getNotifEnabled(slot);
        if (enabled) {
          final hour = await configRepo.getNotifHour(slot);
          final minute = await configRepo.getNotifMinute(slot);
          await scheduleMealReminder(slot, hour, minute);
        }
      }
    } catch (e) {
      _log.warning('Failed to restore notifications', e);
    }
  }

  String _resolveTimezone() {
    try {
      final offset = DateTime.now().timeZoneOffset;
      // Attempt to pick a common timezone matching the offset
      final hours = offset.inHours;
      final knownZones = {
        -5: 'America/New_York',
        -6: 'America/Chicago',
        -7: 'America/Denver',
        -8: 'America/Los_Angeles',
        0: 'Europe/London',
        1: 'Europe/Berlin',
        2: 'Europe/Helsinki',
        3: 'Europe/Moscow',
        5: 'Asia/Kolkata',
        8: 'Asia/Shanghai',
        9: 'Asia/Tokyo',
        10: 'Australia/Sydney',
      };
      return knownZones[hours] ?? 'America/New_York';
    } catch (_) {
      return 'America/New_York';
    }
  }
}
