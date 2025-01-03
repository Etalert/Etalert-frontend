import 'package:flutter/material.dart';
import 'package:frontend/models/maps/location.dart';
import 'package:frontend/models/routine/routine_tag.dart';
import 'package:frontend/screens/selectlocation.dart';
import 'package:frontend/screens/selectoriginlocation.dart';
import 'package:frontend/services/data/routine/get_routine_tags.dart';

class EnumRecurrence {
  final String value;
  const EnumRecurrence._(this.value);

  static const EnumRecurrence none = EnumRecurrence._('none');
  static const EnumRecurrence daily = EnumRecurrence._('daily');
  static const EnumRecurrence weekly = EnumRecurrence._('weekly');
  static const EnumRecurrence monthly = EnumRecurrence._('monthly');
  static const EnumRecurrence yearly = EnumRecurrence._('yearly');
}

class EnumTransportation {
  final String value;
  const EnumTransportation(this.value);

  static const EnumTransportation driving = EnumTransportation('driving');
  static const EnumTransportation walking = EnumTransportation('walking');
  static const EnumTransportation transit = EnumTransportation('transit');
}

class ScheduleDialog extends StatefulWidget {
  final String googleId;
  final DateTime selectedDay;
  final Function(Map<String, dynamic>) onSave;

  const ScheduleDialog({
    Key? key,
    required this.googleId,
    required this.selectedDay,
    required this.onSave,
  }) : super(key: key);

