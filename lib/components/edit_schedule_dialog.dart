import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/schedule_provider.dart';
import 'package:frontend/services/data/schedules/get_schedule_by_id.dart';

class EditScheduleDialog extends ConsumerStatefulWidget {
  final String scheduleId;
  final String googleId;

  const EditScheduleDialog({
    Key? key,
    required this.scheduleId,
    required this.googleId,
  }) : super(key: key);

  @override
  ConsumerState<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends ConsumerState<EditScheduleDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    try {
      final schedule = await getScheduleById(widget.scheduleId);
      setState(() {
        nameController.text = schedule.name;
        dateController.text = schedule.date;
        timeController.text = schedule.startTime;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load schedule data';
        isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  DateTime _parseDate(String date) {
    final parts = date.split('-');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  String _calculateEndTime(String startTime) {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final endDateTime =
        DateTime(2024, 1, 1, hour, minute).add(const Duration(hours: 1));
    return '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleSave() async {
    try {
      final endTime = _calculateEndTime(timeController.text);

      await ref.read(scheduleProvider(widget.googleId).notifier).editSchedule(
            widget.scheduleId,
            nameController.text,
            dateController.text,
            timeController.text,
            endTime,
            true, // isHaveEndTime is always true
          );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update schedule: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Watch the schedule state to handle loading and error states
    final scheduleState = ref.watch(scheduleProvider(widget.googleId));

    return scheduleState.when(
      loading: () => const AlertDialog(
        content: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => AlertDialog(
        title: const Text('Error'),
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
      data: (_) {
        if (isLoading) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (errorMessage != null) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        }

        final customBorder = OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.primaryContainer,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        );

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Schedule',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: customBorder,
                    enabledBorder: customBorder,
                    focusedBorder: customBorder,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: customBorder,
                    enabledBorder: customBorder,
                    focusedBorder: customBorder,
                    prefixIcon:
                        Icon(Icons.calendar_today, color: colorScheme.primary),
                  ),
                  onTap: () async {
                    final date = _parseDate(dateController.text);
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null) {
                      setState(() {
                        dateController.text = _formatDate(picked);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Time',
                    border: customBorder,
                    enabledBorder: customBorder,
                    focusedBorder: customBorder,
                    prefixIcon:
                        Icon(Icons.access_time, color: colorScheme.primary),
                  ),
                  onTap: () async {
                    final parts = timeController.text.split(':');
                    final currentTime = TimeOfDay(
                      hour: int.parse(parts[0]),
                      minute: int.parse(parts[1]),
                    );

                    final picked = await showTimePicker(
                      context: context,
                      initialTime: currentTime,
                    );

                    if (picked != null) {
                      setState(() {
                        timeController.text =
                            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: _handleSave,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        );
      },
    );
  }
}
