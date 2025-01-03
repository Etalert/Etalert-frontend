import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/custom_schedule_dialog.dart';
import 'package:frontend/components/edit_schedule_dialog.dart';
import 'package:frontend/components/sidebar.dart';
import 'package:frontend/models/maps/location.dart';
import 'package:frontend/models/routine/routine_tag.dart';
import 'package:frontend/models/schedules/schedule_req.dart';
import 'package:frontend/models/schedules/schedules.dart';
import 'package:frontend/models/user/user_info.dart';
import 'package:frontend/providers/schedule_provider.dart';
import 'package:frontend/providers/web_socket_provider.dart';
import 'package:frontend/services/data/routine/create_routine_log.dart';
import 'package:frontend/services/notification/notification_handler.dart';
import 'package:frontend/screens/selectlocation.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:frontend/services/data/schedules/get_schedules.dart';
import 'package:frontend/screens/selectoriginlocation.dart';
import 'package:frontend/services/notification/alarm_manager.dart';
import 'dart:async';

class Calendar extends ConsumerStatefulWidget {
  final String googleId;
  const Calendar({super.key, required this.googleId});

  @override
  ConsumerState<Calendar> createState() => _CalendarState();
}

class _CalendarState extends ConsumerState<Calendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now().toLocal();
  DateTime _focusedDay = DateTime.now().toLocal();
  UserData? data;
  bool isLoading = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // Updated to store a list of maps with detailed event info
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};
  TextEditingController originLocationController = TextEditingController();
  LatLng? _originLatLng;
  BuildContext? _currentDialogContext;
  int? _currentActiveAlarmId; // Track the currently ringing alarm

  GoogleMapController? mapController;
  LatLng _center = const LatLng(13.6512574, 100.4938679);
  Set<Marker> _marker = {};
  late SelectedLocation destinationLocation;
  final NotificationsHandler _notificationsHandler = NotificationsHandler();
  StreamSubscription? _alarmSubscription;
  bool _isAlarmInitialized = false;
  final Set<String> _processedScheduleIds = {};
  final Set<String> _shownNotifications = {};
  final Map<String, int> _scheduleAlarmIds =
      {}; // Store alarm IDs by scheduleId

  @override
  void initState() {
    super.initState();
    _notificationsHandler.initialize();
    _setInitialLocation();
    _initializeAlarm();
  }

  @override
  void dispose() {
    // Cancel alarm subscription
    _alarmSubscription?.cancel();
    _alarmSubscription = null;
    _isAlarmInitialized = false;
    _processedScheduleIds.clear();
    _shownNotifications.clear();
    super.dispose();
  }

  Future<void> _initializeAlarm() async {
    if (_isAlarmInitialized) return;

    try {
      await Alarm.init();
      _alarmSubscription = Alarm.ringStream.stream.listen(
        (alarmSettings) {
          print('Alarm triggered: ${alarmSettings.id}');
          if (mounted) _showAlarmDialog(alarmSettings);
        },
        onError: (error) {
          print('Error in alarm stream: $error');
        },
      );
      _isAlarmInitialized = true;
      print('Alarm initialized successfully');
    } catch (e) {
      print('Error initializing alarm: $e');
      _isAlarmInitialized = false;
    }
  }

  Future<void> _setInitialLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _center = LatLng(position.latitude, position.longitude);
      _marker.clear();
      _marker.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: _center,
      ));
    });
  }

  Future<List<String>> _getSuggestions(String query) async {
    List<Location> locations = await locationFromAddress(query);
    return locations
        .map((location) => "${location.latitude}, ${location.longitude}")
        .toList();
  }

  Future<void> _selectSuggestion(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        LatLng latLng = LatLng(location.latitude, location.longitude);

        mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));

        setState(() {
          _marker.clear();
          _marker.add(Marker(
            markerId: const MarkerId('searchedLocation'),
            position: latLng,
          ));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
        ),
      );
    }
  }

  Future<void> setAlarm(
      int scheduleId, DateTime dateTime, String title, String body) async {
    if (_processedScheduleIds.contains(scheduleId.toString())) {
      print('Alarm already set for schedule $scheduleId at $dateTime');
      return;
    }

    final alarmSettings = AlarmSettings(
      id: scheduleId,
      dateTime: dateTime,
      notificationTitle: title,
      notificationBody: body,
      assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
    print('Alarm set for schedule ID $scheduleId at $dateTime');

    _scheduleAlarmIds[scheduleId.toString()] = scheduleId;
    _processedScheduleIds.add(scheduleId.toString());
  }

  Future<void> setAlarmWithCancel(int scheduleId, DateTime dateTime,
      String title, String body, String uniqueId) async {
    final uniqueKey = '${scheduleId}_${dateTime.toIso8601String()}';

    final alarmId = scheduleId;

    // Stop existing alarm
    await AlarmManager.stopAlarm(alarmId);

    // Ensure the alarm does not re-trigger after being stopped
    if (!AlarmManager.activeAlarms.contains(alarmId)) {
      print('[AlarmManager] Alarm canceled: $alarmId');
      return;
    }

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: dateTime,
      notificationTitle: title,
      notificationBody: body,
      assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
    print('Alarm reset successfully with ID: $alarmId at $dateTime');

    // Add back to processed set
    _processedScheduleIds.add(uniqueKey);
  }

  Future<void> _handleRoutineLog(
      AlarmSettings alarmSettings, String actualEndTime) async {
    try {
      Map<String, dynamic>? eventDetails;
      DateTime? eventDate;

      // Search through _events to find matching event
      for (var entry in _events.entries) {
        final events = entry.value;
        for (var event in events) {
          if (AlarmManager.generateAlarmId(event['id']) == alarmSettings.id) {
            eventDetails = event;
            eventDate = entry.key;
            break;
          }
        }
        if (eventDetails != null) break;
      }

      if (eventDetails != null && eventDate != null) {
        final date = formatDate(eventDate);
        final startTime = (eventDetails['time'] as TimeOfDay).format(context);
        final endTime = (eventDetails['endTime'] as TimeOfDay).format(context);

        // Calculate skewness
        final actualTimeOfDay = TimeOfDay.now();
        final scheduledEndTimeOfDay = eventDetails['endTime'] as TimeOfDay;
        final actualMinutes =
            actualTimeOfDay.hour * 60 + actualTimeOfDay.minute;
        final scheduledMinutes =
            scheduledEndTimeOfDay.hour * 60 + scheduledEndTimeOfDay.minute;
        final skewness = actualMinutes - scheduledMinutes;

        // Create routine log only if this is a routine event
        if (eventDetails['routineId'] != "") {
          await createRoutineLog(
            eventDetails['routineId'],
            widget.googleId,
            date,
            startTime,
            endTime,
            actualEndTime,
            skewness,
          );
          print('Routine log created successfully');
        }
      }
    } catch (e) {
      print('Error creating routine log: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log routine completion')),
        );
      }
    }
  }

  Future<void> _showAlarmDialog(AlarmSettings alarmSettings) async {
    final int scheduleId = alarmSettings.id;
    final uniqueKey =
        '${scheduleId}_${alarmSettings.dateTime.toIso8601String()}';

    // Check if this alarm has already been shown
    if (_shownNotifications.contains(uniqueKey)) {
      print('Dialog already shown for schedule $scheduleId');
      return;
    }

    // Stop the previous alarm if one is active
    if (_currentActiveAlarmId != null) {
      await _stopAlarm(_currentActiveAlarmId!);
    }

    // Dismiss any existing dialog
    if (_currentDialogContext != null) {
      _dismissCurrentDialog();
    }

    // Set the new active alarm ID
    _currentActiveAlarmId = scheduleId;

    // Find matching events
    List<Map<String, dynamic>> matchingEvents = [];
    DateTime? eventDate;

    final alarmTime = TimeOfDay(
      hour: alarmSettings.dateTime.hour,
      minute: alarmSettings.dateTime.minute,
    );

    for (var entry in _events.entries) {
      final events = entry.value;
      for (var event in events) {
        final eventTime = event['time'] as TimeOfDay;
        if (eventTime.hour == alarmTime.hour &&
            eventTime.minute == alarmTime.minute) {
          matchingEvents.add(event);
          if (eventDate == null) {
            eventDate = entry.key;
          }
        }
      }
    }

    if (matchingEvents.isEmpty) return; // No matching events, exit

    // Show the new dialog and update the context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          // Store the current dialog context
          _currentDialogContext = dialogContext;

          return AlertDialog(
            title: Text(alarmSettings.notificationTitle ?? 'Schedules Due'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('The following schedules are due:'),
                  const SizedBox(height: 8),
                  ...matchingEvents.map((event) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• ${event['name']}'),
                      )),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () async {
                  // final now = TimeOfDay.now();
                  // final actualEndTime = now.format(context);
                  // final bool isEndTimeAlarm = alarmSettings.notificationTitle?.contains("End") ?? false;

                  // await _handleRoutineLog(alarmSettings, actualEndTime, isEndTimeAlarm);
                  await Alarm.stop(alarmSettings.id);
                  // AlarmManager.cancelAlarmTimer(alarmSettings.id);

                  Navigator.of(dialogContext).pop(); // Close dialog
                  _currentDialogContext = null; // Reset the context

                  // Add to shown notifications set
                  _shownNotifications.add(uniqueKey);

                  // Allow future notifications after delay
                  Future.delayed(const Duration(hours: 24), () {
                    _shownNotifications.remove(uniqueKey);
                    _processedScheduleIds.remove(uniqueKey);
                  });
                  _stopAlarmAndDismiss(alarmSettings);
                },
                child: const Text('Stop Alarm', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _stopAlarm(int alarmId) async {
    try {
      // Stop the alarm and cancel any associated timers
      await Alarm.stop(alarmId);
      //AlarmManager.cancelAlarmTimer(alarmId);
      print('Alarm with ID $alarmId stopped.');
    } catch (e) {
      print('Error stopping alarm $alarmId: $e');
    }
  }

  Future<void> _stopAlarmAndDismiss(AlarmSettings alarmSettings) async {
    try {
      // Stop the alarm sound
      await Alarm.stop(alarmSettings.id);
      //AlarmManager.cancelAlarmTimer(alarmSettings.id);

      // Dismiss the dialog
      if (_currentDialogContext != null) {
        Navigator.of(_currentDialogContext!).pop();
        _currentDialogContext = null;
      }
      print('Alarm stopped and dialog dismissed successfully.');
    } catch (e) {
      print('Error stopping alarm: $e');
    }
  }

  void _dismissCurrentDialog() {
    if (_currentDialogContext != null) {
      Navigator.of(_currentDialogContext!).pop(); // Dismiss the dialog
      _currentDialogContext = null; // Reset dialog context
    }
  }

  String formatDate(DateTime date) {
    var dateTime = date.toLocal();
    String formattedDate =
        '${dateTime.day.toString().length == 1 ? '0${dateTime.day}' : '${dateTime.day}'}-${dateTime.month.toString().length == 1 ? '0${dateTime.month}' : '${dateTime.month}'}-${dateTime.year}';
    return formattedDate;
  }

  TimeOfDay formatTime(String time) {
    final times = time.split(':');
    return TimeOfDay(hour: int.parse(times[0]), minute: int.parse(times[1]));
  }

  Future<List<Schedule>?> getSchedule(String date) async {
    final data = await getAllSchedulesByDate(widget.googleId, date);

    if (data != null) {
      return data;
    }
    return null;
  }

  void _processSchedules(List<Schedule> schedules) {
    var groupId;
    setState(() {
      _events.clear(); // Clear existing events before processing
      for (var schedule in schedules) {
        final date = DateFormat('dd-MM-yyyy')
            .parse(schedule.date)
            .add(const Duration(hours: 7));

        schedule.endTime == "" ? schedule.startTime : schedule.endTime;
        final event;

        if (schedule.isHaveEndTime) {
          event = {
            'id': schedule.id,
            'routineId': schedule.routineId ?? "",
            'name': schedule.name,
            'date': schedule.date,
            'time': TimeOfDay(
              hour: int.parse(schedule.startTime.split(':')[0]),
              minute: int.parse(schedule.startTime.split(':')[1]),
            ),
            'endTime': schedule.endTime != null
                ? TimeOfDay(
                    hour: int.parse(schedule.endTime!.split(':')[0]),
                    minute: int.parse(schedule.endTime!.split(':')[1]))
                : null,
            'location': schedule.destinationName,
            'originLocation': schedule.originName,
            'isHaveEndTime': schedule.isHaveEndTime,
            'groupId': schedule.groupId,
            'priority': schedule.priority,
            'recurrence': schedule.recurrence,
            'recurrenceId': schedule.recurrenceId,
            'transportation': schedule.transportation,
          };
        } else {
          event = {
            'id': schedule.id,
            'name': schedule.name,
            'date': schedule.date,
            'time': TimeOfDay(
              hour: int.parse(schedule.startTime.split(':')[0]),
              minute: int.parse(schedule.startTime.split(':')[1]),
            ),
            'location': schedule.destinationName,
            'originLocation': schedule.originName,
            'isHaveEndTime': schedule.isHaveEndTime,
            'groupId': schedule.groupId,
            'priority': schedule.priority,
            'recurrence': schedule.recurrence,
            'recurrenceId': schedule.recurrenceId,
            'transportation': schedule.transportation,
          };
        }

        if (_events[date.toUtc()] == null) {
          _events[date.toUtc()] = [];
        }
        _events[date.toUtc()]!.add(event);
      }
      _buildTimeline();
    });
  }

  Future<void> _createSchedule(
    String scheduleName,
    String date,
    String startTime,
    String? endTime,
    bool isHaveEndTime,
    String? oriName,
    double? orilat,
    double? orilng,
    String? desName,
    double? deslat,
    double? deslng,
    bool isFirstSchedule,
    RoutineTag? selectedRoutineTag,
    DateTime selectedDay,
    bool isHaveLocation,
    String recurrence,
    String transportation,
  ) async {
    try {
      final bool isHaveLocation = oriName != null &&
          desName != null &&
          orilat != null &&
          orilng != null &&
          deslat != null &&
          deslng != null;

      final req;

      if (isFirstSchedule && selectedRoutineTag != null) {
        req = ScheduleReq(
          googleId: widget.googleId,
          name: scheduleName,
          date: date,
          startTime: startTime,
          endTime: endTime,
          isHaveEndTime: isHaveEndTime,
          oriName: oriName,
          oriLatitude: orilat,
          oriLongtitude: orilng,
          desName: desName,
          destLatitude: deslat,
          destLongtitude: deslng,
          isHaveLocation: isHaveLocation,
          isFirstSchedule: isFirstSchedule,
          tagId: selectedRoutineTag.id,
          recurrence: recurrence,
          transportation: transportation,
        );
      } else {
        req = ScheduleReq(
          googleId: widget.googleId,
          name: scheduleName,
          date: date,
          startTime: startTime,
          endTime: endTime,
          isHaveEndTime: isHaveEndTime,
          oriName: oriName,
          oriLatitude: orilat,
          oriLongtitude: orilng,
          desName: desName,
          destLatitude: deslat,
          destLongtitude: deslng,
          isHaveLocation: isHaveLocation,
          isFirstSchedule: isFirstSchedule,
          recurrence: recurrence,
          transportation: transportation,
        );
      }

      await ref
          .read(scheduleProvider(widget.googleId).notifier)
          .addSchedule(req);

      print('Schedule created successfully!');
    } catch (e) {
      // Handle any errors and print them for debugging
      print('Error creating schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create schedule.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleState = ref.watch(scheduleProvider(widget.googleId));

    return scheduleState.when(
      data: (scheduleState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _processSchedules(scheduleState.schedules);
        });

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'ETAlert',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          drawer: Sidebar(googleId: widget.googleId),
          body: SafeArea(
            child: Column(
              children: [
                TableCalendar(
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    markersMaxCount: 1,
                  ),
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    getSchedule(formatDate(selectedDay));
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    return _events[day]
                            ?.map((event) => event['name'] ?? '')
                            .toList() ??
                        [];
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 Weeks',
                    CalendarFormat.week: 'Week',
                  },
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: _buildTimeline(),
                ),
                const SizedBox(height: 8.0),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            shape: const CircleBorder(),
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _addEventDialog(context),
          ),
        );
      },
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error Stack: $stack')),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildTimeline() {
    List<Map<String, dynamic>> events = _events[_selectedDay] ?? [];

    events.sort((a, b) {
      TimeOfDay timeA = a['time'];
      TimeOfDay timeB = b['time'];
      return timeA.hour.compareTo(timeB.hour) == 0
          ? timeA.minute.compareTo(timeB.minute)
          : timeA.hour.compareTo(timeB.hour);
    });

    if (events.isEmpty) {
      return const Center(child: Text('No events today'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final time =
            event['time'] as TimeOfDay? ?? const TimeOfDay(hour: 0, minute: 0);
        final title = event['name'] as String? ?? 'No Title';
        final location = event['location'] as String? ?? 'No Location';

        return GestureDetector(
          onTap: () {
            _showEventDetailsDialog(context, event);
          },
          child: TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.2,
            beforeLineStyle: LineStyle(
                color: Theme.of(context).colorScheme.primary, thickness: 2),
            afterLineStyle: LineStyle(
                color: Theme.of(context).colorScheme.primary, thickness: 2),
            indicatorStyle: IndicatorStyle(
              width: 20,
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.all(6),
            ),
            startChild: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                time.format(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            endChild: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    title,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500),
                  )),
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelAlarmAndNotification(int alarmId) async {
    try {
      // Stop the alarm and cancel the notification using the hashed alarm ID
      await Alarm.stop(alarmId);
      await flutterLocalNotificationsPlugin.cancel(alarmId);
      print('Alarm and notification canceled for ID: $alarmId');
    } catch (e) {
      print('Error canceling alarm and notification: $e');
    }
  }

  Future<void> _cancelNotification(int alarmId) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(alarmId);
    } catch (e) {
      print('Error canceling alarm and notification: $e');
    }
  }

  void _showEventDetailsDialog(
      BuildContext context, Map<String, dynamic> event) {
    TextEditingController locationController = TextEditingController();
    locationController.text = event['location'] ?? 'No Location';

    TextEditingController originLocationController = TextEditingController();
    originLocationController.text =
        event['originLocation'] ?? 'No Origin Location';

    final endTime = event['endtime'] != null
        ? DateTime(
            DateTime.now().year, // Use the event’s actual year if available
            DateTime.now().month, // Use the event’s actual month if available
            DateTime.now().day, // Use the event’s actual day if available
            int.parse(event['endtime'].split(':')[0]),
            int.parse(event['endtime'].split(':')[1]),
          )
        : null;

    // // Create the AlarmSettings object based on the event details
    final alarmSettings = AlarmSettings(
      id: int.tryParse(event['id'].toString()) ?? 0,
      dateTime: endTime ?? DateTime.now(),
      assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
      notificationTitle: 'Schedule Completed',
      notificationBody: '${event['name']} completed early.',
      loopAudio: false,
      vibrate: false,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                event['name'] ?? 'No name',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => EditScheduleDialog(
                        googleId: widget.googleId,
                        scheduleId: event['id'],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    final int groupId = event['groupId'];
                    // Retrieve all schedule IDs associated with the group
                    final List<String>? scheduleIds = await ref
                        .read(scheduleProvider(widget.googleId).notifier)
                        .getScheduleIdByGroupId(groupId);
                    if (scheduleIds != null) {
                      // Stop alarms and cancel notifications for each schedule ID
                      for (String scheduleId in scheduleIds) {
                        // Generate the hashed alarm ID to match the created alarm ID
                        final int alarmIdByScheduleId =
                            scheduleId.hashCode % 0x7FFFFFFF;
                        final int alarmIdByRequest =
                            AlarmManager.generateAlarmIdFromRequest(
                          event['date'],
                          event['time'].format(context),
                          event['name'],
                        );
                        int? alarmIdEnd;
                        if (event['endtime'] != null) {
                          // Debugging: Print end time to verify
                          print("End time for event: ${event['endtime']}");

                          final endTime = TimeOfDay(
                            hour: int.parse(event['endtime']!.split(':')[0]),
                            minute: int.parse(event['endtime']!.split(':')[1]),
                          );
                          alarmIdEnd = AlarmManager.generateAlarmIdFromRequest(
                            event['date'],
                            endTime.format(context),
                            event['name'] + '_end',
                          );
                        }
                        await _cancelAlarmAndNotification(alarmIdByScheduleId);
                        await _cancelAlarmAndNotification(alarmIdByRequest);
                        print(alarmIdEnd);
                        if (alarmIdEnd != null) {
                          await _cancelNotification(alarmIdEnd);
                        } else {
                          print(
                              "Alarm ID for end time is null. Skipping cancellation.");
                        }
                      }
                    }
                    // Delete the event
                    if (event['recurrence'] == "none" ||
                        event['recurrence'] == "") {
                      Navigator.pop(context);
                      await ref
                          .read(scheduleProvider(widget.googleId).notifier)
                          .deleteThisSchedule(event['groupId']);
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            actionsAlignment: MainAxisAlignment.center,
                            title: Container(
                              padding: const EdgeInsets.only(bottom: 16),
                              decoration: const BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(
                                          color: Color.fromARGB(
                                              255, 228, 228, 228),
                                          width: 1))),
                              child: const Center(
                                  child: Text(
                                'Delete recurring event',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600),
                              )),
                            ),
                            actions: <Widget>[
                              Center(
                                child: Column(
                                  children: [
                                    TextButton(
                                      child: Text(
                                        'This event',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red[700]),
                                      ),
                                      onPressed: () async {
                                        final List<String>? scheduleIds =
                                            await ref
                                                .read(scheduleProvider(
                                                        widget.googleId)
                                                    .notifier)
                                                .getScheduleIdByGroupId(
                                                    groupId);
                                        if (scheduleIds != null) {
                                          // Stop alarms and cancel notifications for each schedule ID
                                          for (String scheduleId
                                              in scheduleIds) {
                                            // Generate the hashed alarm ID to match the created alarm ID
                                            final int alarmIdByScheduleId =
                                                scheduleId.hashCode %
                                                    0x7FFFFFFF;
                                            final int alarmIdByRequest =
                                                AlarmManager
                                                    .generateAlarmIdFromRequest(
                                              event['date'],
                                              event['time'].format(context),
                                              event['name'],
                                            );
                                            final int? alarmIdEnd = event[
                                                        'endtime'] !=
                                                    null
                                                ? AlarmManager
                                                    .generateAlarmIdFromRequest(
                                                    event['date'],
                                                    event['endtime']!
                                                        .format(context),
                                                    '${event['name']}_end',
                                                  )
                                                : null;
                                            await _cancelAlarmAndNotification(
                                                alarmIdByScheduleId);
                                            await _cancelAlarmAndNotification(
                                                alarmIdByRequest);
                                            if (alarmIdEnd != null) {
                                              await _cancelNotification(
                                                  alarmIdEnd);
                                            } else {
                                              print(
                                                  "Alarm ID for end time is null. Skipping cancellation.");
                                            }
                                          }
                                        }
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        await ref
                                            .read(scheduleProvider(
                                                    widget.googleId)
                                                .notifier)
                                            .deleteThisSchedule(
                                                event['groupId']);
                                      },
                                    ),
                                    TextButton(
                                      child: Text(
                                        'This and following events',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red[700]),
                                      ),
                                      onPressed: () async {
                                        // Retrieve schedule IDs for this and following events
                                        final List<String>?
                                            followingScheduleIds = await ref
                                                .read(scheduleProvider(
                                                        widget.googleId)
                                                    .notifier)
                                                .getScheduleByRecurrenceId(
                                                    event['recurrenceId'],
                                                    event['date']);
                                        if (followingScheduleIds != null) {
                                          for (String scheduleId
                                              in followingScheduleIds) {
                                            final int alarmIdByScheduleId =
                                                scheduleId.hashCode %
                                                    0x7FFFFFFF;
                                            final int alarmIdByRequest =
                                                AlarmManager
                                                    .generateAlarmIdFromRequest(
                                              event['date'],
                                              event['time'].format(context),
                                              event['name'],
                                            );
                                            final int? alarmIdEnd = event[
                                                        'endtime'] !=
                                                    null
                                                ? AlarmManager
                                                    .generateAlarmIdFromRequest(
                                                    event['date'],
                                                    event['endtime']!
                                                        .format(context),
                                                    '${event['name']}_end',
                                                  )
                                                : null;
                                            await _cancelAlarmAndNotification(
                                                alarmIdByScheduleId);
                                            await _cancelAlarmAndNotification(
                                                alarmIdByRequest);
                                            if (alarmIdEnd != null) {
                                              await _cancelNotification(
                                                  alarmIdEnd);
                                            } else {
                                              print(
                                                  "Alarm ID for end time is null. Skipping cancellation.");
                                            }
                                          }
                                        }
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        await ref
                                            .read(scheduleProvider(
                                                    widget.googleId)
                                                .notifier)
                                            .deleteThisAndFollowingSchedulesByRecurrenceId(
                                                event['recurrenceId'],
                                                event['date']);
                                      },
                                    ),
                                    TextButton(
                                      child: Text(
                                        'All events',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.red[700]),
                                      ),
                                      onPressed: () async {
                                        // Retrieve schedule IDs for all events in the series
                                        final List<String>? allScheduleIds =
                                            await ref
                                                .read(scheduleProvider(
                                                        widget.googleId)
                                                    .notifier)
                                                .getScheduleIdByGroupId(
                                                    event['recurrenceId']);
                                        if (allScheduleIds != null) {
                                          for (String scheduleId
                                              in allScheduleIds) {
                                            final int alarmIdByScheduleId =
                                                scheduleId.hashCode %
                                                    0x7FFFFFFF;
                                            final int alarmIdByRequest =
                                                AlarmManager
                                                    .generateAlarmIdFromRequest(
                                              event['date'],
                                              event['time'].format(context),
                                              event['name'],
                                            );
                                            final int? alarmIdEnd = event[
                                                        'endtime'] !=
                                                    null
                                                ? AlarmManager
                                                    .generateAlarmIdFromRequest(
                                                    event['date'],
                                                    event['endtime']!
                                                        .format(context),
                                                    '${event['name']}_end',
                                                  )
                                                : null;
                                            await _cancelAlarmAndNotification(
                                                alarmIdByScheduleId);
                                            await _cancelAlarmAndNotification(
                                                alarmIdByRequest);
                                            if (alarmIdEnd != null) {
                                              await _cancelNotification(
                                                  alarmIdEnd);
                                            } else {
                                              print(
                                                  "Alarm ID for end time is null. Skipping cancellation.");
                                            }
                                          }
                                        }
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                        await ref
                                            .read(scheduleProvider(
                                                    widget.googleId)
                                                .notifier)
                                            .deleteAllSchedulesByRecurrenceId(
                                                event['recurrenceId']);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${event['date']}'),
            Text(
                'Time: ${event['time'].format(context)} ${event['isHaveEndTime'] ? '- ' + event['endTime'].format(context) : ''}'),
            event['recurrence'] == '' || event['recurrence'] == 'none'
                ? SizedBox()
                : Text('Recurrence: ${event['recurrence']}'),
            event['originLocation'] == '' || event['originLocation'] == null
                ? SizedBox()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Start from?',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(event['originLocation']),
                    ],
                  ),
            event['location'] == '' || event['location'] == null
                ? SizedBox()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Where to?',
                        style: TextStyle(fontSize: 11),
                      ),
                      const SizedBox(height: 8),
                      Text(event['location']),
                    ],
                  ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      event['location'] = locationController.text;
                      event['originLocation'] = originLocationController.text;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () =>
                      _finishSchedule(context, alarmSettings, event),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Finish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRoutineLogToBackend(
      String routineId,
      String googleId,
      String date,
      String startTime,
      String endTime,
      String actualEndTime,
      int skewness) async {
    try {
      await createRoutineLog(
        routineId,
        googleId,
        date,
        startTime,
        endTime,
        actualEndTime,
        skewness,
      );
      print('Routine log sent to backend successfully');
    } catch (e) {
      print('Error sending routine log to backend: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send routine log')),
        );
      }
    }
  }

  void _finishSchedule(BuildContext dialogContext, AlarmSettings alarmSettings,
      Map<String, dynamic> event) async {
    // print(event['routineId']);
    // print(event['time']);
    // print(event['endTime']);
    if (isLoading) return; // Prevent duplicate calls

    setState(() {
      isLoading = true;
    });

    try {
      final now = TimeOfDay.now();
      final actualEndTime = now.format(context);

      int? alarmIdEnd;
      if (event['endTime'] != null) {
        final endTime = event['endTime'] as TimeOfDay;
        alarmIdEnd = AlarmManager.generateAlarmIdFromRequest(
          event['date'],
          endTime.format(context),
          '${event['name']}_end',
        );
      }

      final String scheduleId = event['id'];

      final int alarmIdByScheduleId = scheduleId.hashCode % 0x7FFFFFFF;
      final int alarmIdByRequest = AlarmManager.generateAlarmIdFromRequest(
        event['date'],
        event['time'].format(context),
        event['name'],
      );

      await _cancelAlarmAndNotification(alarmIdByRequest);
      await _cancelAlarmAndNotification(alarmIdByScheduleId);

      if (alarmIdEnd != null) {
        await _cancelNotification(alarmIdEnd);
      }

      await Alarm.stop(alarmSettings.id);
      await flutterLocalNotificationsPlugin.cancel(alarmSettings.id);
      _processedScheduleIds.remove(event['id'].toString());

      if (event['routineId'] != null && event['routineId'] != "") {
        final date = formatDate(_selectedDay);
        final startTime = event['time'].format(context);
        final endTime = event['endTime']?.format(context) ?? "";
        final scheduledEndTimeOfDay = event['endTime'] as TimeOfDay?;
        final actualMinutes = now.hour * 60 + now.minute;
        final scheduledMinutes = scheduledEndTimeOfDay != null
            ? scheduledEndTimeOfDay.hour * 60 + scheduledEndTimeOfDay.minute
            : actualMinutes;
        final skewness = actualMinutes - scheduledMinutes;
        await _sendRoutineLogToBackend(
          event['routineId'],
          widget.googleId,
          date,
          startTime,
          endTime,
          actualEndTime,
          skewness,
        );
      }

      if (mounted && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    } catch (e) {
      print("Error in Finish Schedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to finish schedule.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addEventDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => ScheduleDialog(
        googleId: widget.googleId,
        selectedDay: _selectedDay,
        onSave: (eventDetails) async {
          final taskName = eventDetails['name'];
          final dateString = eventDetails['date'];
          final startTime = eventDetails['startTime'] as TimeOfDay;
          final endTime = eventDetails['endTime'];
          final isHaveEndTime = eventDetails['isHaveEndTime'];
          final isRoutineChecked = eventDetails['isRoutineChecked'];
          final oriLocationName = eventDetails['originLocation'];
          final desLocationName = eventDetails['destinationLocation'];
          final isHaveLocation = eventDetails['isHaveLocation'];
          final recurrence = eventDetails['recurrence'] ?? '';
          final transportation = eventDetails['transportation'];
          final selectedRoutineTag = eventDetails['selectedRoutineTag'];

          final scheduledDateTime = DateTime(
            _selectedDay.year,
            _selectedDay.month,
            _selectedDay.day,
            startTime.hour,
            startTime.minute,
          );

          await _createSchedule(
            taskName,
            dateString,
            startTime.format(context),
            endTime?.format(context),
            isHaveEndTime,
            oriLocationName,
            eventDetails['originLatitude'],
            eventDetails['originLongitude'],
            desLocationName,
            eventDetails['destinationLatitude'],
            eventDetails['destinationLongitude'],
            isRoutineChecked,
            selectedRoutineTag,
            _selectedDay,
            isHaveLocation,
            recurrence,
            transportation,
          );

          setState(() {});
        },
      ),
    );
  }

  Future<SelectedLocation?> _selectLocation(BuildContext context) async {
    SelectedLocation? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocation(),
      ),
    );

    return selectedLocation;
  }

  Future<SelectedLocation?> _selectOriginLocation(BuildContext context) async {
    SelectedLocation? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectOriginLocation(),
      ),
    );

    return selectedLocation;
  }
}