  @override
  _ScheduleDialogState createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog> {
  TextEditingController taskNameController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController endTimeController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  TextEditingController originLocationController = TextEditingController();
  bool isChecked = false;
  bool isEndTimeExpanded = false;
  bool isLocationExpanded = false;
  SelectedLocation originLocation = SelectedLocation();
  SelectedLocation destinationLocation = SelectedLocation();
  EnumRecurrence selectedRecurrence = EnumRecurrence.none;
  EnumTransportation selectedTransportation = EnumTransportation.driving;
  List<RoutineTag> routineTags = [];
  RoutineTag? selectedRoutineTag;

  @override
  void initState() {
    super.initState();
    dateController.text = formatDate(widget.selectedDay);
    getRoutineTagsByGoogleId(widget.googleId);
  }

  void getRoutineTagsByGoogleId(String googleId) async {
    List<RoutineTag> tags = await getRoutineTags(googleId);
    setState(() {
      routineTags = tags;
      print(routineTags);
    });
  }

  String formatDate(DateTime date) {
    var dateTime = date.toLocal();
    String formattedDate =
        '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    return formattedDate;
  }

  TimeOfDay formatTime(String time) {
    final times = time.split(':');
    return TimeOfDay(
        hour: int.parse(times[0]), minute: int.parse(times[1].split(' ')[0]));
  }

  Widget _buildEndTimeSection(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        border: Border.symmetric(
            horizontal: BorderSide(color: theme.colorScheme.primaryContainer)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                isEndTimeExpanded = !isEndTimeExpanded;
                if (!isEndTimeExpanded) {
                  endTimeController.clear();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_filled,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(Optional)',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isEndTimeExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isEndTimeExpanded)
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 20.0,
              ),
              child: TextField(
                controller: endTimeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  labelText: 'End Time',
                  labelStyle:
                      TextStyle(color: theme.colorScheme.primary, fontSize: 14),
                ),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    endTimeController.text = pickedTime.format(context);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context, ThemeData theme) {
    return Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.primaryContainer),
          ),
        ),
        child: Column(children: [
          InkWell(
            onTap: () {
              setState(() {
                isLocationExpanded = !isLocationExpanded;
                if (!isLocationExpanded) {
                  originLocationController.clear();
                  locationController.clear();
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 16.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(Optional)',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isLocationExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isLocationExpanded)
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 20.0,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Icon(Icons.home_filled, color: theme.colorScheme.primary),
                      // const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: originLocationController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            ),
                            labelText: 'Start from?',
                            labelStyle: TextStyle(
                                color: theme.colorScheme.primary, fontSize: 14),
                          ),
                          readOnly: true,
                          onTap: () async {
                            SelectedLocation? selectedLocation =
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SelectOriginLocation(),
                              ),
                            );
                            if (selectedLocation != null) {
                              setState(() {
                                originLocation = selectedLocation;
                                originLocationController.text =
                                    originLocation.locationName ?? "";
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Icon(Icons.location_on, color: theme.colorScheme.primary),
                      // const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primaryContainer,
                              ),
                            ),
                            labelText: 'Where to?',
                            labelStyle: TextStyle(
                                color: theme.colorScheme.primary, fontSize: 14),
                          ),
                          onTap: () async {
                            SelectedLocation? selectedLocation =
                                await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SelectLocation(),
                              ),
                            );
                            if (selectedLocation != null) {
                              setState(() {
                                locationController.text =
                                    selectedLocation.locationName ?? "";
                                destinationLocation = selectedLocation;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.directions_car,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<EnumTransportation>(
                          value: selectedTransportation,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            labelText: 'Transportation',
                            labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          items: [
                            EnumTransportation.driving,
                            EnumTransportation.walking,
                            EnumTransportation.transit,
                          ].map((EnumTransportation transportation) {
                            return DropdownMenuItem<EnumTransportation>(
                              value: transportation,
                              child: Text(transportation.value.capitalize()),
                            );
                          }).toList(),
                          onChanged: (EnumTransportation? newValue) {
                            setState(() {
                              selectedTransportation = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    OutlineInputBorder customBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: colorScheme.primaryContainer,
      ),
      borderRadius: BorderRadius.circular(8.0),
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'New Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your schedule.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: taskNameController,
                decoration: InputDecoration(
                  border: customBorder,
                  enabledBorder: customBorder,
                  focusedBorder: customBorder,
                  labelText: 'Name',
                  labelStyle:
                      TextStyle(color: colorScheme.primary, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dateController,
                      decoration: InputDecoration(
                        border: customBorder,
                        enabledBorder: customBorder,
                        focusedBorder: customBorder,
                        labelText: 'Date',
                        labelStyle:
                            TextStyle(color: colorScheme.primary, fontSize: 14),
                      ),
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: widget.selectedDay,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          dateController.text = formatDate(pickedDate);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.access_time, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: timeController,
                      decoration: InputDecoration(
                        border: customBorder,
                        enabledBorder: customBorder,
                        focusedBorder: customBorder,
                        labelText: 'Start Time',
                        labelStyle:
                            TextStyle(color: colorScheme.primary, fontSize: 14),
                      ),
                      onTap: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          timeController.text = pickedTime.format(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.repeat, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<EnumRecurrence>(
                      value: selectedRecurrence,
                      decoration: InputDecoration(
                        border: customBorder,
                        enabledBorder: customBorder,
                        focusedBorder: customBorder,
                        labelText: 'Recurrence',
                        labelStyle: TextStyle(color: colorScheme.primary),
                      ),
                      items: [
                        EnumRecurrence.none,
                        EnumRecurrence.daily,
                        EnumRecurrence.weekly,
                        EnumRecurrence.monthly,
                        EnumRecurrence.yearly,
                      ].map((EnumRecurrence recurrence) {
                        return DropdownMenuItem<EnumRecurrence>(
                          value: recurrence,
                          child: Text(recurrence.value.capitalize()),
                        );
                      }).toList(),
                      onChanged: (EnumRecurrence? newValue) {
                        setState(() {
                          selectedRecurrence = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildEndTimeSection(context, theme),
              _buildLocationSection(context, theme),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Checkbox(
                      value: isChecked,
                      onChanged: (value) {
                        setState(() {
                          isChecked = value!;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 7,
                    child: Text(
                      'Want to set your morning routines?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              isChecked
                  ? Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<RoutineTag>(
                            value: selectedRoutineTag,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              labelText: 'Routine tag',
                              labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            items: routineTags.map((RoutineTag routineTag) {
                              return DropdownMenuItem<RoutineTag>(
                                value: routineTag,
                                child: Text(routineTag.name),
                              );
                            }).toList(),
                            onChanged: (RoutineTag? newValue) {
                              setState(() {
                                selectedRoutineTag = newValue;
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  : Container(),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final taskName = taskNameController.text.isNotEmpty
                        ? taskNameController.text
                        : 'Unnamed Event';
                    final dateString = dateController.text.isNotEmpty
                        ? dateController.text
                        : 'No date';
                    final timeString = timeController.text.isNotEmpty
                        ? timeController.text
                        : '00:00';
                    final location = locationController.text.isNotEmpty
                        ? locationController.text
                        : 'No location';

                    if (taskName.isNotEmpty &&
                        dateString.isNotEmpty &&
                        timeString.isNotEmpty &&
                        location.isNotEmpty) {
                      final timeParts = timeString.split(':');
                      final time = TimeOfDay(
                        hour: int.parse(timeParts[0]),
                        minute: int.parse(timeParts[1].split(' ')[0]),
                      );

                      final eventDetails = {
                        'name': taskName,
                        'date': dateString,
                        'startTime': formatTime(timeString),
                        'isHaveEndTime': endTimeController.text.isNotEmpty,
                        'endTime': endTimeController.text.isNotEmpty
                            ? formatTime(endTimeController.text)
                            : null,
                        'isRoutineChecked': isChecked,
                        'selectedRoutineTag': selectedRoutineTag,
                        'originLocation': originLocationController.text,
                        'originLatitude':
                            originLocation.selectedLatLng?.latitude,
                        'originLongitude':
                            originLocation.selectedLatLng?.longitude,
                        'destinationLocation': locationController.text,
                        'destinationLatitude':
                            destinationLocation.selectedLatLng?.latitude,
                        'destinationLongitude':
                            destinationLocation.selectedLatLng?.longitude,
                        'isHaveLocation': locationController.text.isNotEmpty &&
                            originLocationController.text.isNotEmpty,
                        'recurrence': selectedRecurrence.value,
                        'transportation': selectedTransportation.value,
                      };

                      widget.onSave(eventDetails);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
