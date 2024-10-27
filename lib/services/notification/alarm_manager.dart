import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AlarmManager {
  static final Map<int, Timer> _alarmTimers = {};
  static final Set<int> _activeAlarms = {};

  static Set<int> get activeAlarms => _activeAlarms;

  // Helper method to generate consistent alarm ID from schedule
  static int generateAlarmId(String scheduleId) {
    return scheduleId.hashCode % 0x7FFFFFFF;
  }

  // Helper method to generate consistent alarm ID from request
  static int generateAlarmIdFromRequest(
      String date, String startTime, String name) {
    final idString = '$date-$startTime-$name';
    return idString.hashCode % 0x7FFFFFFF;
  }

  static Future<void> setAlarmWithSound({
    required int alarmId,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: dateTime,
      assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
      notificationTitle: title,
      notificationBody: body,
      loopAudio: true,
      vibrate: true,
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
    print('Alarm set for: $dateTime with ID: $alarmId'); // Debug print
    _activeAlarms.add(alarmId);
  }

  static Future<void> setAlarmWithAutoStop({
    required int alarmId,
    required DateTime dateTime,
    required String title,
    required String body,
    required FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  }) async {
    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: dateTime.add(const Duration(seconds: 1)), // Slight delay
      assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
      notificationTitle: title,
      notificationBody: body,
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
    _activeAlarms.add(alarmId);

    // Set up a timer to stop the alarm after 15 minutes
    _alarmTimers[alarmId] = Timer(const Duration(minutes: 15), () {
      Alarm.stop(alarmId);
      _alarmTimers.remove(alarmId);
      _activeAlarms.remove(alarmId);
    });
  }

  static Future<void> deleteAlarm(String scheduleId) async {
    final alarmId = generateAlarmId(scheduleId);

    if (_activeAlarms.contains(alarmId)) {
      await stopAlarm(alarmId);
    }
  }

  static Future<void> stopAlarm(int alarmId) async {
    if (!_activeAlarms.contains(alarmId))
      return; // Guard to prevent redundant stops

    print('[AlarmManager] Stopping alarm with id: $alarmId');
    await Alarm.stop(alarmId);
    _alarmTimers[alarmId]?.cancel();
    _alarmTimers.remove(alarmId);
    _activeAlarms.remove(alarmId);
  }

  static void cancelAlarmTimer(int alarmId) {
    _alarmTimers[alarmId]?.cancel();
    _alarmTimers.remove(alarmId);
  }
}
