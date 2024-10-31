import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/tasklist_provider.dart';
import 'package:go_router/go_router.dart';

class AddRoutine extends ConsumerStatefulWidget {
  final String googleId;
  final String returnPath;

  const AddRoutine(
      {Key? key,
      required this.googleId,
      required this.returnPath,
      required TaskListNotifier taskListNotifier})
      : super(key: key);

  @override
  ConsumerState<AddRoutine> createState() => _AddRoutineState();
}

class _AddRoutineState extends ConsumerState<AddRoutine> {
  final TextEditingController taskNameController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  Set<String> selectedDays = {};

  @override
  Widget build(BuildContext context) {
    final ref = ProviderScope.containerOf(context);
    final taskListNotifier = ref.read(taskListProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Add Routine',
          textAlign: TextAlign.start,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: taskNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary)),
                labelText: 'Task name',
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: durationController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a duration';
                }
                return null;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary)),
                labelText: 'Duration (minutes)',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Repeated day:'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday'
              ].map((day) {
                final bool isSelected = selectedDays.contains(day);
                return FilterChip(
                  label: Text(day),
                  selected: isSelected,
                  onSelected: (bool value) {
                    setState(() {
                      if (value) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[300], // Default color
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary, // Highlighted color
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        final taskName = taskNameController.text;
                        final duration = durationController.text;
                        if (taskName.isNotEmpty) {
                          final task = Task(
                              name: taskName,
                              duration: duration,
                              days: selectedDays.toList());
                          taskListNotifier.addTask(task);
                          Navigator.of(context).pop();
                        } else {
                          // Show error message
                        }
                      },
                      child: const Text("Create"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
