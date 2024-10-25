import 'package:frontend/services/data/routine/create_routine.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user/user_info.dart';
import 'package:frontend/models/routine/routine_model.dart';
import 'package:frontend/services/data/user/get_user_info.dart';
import 'package:frontend/services/data/user/edit_user_info.dart';
import 'package:frontend/services/data/routine/get_routine.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/data/routine/edit_routine.dart';
import 'package:frontend/services/data/routine/delete_routine.dart';

class Setting extends ConsumerStatefulWidget {
  final String googleId;
  const Setting({Key? key, required this.googleId}) : super(key: key);

  @override
  ConsumerState<Setting> createState() => _SettingState();
}

class _SettingState extends ConsumerState<Setting> {
  UserData? userData;
  List<Routine> routines = [];
  bool isLoading = true;
  bool isEditing = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
    _loadRoutines(); // Load routines
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await getUserInfo(widget.googleId);
      if (mounted) {
        setState(() {
          userData = data;
          _nameController.text = data?.name ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user data')),
        );
      }
    }
  }

  Future<void> _loadRoutines() async {
    try {
      setState(() {
        isLoading = true;
      });

      final List<Routine> fetchedRoutines =
          await getAllRoutines(widget.googleId);

      for (var routine in fetchedRoutines) {
        print(
            'Loaded Routine: ${routine.toJson()}'); // Debug log to confirm data
      }

      if (mounted) {
        setState(() {
          routines = fetchedRoutines;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadRoutines: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load routines'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _updateUserName() async {
    try {
      if (userData != null) {
        await editUser(widget.googleId, _nameController.text, userData!.image);
        setState(() {
          userData!.name = _nameController.text;
          isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update name')),
      );
    }
  }

  Future<void> _editRoutine(String routineId, Routine updatedRoutine) async {
    try {
      await editRoutine(
        routineId,
        updatedRoutine.name,
        updatedRoutine.duration,
        updatedRoutine.order,
        updatedRoutine.days,
      );

      // Reload routines to reflect the changes
      await _loadRoutines();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine updated successfully!')),
      );
    } catch (e) {
      print('Update failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update routine')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/${widget.googleId}');
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: CircleAvatar(
                      radius: 60.0,
                      backgroundImage: userData?.image != null
                          ? NetworkImage(userData!.image!)
                          : const AssetImage('assets/IMG_1274.JPG')
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 30.0),
                  _buildNameSection(theme),
                  const SizedBox(height: 32.0),
                  Expanded(child: _buildTaskSection(routines, colorScheme)),
                ],
              ),
            ),
    );
  }

  Widget _buildNameSection(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isEditing) ...[
          Padding(
            padding:
                const EdgeInsets.only(left: 35.0), // Add horizontal space here
            child: Text(
              userData?.name ?? 'Name not available',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
            color: theme.primaryColor,
          ),
        ] else ...[
          SizedBox(
            width: 200,
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check, size: 20),
            onPressed: _updateUserName,
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _nameController.text = userData?.name ?? '';
                isEditing = false;
              });
            },
            color: Colors.red,
          ),
        ],
      ],
    );
  }

  Widget _buildTaskSection(List<Routine> routines, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Routines',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              color: colorScheme.primary,
              // Inside the IconButton's onPressed callback
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (BuildContext context) {
                    final TextEditingController nameController =
                        TextEditingController();
                    final TextEditingController durationController =
                        TextEditingController();
                    Set<String> selectedDays = {}; // Store selected days

                    return StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return AlertDialog(
                          title: const Text('Add Routine'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                    labelText: 'Routine Name'),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: durationController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Duration (minutes)'),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                children: [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun'
                                ].map((day) {
                                  final bool isSelected =
                                      selectedDays.contains(day);
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
                                    backgroundColor:
                                        Colors.grey[300], // Default color
                                    selectedColor: Theme.of(context)
                                        .colorScheme
                                        .primary, // Highlighted color
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context), // Cancel button
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                if (nameController.text.isNotEmpty &&
                                    int.tryParse(durationController.text) !=
                                        null) {
                                  Navigator.pop(context, {
                                    'name': nameController.text,
                                    'duration':
                                        int.parse(durationController.text),
                                    'days': selectedDays.toList(),
                                  });
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );

                if (result != null) {
                  try {
                    await createRoutine(
                      widget.googleId,
                      result['name'],
                      result['duration'],
                      routines.length + 1,
                      result['days'], // Pass selected days
                    );

                    await _loadRoutines(); // Reload routines
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Routine added successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add routine')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: routines.isEmpty
              ? const Text('No tasks available')
              : ListView.builder(
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return Card(
                      child: ListTile(
                        title: Text(
                          routine.name,
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        subtitle: Text('${routine.duration} mins'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDayCircles(
                                routine, colorScheme), // Day circles
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () => _confirmDelete(context, routine),
                            ),
                          ],
                        ),
                        onTap: () => _showTaskDialog(context, routine),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Confirm Delete Dialog
  void _confirmDelete(BuildContext context, Routine routine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _deleteRoutine(routine.id); // Delete the routine
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

// Delete Routine and Update State
  Future<void> _deleteRoutine(String routineId) async {
    print(routineId);
    try {
      await deleteRoutine(routineId); // Call API to delete the routine
      setState(() {
        routines.removeWhere(
            (routine) => routine.id == routineId); // Remove locally
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine deleted successfully!')),
      );
    } catch (e) {
      print('Delete failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete routine')),
      );
    }
  }

// Helper to build day circles
  Widget _buildDayCircles(Routine routine, ColorScheme colorScheme) {
    const daysOfWeek = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: daysOfWeek.map((day) {
        final isSelected = routine.days.contains(day);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: CircleAvatar(
            radius: 10,
            backgroundColor: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.2),
            child: Text(
              day.substring(0, 1),
              style: TextStyle(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showTaskDialog(BuildContext context, Routine routine) {
    print('Routine passed to dialog: ${routine.toJson()}');

    // Initialize the selected days with the routine's days
    Set<String> selectedDays = Set<String>.from(routine.days);

    final colorScheme = Theme.of(context).colorScheme;

    // Controllers for editing routine name and duration
    final TextEditingController nameController =
        TextEditingController(text: routine.name);
    final TextEditingController durationController =
        TextEditingController(text: routine.duration.toString());

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top section with label and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 200,
                          child: TextField(
                            controller: nameController,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 20,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Duration input field
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 60,
                          fontWeight: FontWeight.w300,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'mins',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Selected days display
                Text(
                  selectedDays.isEmpty
                      ? 'No days selected'
                      : selectedDays.join(', '),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 30),

                // Weekday selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                      .asMap()
                      .entries
                      .map((entry) {
                    final String day =
                        _getDayFromInitial(entry.value, entry.key);
                    final bool isSelected = selectedDays.contains(day);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          // Toggle the day selection
                          if (isSelected) {
                            selectedDays.remove(day);
                          } else {
                            selectedDays.add(day);
                          }
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.primaryContainer,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 30),

                // Save button
                ElevatedButton(
                  onPressed: () {
                    final updatedRoutine = Routine(
                      id: routine.id,
                      name: nameController.text,
                      duration: int.tryParse(durationController.text) ??
                          routine.duration,
                      order: routine.order,
                      days: selectedDays.toList(),
                    );

                    _editRoutine(routine.id, updatedRoutine);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to get day order (Monday = 0, Sunday = 6)
  int _getDayOrder(String day) {
    final Map<String, int> dayOrder = {
      'Sunday': 0,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
    };
    return dayOrder[day] ?? 0;
  }

// Helper function to sort and format selected days
  String _getOrderedDayString(Set<String> selectedDays) {
    final List<String> orderedDays = selectedDays.toList()
      ..sort((a, b) => _getDayOrder(a).compareTo(_getDayOrder(b)));
    return orderedDays.join(', ');
  }

// Helper function to convert initials to full day names
  String _getDayFromInitial(String initial, int index) {
    final Map<int, String> dayMap = {
      0: 'Sunday',
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
    };
    return dayMap[index] ?? 'Monday';
  }
}
