import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user/user_info.dart';
import 'package:frontend/models/routine/routine_model.dart';
import 'package:frontend/services/data/user/get_user_info.dart';
import 'package:frontend/services/data/user/edit_user_info.dart';
import 'package:frontend/services/data/routine/get_routine.dart';
import 'package:go_router/go_router.dart';

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

      final fetchedRoutines = await getAllRoutines(widget.googleId);
      print('Fetched routines: $fetchedRoutines'); // Debug log

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
          SnackBar(
            content: Text('Failed to load routines'),
            duration: const Duration(seconds: 3),
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
        Text(
          'Your Routines',
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
                        title: Text(routine.name,
                            style: TextStyle(color: colorScheme.primary)),
                        subtitle: Text('${routine.duration} mins'),
                        onTap: () => _showTaskDialog(context, routine),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showTaskDialog(BuildContext context, Routine routine) {
    // Use a Set to track multiple selected days
    Set<String> selectedDays = {DateFormat('EEEE').format(DateTime.now())};
    final colorScheme = Theme.of(context).colorScheme;

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
                          Icons.label_outline,
                          color: colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          routine.name,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 20,
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

                // Duration display
                Text(
                  '${routine.duration} mins',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 60,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const SizedBox(height: 20),

                // Selected days display
                Text(
                  selectedDays.isEmpty
                      ? 'No days selected'
                      : selectedDays.length == 1
                          ? selectedDays.first
                          : '${selectedDays.length} days selected',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 30),

                // Weekday selector (Sunday to Saturday)
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

                // Display selected days summary (optional)
                if (selectedDays.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getOrderedDayString(selectedDays),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
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
