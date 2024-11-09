import 'dart:core';

import 'package:flutter/material.dart';
import 'package:frontend/models/routine/routine_model.dart';
import 'package:frontend/services/data/routine/create_routine.dart';
import 'package:frontend/services/data/routine/edit_routine.dart';
import 'package:frontend/services/data/routine/get_routine.dart';
import 'package:frontend/services/data/routine/get_routine_by_tag_id.dart';
import 'package:frontend/services/data/routine/update_routine_tag.dart';

class RoutineList extends StatefulWidget {
  final String googleId;
  final String tagId;
  final String tagName;
  const RoutineList(
      {super.key,
      required this.googleId,
      required this.tagId,
      required this.tagName});

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
    for (var i = 1; i <= updatedRoutines.length; i++) {
      final updatedRoutine = updatedRoutines[i];
      await editRoutine(
          updatedRoutine!.id, updatedRoutine.name, updatedRoutine.duration, i);
    }
    final data = await getRoutines(widget.tagId);
    setState(() {
      routines = data;
      isLoading = false;
      isEditing = false;
    });
  }

  void createRoutineInCurrentTag(String name, int duration, int order) async {
    await createRoutine(widget.googleId, name, duration, order);

    Navigator.of(context).pop();
    setState(() {
      isLoading = true;
    });
    List<Routine> newRoutines = await getAllRoutines(widget.googleId);
    List<String> routineId = [];

    for (var routine in routines) {
      routineId.add(routine.id);
    }

    for (var i = 0; i < newRoutines.length; i++) {
      if (newRoutines[i].name == name) {
        routineId.add(newRoutines[i].id);
        break;
      }
    }

    await updateRoutineTag(widget.tagId, widget.tagName, routineId);
    final data = await getRoutines(widget.tagId);
    setState(() {
      routines = data;
      isLoading = false;
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
        title: Text(widget.tagName,
            style: const TextStyle(
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
                  ? Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PopupMenuButton(
                                icon: Icon(Icons.more_horiz_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary),
                                onSelected: (value) {
                                  if (value == 'add routine') {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        final TextEditingController
                                            nameController =
                                            TextEditingController();
                                        final TextEditingController
                                            durationController =
                                            TextEditingController();

                                        return AlertDialog(
                                          title: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Text('Add Routine',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary)),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: nameController,
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primaryContainer),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primaryContainer),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primaryContainer),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0)),
                                                    labelText: 'Name',
                                                    labelStyle: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        fontSize: 14),
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                TextField(
                                                  controller:
                                                      durationController,
                                                  decoration: InputDecoration(
                                                    border: OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primaryContainer),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primaryContainer),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primaryContainer),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0)),
                                                    labelText:
                                                        'Duration (mins)',
                                                    labelStyle: TextStyle(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                        fontSize: 14),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
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
                                                style: TextStyle(
                                                    color: Colors.grey[600]),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final String name =
                                                    nameController.text;
                                                final int duration = int.parse(
                                                    durationController.text);
                                                final int order =
                                                    routines.length + 1;

                                                createRoutineInCurrentTag(
                                                    name, duration, order);
                                              },
                                              child: const Text('Add'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                itemBuilder: (context) {
                                  return [
                                    PopupMenuItem(
                                      value: 'add routine',
                                      child: Row(
                                        children: [
                                          Icon(Icons.add_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondary),
                                          const SizedBox(width: 5),
                                          Text('Add routine',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSecondary)),
                                        ],
                                      ),
                                    )
                                  ];
                                })
                          ],
                        ),
                        const Expanded(
                          child: Center(
                            child: Text('No routines available'),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 16, top: 16, bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                isEditing
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  isEditing = false;
                                                });
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.cancel_outlined,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            GestureDetector(
                                              onTap: () {
                                                updateRoutineOrder();
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.save_rounded,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'Save',
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
                                      )
                                    : PopupMenuButton(
                                        icon: Icon(Icons.more_horiz_rounded,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary),
                                        onSelected: (value) {
                                          if (value == 'edit order') {
                                            routines.map((routine) {
                                              updatedRoutines[routine.order] =
                                                  routine;
                                            });

                                            setState(() {
                                              isEditing = !isEditing;
                                            });
                                          } else if (value == 'add routine') {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                final TextEditingController
                                                    nameController =
                                                    TextEditingController();
                                                final TextEditingController
                                                    durationController =
                                                    TextEditingController();

                                                return AlertDialog(
                                                  title: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 10),
                                                    child: Text('Add Routine',
                                                        style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary)),
                                                  ),
                                                  content:
                                                      SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        TextField(
                                                          controller:
                                                              nameController,
                                                          decoration:
                                                              InputDecoration(
                                                            border:
                                                                OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primaryContainer),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primaryContainer),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primaryContainer),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0)),
                                                            labelText: 'Name',
                                                            labelStyle: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                fontSize: 14),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 20),
                                                        TextField(
                                                          controller:
                                                              durationController,
                                                          decoration:
                                                              InputDecoration(
                                                            border:
                                                                OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primaryContainer),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide: BorderSide(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primaryContainer),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8.0),
                                                            ),
                                                            focusedBorder: OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primaryContainer),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0)),
                                                            labelText:
                                                                'Duration (mins)',
                                                            labelStyle: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                fontSize: 14),
                                                          ),
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text(
                                                        'Cancel',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[600]),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        final String name =
                                                            nameController.text;
                                                        final int duration =
                                                            int.parse(
                                                                durationController
                                                                    .text);
                                                        final int order =
                                                            routines.length + 1;

                                                        createRoutineInCurrentTag(
                                                            name,
                                                            duration,
                                                            order);
                                                      },
                                                      child: const Text('Add'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        itemBuilder: (context) {
                                          return [
                                            PopupMenuItem(
                                              value: 'edit order',
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSecondary,
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    'Edit order',
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                                value: 'add routine',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.add_rounded,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSecondary),
                                                    const SizedBox(width: 5),
                                                    Text('Add routine',
                                                        style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSecondary)),
                                                  ],
                                                ))
                                          ];
                                        }),
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
                                    return GestureDetector(
                                      onLongPress: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            final TextEditingController
                                                nameController =
                                                TextEditingController();
                                            final TextEditingController
                                                durationController =
                                                TextEditingController();

                                            nameController.text = e.name;
                                            durationController.text =
                                                e.duration.toString();

                                            return AlertDialog(
                                              title: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: Text('Edit Routine',
                                                    style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary)),
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          nameController,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primaryContainer),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primaryContainer),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primaryContainer),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0)),
                                                        labelText: 'Name',
                                                        labelStyle: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            fontSize: 14),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    TextField(
                                                      controller:
                                                          durationController,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primaryContainer),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primaryContainer),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primaryContainer),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8.0)),
                                                        labelText:
                                                            'Duration (mins)',
                                                        labelStyle: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            fontSize: 14),
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
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
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    final String name =
                                                        nameController.text;
                                                    final int duration =
                                                        int.parse(
                                                            durationController
                                                                .text);

                                                    setState(() {
                                                      isLoading = true;
                                                    });
                                                    Navigator.of(context).pop();

                                                    await editRoutine(
                                                        e.id,
                                                        name,
                                                        duration,
                                                        e.order);

                                                    final data =
                                                        await getRoutines(
                                                            widget.tagId);

                                                    setState(() {
                                                      routines = data;
                                                      isLoading = false;
                                                    });
                                                  },
                                                  child: const Text('Save'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Card(
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
