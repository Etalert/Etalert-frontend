import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/tasklist_provider.dart';
import 'package:frontend/services/data/routine/create_routine.dart';
import 'package:go_router/go_router.dart';

class Preference extends ConsumerWidget {
  final String googleId;

  Preference({Key? key, required this.googleId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tasks = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        title: _buildTitle(theme),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: _buildBody(context, ref, tasks, theme),
        ),
      ),
      bottomNavigationBar:
          _buildBottomBar(context, googleId, tasks, colorScheme),
    );
  }

  // Build the page title
  Widget _buildTitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Self-prepared routines',
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          children: [
            Text(
              'Add your self-prepare routine in order from first to last',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  // Build the main body section
  Widget _buildBody(
      BuildContext context, WidgetRef ref, List tasks, ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks',
              style: TextStyle(
                color: theme.primaryColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.push(
                    '/addroutine/$googleId?returnPath=/preference/$googleId');
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: tasks.map((task) {
                return _buildTaskCard(task, theme);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Build each task card
  Widget _buildTaskCard(task, ThemeData theme) {
    return Column(
      children: [
        Card(
          elevation: 2.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Text(
                                task.duration.toString(),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                int.parse(task.duration) <= 1 ? 'min' : 'mins',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repeated Day:',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.days.join(', '),
                                  style: TextStyle(color: Colors.grey[600]),
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Build the bottom bar with the 'Finish' button
  Widget _buildBottomBar(BuildContext context, String googleId, List tasks,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 35, left: 16, right: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        onPressed: () async {
          try {
            for (int i = 0; i < tasks.length; i++) {
              int duration = int.parse(tasks[i].duration);
              await createRoutine(
                googleId,
                tasks[i].name,
                duration,
                i + 1,
              );
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Routines created successfully!')),
            );

            context.go('/$googleId');
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to create routines')),
            );
          }
        },
        child: const Text(
          'Finish',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
