import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/schedules/schedules.dart';
import 'package:frontend/services/data/schedules/delete_schedule.dart';
import 'package:frontend/services/data/schedules/delete_schedule_by_recurrence_id.dart';
import 'package:frontend/services/data/schedules/edit_schedule.dart';
import 'package:frontend/services/data/schedules/get_schedule_by_group_id.dart';
import 'package:frontend/services/data/schedules/get_user_schedules.dart';
import 'package:frontend/services/data/schedules/create_schedule.dart';
import 'package:frontend/models/schedules/schedule_req.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/services/notification/notification_handler.dart';
import 'package:frontend/services/notification/alarm_manager.dart';
import 'package:alarm/alarm.dart';
import 'package:intl/intl.dart';
import 'package:frontend/services/data/schedules/get_schedules.dart';

class ScheduleState {
  final List<Schedule> schedules;
  final bool isProcessing;
  final Map<DateTime, List<Schedule>> schedulesMap;

  ScheduleState({
    required this.schedules,
    this.isProcessing = false,
    Map<DateTime, List<Schedule>>? schedulesMap,
  }) : schedulesMap = schedulesMap ?? {};

  ScheduleState copyWith({
    List<Schedule>? schedules,
    bool? isProcessing,
    Map<DateTime, List<Schedule>>? schedulesMap,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isProcessing: isProcessing ?? this.isProcessing,
      schedulesMap: schedulesMap ?? this.schedulesMap,
    );
  }
}

class ScheduleNotifier extends StateNotifier<AsyncValue<ScheduleState>> {
  final String googleId;
  final NotificationsHandler _notificationsHandler = NotificationsHandler();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  ScheduleNotifier(this.googleId) : super(const AsyncValue.loading()) {
    fetchAllSchedules();
    _initializeAlarm();
  }

  Future<void> _initializeAlarm() async {
    await Alarm.init();
  }

  Map<DateTime, List<Schedule>> _organizeSchedulesByDate(
      List<Schedule> schedules) {
    final Map<DateTime, List<Schedule>> organized = {};
    for (final schedule in schedules) {
      final date = DateFormat('dd-MM-yyyy').parse(schedule.date);
      final dateKey = DateTime(date.year, date.month, date.day);

      if (!organized.containsKey(dateKey)) {
        organized[dateKey] = [];
      }
      organized[dateKey]!.add(schedule);
    }
    return organized;
  }

