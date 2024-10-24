import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/custom_schedule_dialog.dart';
import 'package:frontend/components/edit_schedule_dialog.dart';
import 'package:frontend/models/maps/location.dart';
import 'package:frontend/models/schedules/schedule_req.dart';
import 'package:frontend/models/schedules/schedules.dart';
import 'package:frontend/models/user/user_info.dart';
import 'package:frontend/providers/schedule_provider.dart';
import 'package:frontend/services/notification/notification_handler.dart';
import 'package:frontend/screens/selectlocation.dart';
import 'package:frontend/services/websocket/web_socket_service.dart';
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
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

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

  GoogleMapController? mapController;
  LatLng _center = const LatLng(13.6512574, 100.4938679);
  Set<Marker> _marker = {};
  late SelectedLocation destinationLocation;
  final NotificationsHandler _notificationsHandler = NotificationsHandler();
  late final webSocketService;

  @override
  void initState() {
    super.initState();
    _notificationsHandler.initialize();
    _setInitialLocation();
    _initializeAlarm();

    webSocketService = WebSocketService(
      onEventUpdate: (p0) {
        ref
            .watch(scheduleProvider(widget.googleId).notifier)
            .fetchAllSchedules();
      },
      // onEventUpdate: (updatedEvent) {
      //   setState(() {
      //     // Find the date for this event
      //     final date = DateFormat('dd-MM-yyyy')
      //         .parse(updatedEvent['date'])
      //         .add(const Duration(hours: 7));

      //     // If we have events for this date
      //     if (_events[date.toUtc()] != null) {
      //       // Find and update the matching event
      //       final eventIndex = _events[date.toUtc()]!
      //           .indexWhere((event) => event['id'] == updatedEvent['id']);

      //       if (eventIndex != -1) {
      //         // Update existing event
      //         _events[date.toUtc()]![eventIndex] = {
      //           ..._events[date.toUtc()]![eventIndex],
      //           ...updatedEvent,
      //         };
      //       } else {
      //         // Add new event if not found
      //         _events[date.toUtc()]!.add(updatedEvent);
      //       }

      //       // Resort events for this date
      //       _events[date.toUtc()]!.sort((a, b) {
      //         TimeOfDay timeA = a['time'];
      //         TimeOfDay timeB = b['time'];
      //         return timeA.hour.compareTo(timeB.hour) == 0
      //             ? timeA.minute.compareTo(timeB.minute)
      //             : timeA.hour.compareTo(timeB.hour);
      //       });
      //     } else {
      //       // Create new entry for this date
      //       _events[date.toUtc()] = [updatedEvent];
      //     }
      //   });
      // },
    );
    webSocketService.connectWebSocket();
  }

  @override
  void dispose() {
    webSocketService.closeWebSocket();
    super.dispose();
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

  Future<void> _initializeAlarm() async {
    await Alarm.init();
    Alarm.ringStream.stream.listen((alarmSettings) {
      _showAlarmDialog(alarmSettings);
    });
  }

  Future<void> setAlarm(
      int id, DateTime dateTime, String title, String body) async {
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: 'assets/mixkit-warning-alarm-buzzer-991.mp3',
      notificationTitle: title,
      notificationBody: body,
      loopAudio: true,
      vibrate: true,
      fadeDuration: 3.0,
      enableNotificationOnKill: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
    print('Alarm set for $dateTime with ID $id');
  }

  void _showAlarmDialog(AlarmSettings alarmSettings) {
    final dialogCompleter = Completer<void>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Timer(const Duration(minutes: 2), () {
          if (context.mounted && !dialogCompleter.isCompleted) {
            Navigator.of(context).pop();
            dialogCompleter.complete();
          }
        });
        return AlertDialog(
          title: Text(alarmSettings.notificationTitle),
          content: Text(alarmSettings.notificationBody),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            Container(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  alignment: Alignment.center,
                ),
                child: const Text(
                  'Stop Alarm',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Alarm.stop(alarmSettings.id);
                  AlarmManager.cancelAlarmTimer(alarmSettings.id);
                  if (!dialogCompleter.isCompleted) {
                    Navigator.of(context).pop();
                    dialogCompleter.complete();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
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
            'name': schedule.name,
            'date': schedule.date,
            'time': TimeOfDay(
              hour: int.parse(schedule.startTime.split(':')[0]),
              minute: int.parse(schedule.startTime.split(':')[1]),
            ),
            'endTime': TimeOfDay(
                hour: int.parse(schedule.endTime!.split(':')[0]),
                minute: int.parse(schedule.endTime!.split(':')[1])),
            'location': schedule.destinationName,
            'originLocation': schedule.originName,
            'isHaveEndTime': schedule.isHaveEndTime,
            'groupId': schedule.groupId,
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
      DateTime selectedDay,
      bool isHaveLocation) async {
    final req = ScheduleReq(
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
      recurrence: EnumRecurrence.none.value,
    );
    await ref.read(scheduleProvider(widget.googleId).notifier).addSchedule(req);
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

  void _showEventDetailsDialog(
      BuildContext context, Map<String, dynamic> event) {
    TextEditingController locationController = TextEditingController();
    locationController.text = event['location'] ?? 'No Location';

    TextEditingController originLocationController = TextEditingController();
    originLocationController.text =
        event['originLocation'] ?? 'No Origin Location';

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
                    // Edit the event
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
                  icon: const Icon(Icons.delete), // Trash bin icon
                  onPressed: () async {
                    // Delete the event
                    Navigator.pop(context);
                    await ref
                        .read(scheduleProvider(widget.googleId).notifier)
                        .deleteSchedule(event['groupId']);
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
            TextField(
              controller: originLocationController,
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                labelText: 'Start from?',
                labelStyle: TextStyle(fontSize: 14.0),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                labelText: 'Where to?',
                labelStyle: TextStyle(fontSize: 14.0),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8.0),
              ),
              maxLines: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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
        ],
      ),
    );
  }

  Future<void> _addEventDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => ScheduleDialog(
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
            _selectedDay,
            isHaveLocation,
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
