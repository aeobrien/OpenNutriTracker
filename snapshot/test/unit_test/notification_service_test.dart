import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;

@GenerateMocks([FlutterLocalNotificationsPlugin])
import 'notification_service_test.mocks.dart';

void main() {
  late MockFlutterLocalNotificationsPlugin mockPlugin;
  late NotificationService service;

  setUpAll(() {
    tz.initializeTimeZones();
    tzlib.setLocalLocation(tzlib.getLocation('America/New_York'));
  });

  setUp(() {
    mockPlugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: mockPlugin);

    when(mockPlugin.initialize(
      any,
      onDidReceiveNotificationResponse:
          anyNamed('onDidReceiveNotificationResponse'),
      onDidReceiveBackgroundNotificationResponse:
          anyNamed('onDidReceiveBackgroundNotificationResponse'),
    )).thenAnswer((_) async => true);

    when(mockPlugin.zonedSchedule(
      any, any, any, any, any,
      payload: anyNamed('payload'),
      androidScheduleMode: anyNamed('androidScheduleMode'),
      matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
    )).thenAnswer((_) async {});

    when(mockPlugin.cancel(any)).thenAnswer((_) async {});
    when(mockPlugin.cancelAll()).thenAnswer((_) async {});
  });

  group('NotificationService', () {
    test('scheduleMealReminder uses correct id and body per slot', () async {
      final cases = {
        'breakfast': (1, 'Good morning \u2014 want to log breakfast?'),
        'lunch': (2, 'Lunchtime \u2014 want to log something?'),
        'dinner': (3, 'Dinner time \u2014 what did you have?'),
        'snack': (4, 'Snack check-in \u2014 anything to log?'),
      };

      for (final entry in cases.entries) {
        reset(mockPlugin);
        when(mockPlugin.zonedSchedule(
          any, any, any, any, any,
          payload: anyNamed('payload'),
          androidScheduleMode: anyNamed('androidScheduleMode'),
          matchDateTimeComponents: anyNamed('matchDateTimeComponents'),
        )).thenAnswer((_) async {});

        await service.scheduleMealReminder(entry.key, 12, 0);

        final captured = verify(mockPlugin.zonedSchedule(
          captureAny, captureAny, captureAny, captureAny, captureAny,
          payload: captureAnyNamed('payload'),
          androidScheduleMode: captureAnyNamed('androidScheduleMode'),
          matchDateTimeComponents:
              captureAnyNamed('matchDateTimeComponents'),
        )).captured;

        // captured is a flat list: [id, title, body, dateTime, details, payload, androidScheduleMode, matchDateTimeComponents]
        expect(captured[0], entry.value.$1,
            reason: '${entry.key} should have id ${entry.value.$1}');
        expect(captured[1], isNull, reason: 'title should be null');
        expect(captured[2], entry.value.$2,
            reason: '${entry.key} body text');
        expect(captured[5], entry.key,
            reason: 'payload should be slot name');
        expect(captured[7], DateTimeComponents.time,
            reason: 'should repeat daily');
      }
    });

    test('cancelMealReminder cancels by correct id', () async {
      await service.cancelMealReminder('lunch');
      verify(mockPlugin.cancel(2)).called(1);
    });

    test('cancelMealReminder cancels breakfast by id 1', () async {
      await service.cancelMealReminder('breakfast');
      verify(mockPlugin.cancel(1)).called(1);
    });

    test('cancelAll delegates to plugin', () async {
      await service.cancelAll();
      verify(mockPlugin.cancelAll()).called(1);
    });
  });
}