  Future<void> fetchAllSchedules() async {
    state = const AsyncValue.loading();
    try {
      // Fetch user-created and backend schedules
      final List<Schedule>? userSchedules = await getAllUserSchedules(googleId);
      final String today = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final List<Schedule>? backendSchedules =
          await getAllSchedulesByDate(googleId, today);

      // Combine schedules, ensuring no duplicates
      final List<Schedule> allSchedules = [
        if (userSchedules != null) ...userSchedules,
        if (backendSchedules != null)
          ...backendSchedules.where((backendSchedule) =>
              userSchedules?.every(
                  (userSchedule) => userSchedule.id != backendSchedule.id) ??
              true),
      ];

      // Organize schedules by date and update state
      final Map<DateTime, List<Schedule>> schedulesMap =
          _organizeSchedulesByDate(allSchedules);

      state = AsyncValue.data(ScheduleState(
        schedules: allSchedules,
        schedulesMap: schedulesMap,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> fetchSchedulesForDate(String date) async {
    try {
      // Fetch user schedules and ensure it's a List<Schedule>
      final List<Schedule>? userSchedules = await getAllUserSchedules(googleId);

      // Fetch backend schedules and ensure it's a List<Schedule>
      final List<Schedule>? backendSchedules =
          await getAllSchedulesByDate(googleId, date);

      // Combine the schedules, filtering out duplicates based on schedule ID
      final List<Schedule> allSchedules = [
        if (userSchedules != null)
          ...userSchedules, // Null-checking and spreading
        if (backendSchedules != null)
          ...backendSchedules.where((backendSchedule) =>
              userSchedules?.every(
                  (userSchedule) => userSchedule.id != backendSchedule.id) ??
              true),
      ];

      // Organize schedules by date
      final Map<DateTime, List<Schedule>> schedulesMap =
          _organizeSchedulesByDate(allSchedules);

      // Update state with the combined schedules and schedules map
      state.whenData((currentState) {
        state = AsyncValue.data(currentState.copyWith(
          schedules: allSchedules,
          schedulesMap: schedulesMap,
        ));
      });

      // Set alarms for backend schedules, but only for future schedules
      if (backendSchedules != null) {
        for (final backendSchedule in backendSchedules) {
          final scheduleDate =
              DateFormat('dd-MM-yyyy').parse(backendSchedule.date);
          final timeParts = backendSchedule.startTime.split(':');
          final scheduleDateTime = DateTime(
            scheduleDate.year,
            scheduleDate.month,
            scheduleDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          // Only set alarms for future schedules
          if (scheduleDateTime.isAfter(DateTime.now())) {
            await _setNotificationAndAlarm(backendSchedule);
          }
        }
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addSchedule(ScheduleReq scheduleReq) async {
    try {
      // Step 1: Create the schedule
      await createSchedule(scheduleReq);

      // Step 2: Set alarm for the user-created schedule
      await _setNotificationAndAlarmFromRequest(scheduleReq, autoStop: false);

      // Step 3: Fetch backend schedules related to the new schedule
      final relatedBackendSchedules =
          await getAllSchedulesByDate(googleId, scheduleReq.date);

      if (relatedBackendSchedules != null &&
          relatedBackendSchedules.isNotEmpty) {
        for (final backendSchedule in relatedBackendSchedules) {
          // Set alarms only for backend schedules that don't match the user-created one
          if (backendSchedule.name != scheduleReq.name ||
              backendSchedule.startTime != scheduleReq.startTime) {
            await _setNotificationAndAlarm(backendSchedule, autoStop: false);
          }
        }
      }

      // Step 4: Refresh all schedules after adding
      await fetchAllSchedules();
    } catch (e, stackTrace) {
      print('Error while adding schedule: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _setNotificationAndAlarm(Schedule schedule,
      {bool autoStop = false}) async {
    try {
      final alarmId = AlarmManager.generateAlarmId(schedule.id);

      // Check if the alarm is already active using the new getter
      if (AlarmManager.activeAlarms.contains(alarmId)) {
        print('[ScheduleNotifier] Alarm with id $alarmId is already active.');
        return;
      }

      final scheduledDateTime = DateFormat('dd-MM-yyyy HH:mm').parse(
        '${schedule.date} ${schedule.startTime}',
      );

      if (scheduledDateTime.isAfter(DateTime.now())) {
        await _setAlarm(
          id: alarmId,
          dateTime: scheduledDateTime,
          title: schedule.name,
          body: "Your schedule '${schedule.name}' is starting now!",
          autoStop: autoStop,
        );
      }

      // Set a notification only for the end time, without sound or vibration
      if (schedule.isHaveEndTime && schedule.endTime != null) {
        final endDateTime = DateFormat('dd-MM-yyyy HH:mm').parse(
          '${schedule.date} ${schedule.endTime}',
        );

        if (endDateTime.isAfter(DateTime.now())) {
          final alarmIdEnd = AlarmManager.generateAlarmIdFromRequest(
            schedule.date,
            schedule.startTime,
            schedule.name,
          );
          await _setNotificationOnly(
            id: alarmIdEnd,
            dateTime: endDateTime,
            title: "${schedule.name} - End",
            body: "Your schedule '${schedule.name}' has ended.",
          );
        }
      }
    } catch (e) {
      print('Error setting alarm: $e');
    }
  }

  Future<void> _setNotificationAndAlarmFromRequest(ScheduleReq scheduleReq,
      {bool autoStop = false}) async {
    final startDate = DateFormat('dd-MM-yyyy').parse(scheduleReq.date);
    final startTimeParts = scheduleReq.startTime.split(':');
    final startDateTime = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      int.parse(startTimeParts[0]),
      int.parse(startTimeParts[1]),
    );

    if (startDateTime.isAfter(DateTime.now())) {
      final alarmIdStart = AlarmManager.generateAlarmIdFromRequest(
        scheduleReq.date,
        scheduleReq.startTime,
        scheduleReq.name,
      );
      await _setAlarm(
        id: alarmIdStart,
        dateTime: startDateTime,
        title: scheduleReq.name,
        body: "Your schedule '${scheduleReq.name}' is starting now!",
        autoStop: autoStop,
      );
    }

    // Set notification only for end time if it exists
    if (scheduleReq.isHaveEndTime && scheduleReq.endTime != null) {
      final endTimeParts = scheduleReq.endTime!.split(':');
      final endDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      );

      if (endDateTime.isAfter(DateTime.now())) {
        final alarmIdEnd = AlarmManager.generateAlarmIdFromRequest(
          scheduleReq.date,
          scheduleReq.endTime!,
          scheduleReq.name + "_end",
        );
        await _setNotificationOnly(
          id: alarmIdEnd,
          dateTime: endDateTime,
          title: "${scheduleReq.name} - End",
          body: "Your schedule '${scheduleReq.name}' has ended.",
        );
      }
    }
  }

  Future<void> _setAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    bool autoStop = false,
  }) async {
    await _notificationsHandler.showNotification(
      AlarmSettings(
        id: id,
        dateTime: dateTime,
        notificationTitle: title,
        notificationBody: body,
        assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
        loopAudio: true,
        vibrate: true,
        enableNotificationOnKill: true,
      ),
      isEndTime: false,
    );

    if (autoStop) {
      await AlarmManager.setAlarmWithAutoStop(
        alarmId: id,
        dateTime: dateTime,
        title: title,
        body: body,
        flutterLocalNotificationsPlugin: _flutterLocalNotificationsPlugin,
      );
    } else {
      await AlarmManager.setAlarmWithSound(
        alarmId: id,
        dateTime: dateTime,
        title: title,
        body: body,
      );
    }
  }

  Future<void> _setNotificationOnly({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
  }) async {
    await _notificationsHandler.showNotification(
      AlarmSettings(
        id: id,
        dateTime: dateTime,
        assetAudioPath: "null", // No sound for end notifications
        notificationTitle: title,
        notificationBody: body,
        loopAudio: false, // Ensure it’s non-looping
        vibrate: false, // No vibration
        enableNotificationOnKill:
            true, // Show notification even if app is killed
      ),
      isEndTime: true, // Mark this as an end-time notification
    );
  }

  void updateScheduleFromData(Map<String, dynamic> data) {
    final updatedSchedule =
        Schedule.fromJson(data); // Convert to Schedule object

    // Step 1: Cancel existing alarm for the schedule
    final alarmId = AlarmManager.generateAlarmId(updatedSchedule.id);
    AlarmManager.deleteAlarm(alarmId.toString()); // Remove old alarm

    // Step 2: Update state with the new schedule
    state.whenData((currentState) {
      final updatedSchedules = currentState.schedules.map((schedule) {
        return schedule.id == updatedSchedule.id ? updatedSchedule : schedule;
      }).toList();

      final updatedSchedulesMap = _organizeSchedulesByDate(updatedSchedules);

      state = AsyncValue.data(currentState.copyWith(
        schedules: updatedSchedules,
        schedulesMap: updatedSchedulesMap,
      ));

      // Step 3: Set a new notification or alarm for the updated schedule
      _setNotificationAndAlarm(updatedSchedule, autoStop: false);
    });
  }

  List<Schedule> getSchedulesForDate(DateTime date) {
    return state.when(
      data: (state) {
        final dateKey = DateTime(date.year, date.month, date.day);
        return state.schedulesMap[dateKey] ?? [];
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Future<void> editSchedule(String scheduleId, String name, String date,
      String startTime, String endTime, bool isHaveEndTime) async {
    try {
      await editScheduleService(
          scheduleId, name, date, startTime, endTime, isHaveEndTime);
      await fetchAllSchedules();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteThisSchedule(int groupId) async {
    state = const AsyncValue.loading();
    try {
      await deleteSchedules(groupId);
      // Use the new deleteAlarm method
      await AlarmManager.deleteAlarm(groupId.toString());
      await fetchAllSchedules();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteAllSchedulesByRecurrenceId(int recurrenceId) async {
    state = const AsyncValue.loading();
    try {
      await deleteScheduleByRecurrenceId(recurrenceId, null);
      await fetchAllSchedules();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteThisAndFollowingSchedulesByRecurrenceId(
      int recurrenceId, String date) async {
    state = const AsyncValue.loading();
    try {
      await deleteScheduleByRecurrenceId(recurrenceId, date);
      await fetchAllSchedules();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<List<String>?> getScheduleIdByGroupId(int groupId) async {
    state = const AsyncValue.loading();
    try {
      final schedulesId = await getScheduleByGroupId(groupId);
      return schedulesId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
    return null;
  }

  Future<List<String>?> getScheduleByRecurrenceId(
      int recurrenceId, String date) async {
    state = const AsyncValue.loading();
    try {
      final schedulesId = await getScheduleByRecurrenceId(recurrenceId, date);
      return schedulesId;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
    return null;
  }
}

final scheduleProvider = StateNotifierProvider.family<ScheduleNotifier,
    AsyncValue<ScheduleState>, String>(
  (ref, googleId) => ScheduleNotifier(googleId),
);
