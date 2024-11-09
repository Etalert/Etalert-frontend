import 'package:frontend/components/routine_list.dart';
import 'package:frontend/components/sidebar.dart';
import 'package:frontend/models/routine/routine_tag.dart';
import 'package:frontend/services/data/routine/create_routine_tag.dart';
import 'package:frontend/services/data/routine/get_routine_tags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/user/user_info.dart';
import 'package:frontend/models/routine/routine_model.dart';
import 'package:frontend/services/data/user/get_user_info.dart';
import 'package:frontend/services/data/user/edit_user_info.dart';

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
  List<RoutineTag> routineTags = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
    _loadRoutineTags();
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

  Future<void> _loadRoutineTags() async {
    try {
      setState(() {
        isLoading = true;
      });

      final List<RoutineTag> fetchedRoutinetags =
          await getRoutineTags(widget.googleId);

      for (var tag in fetchedRoutinetags) {
        print('Loaded Routine Tag: ${tag.name}');
      }

      if (mounted) {
        setState(() {
          routineTags = fetchedRoutinetags;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadRoutineTags: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load routine tags'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: Sidebar(googleId: widget.googleId),
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
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final TextEditingController tagNameController =
                          TextEditingController();

                      return AlertDialog(
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('Add routine tag',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: tagNameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer),
                                      borderRadius: BorderRadius.circular(8.0)),
                                  labelText: 'Name',
                                  labelStyle: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final String name = tagNameController.text;

                              await createRoutineTag(widget.googleId, name, []);

                              Navigator.of(context).pop();

                              setState(() {
                                isLoading = true;
                              });

                              _loadRoutineTags();

                              setState(() {
                                isLoading = false;
                              });
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      );
                    },
                  );
                }),
          ],
        ),
        const SizedBox(height: 16),
        routineTags.isEmpty
            ? const Center(child: Text('No routine tag available'))
            : Expanded(
                child: ListView.builder(
                  itemCount: routineTags.length,
                  itemBuilder: (context, index) {
                    final routineTag = routineTags[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) {
                              return RoutineList(
                                googleId: widget.googleId,
                                tagId: routineTag.id,
                                tagName: routineTag.name,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 0.5,
                              color: Color.fromARGB(255, 205, 205, 205),
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 28),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                routineTag.name,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color:
                                    Theme.of(context).colorScheme.onSecondary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }
}
