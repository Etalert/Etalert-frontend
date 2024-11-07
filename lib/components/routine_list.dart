import 'dart:core';

import 'package:flutter/material.dart';
import 'package:frontend/models/routine/routine_model.dart';
import 'package:frontend/services/data/routine/edit_routine.dart';
import 'package:frontend/services/data/routine/get_routine_by_tag_id.dart';

class RoutineList extends StatefulWidget {
  final String tagId;
  const RoutineList({super.key, required this.tagId});

  @override
  State<RoutineList> createState() => _RoutineListState();
}

class _RoutineListState extends State<RoutineList> {
  List<Routine> routines = [];
  bool isLoading = true;
  bool isEditing = false;
  Map<int, Routine> updatedRoutines = {};

  Future<List<Routine>> getRoutines(String tagId) async {
    final List<Routine> data = await getRoutinesByTagId(tagId);
    setState(() {
      routines = data;
      isLoading = false;
    });
    return routines;
  }

  void updateRoutineOrder() async {
    setState(() {
      isLoading = true;
    });
    updatedRoutines.keys.forEach((routine) async {
      final updatedRoutine = updatedRoutines[routine];
      await editRoutine(updatedRoutine!.id, updatedRoutine.name,
          updatedRoutine.duration, routine);
    });
    final data = await getRoutines(widget.tagId);
    setState(() {
      routines = data;
      isLoading = false;
      isEditing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getRoutines(widget.tagId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            )),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: routines.isEmpty
                  ? const Center(
                      child: Text('No routines available'),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 16, top: 20, bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (isEditing) {
                                      updateRoutineOrder();
                                    } else {
                                      routines.map((routine) {
                                        updatedRoutines[routine.order] =
                                            routine;
                                      });
                                    }
                                    setState(() {
                                      isEditing = !isEditing;
                                    });
                                  },
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isEditing
                                            ? Icons.check_rounded
                                            : Icons.edit,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        isEditing ? 'Done' : 'Edit order',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          isEditing
                              ? SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: ReorderableListView.builder(
                                    itemCount: routines.length,
                                    itemBuilder: (context, index) {
                                      final Routine routine = routines[index];
                                      return Card(
                                        key: Key(routine.id),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ListTile(
                                            title: Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Text(
                                                routine.name,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            subtitle: Text(
                                              '${routine.duration}${routine.duration <= 1 ? ' min' : ' mins'}',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSecondary),
                                            ),
                                            trailing:
                                                const Icon(Icons.drag_handle),
                                          ),
                                        ),
                                      );
                                    },
                                    onReorder:
                                        (int oldIndex, int newIndex) async {
                                      if (newIndex > oldIndex) {
                                        newIndex--;
                                      }

                                      setState(() {
                                        final Routine movedRoutineTag =
                                            routines.removeAt(oldIndex);
                                        routines.insert(
                                            newIndex, movedRoutineTag);
                                      });

                                      updatedRoutines.clear();
                                      var i = 1;
                                      routines.map((routine) {
                                        updatedRoutines[i] = routine;
                                        i++;
                                      }).toList();
                                    },
                                  ),
                                )
                              : Column(
                                  children: routines.map((e) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: ListTile(
                                          title: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: Text(
                                              e.name,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${e.duration}${e.duration <= 1 ? ' min' : ' mins'}',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondary),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
