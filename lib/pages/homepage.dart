import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/data/constants.dart';
import 'package:to_do_app/data/notification_service.dart';
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/data/notifiers.dart';
import 'package:to_do_app/pages/edit_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  int _lastTaskCount = 0;

  @override
  void initState() {
    super.initState();
    updateExpandingList();
    _animationControllers = [];
    final box = Hive.box<Task>('tasks');
    _lastTaskCount = box.length;

    generateAnimationControllers(_lastTaskCount);
  }

  void generateAnimationControllers(int newCount) {
    if (newCount > _animationControllers.length) {
      // add controllers
      for (int i = _animationControllers.length; i < newCount; i++) {
        _animationControllers.add(
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 700),
          ),
        );
      }
    } else if (newCount < _animationControllers.length) {
      // remove extra controllers
      for (int i = _animationControllers.length - 1; i >= newCount; i--) {
        _animationControllers[i].dispose();
        _animationControllers.removeAt(i);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _animationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: SizedBox(
          height: double.maxFinite,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 30,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: Text(
                        "Tasks : ",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: Hive.box<Task>('tasks').listenable(),
                      builder: (context, Box<Task> box, _) {
                        final tasks = box.values.toList();
                        sortTasks(tasks);
                        if (tasks.length != _lastTaskCount) {
                          generateAnimationControllers(tasks.length);
                          _lastTaskCount = tasks.length;
                        }
                        return tasks.isNotEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children:
                                    tasks
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          int index = entry.key;
                                          final task = entry.value;
                                          return Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: CircleAvatar(
                                                  radius: 25,
                                                  backgroundColor:
                                                      taskCategories[task
                                                              .category]!['color']
                                                          as Color,
                                                  child: Center(
                                                    child: Icon(
                                                      taskCategories[task
                                                              .category]!['icon']
                                                          as IconData,
                                                      color: Colors.white,
                                                      size: 30,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 8,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      expandingList
                                                              .value[index] =
                                                          !expandingList
                                                              .value[index];
                                                      expandingList.value[index]
                                                          ? _animationControllers[index]
                                                                .forward()
                                                          : _animationControllers[index]
                                                                .reverse();
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 15,
                                                          vertical: 15,
                                                        ),
                                                    decoration: boxDec(
                                                      color: Theme.of(
                                                        context,
                                                      ).primaryColor,
                                                      borderColor: getTaskColor(
                                                        task,
                                                      ),
                                                      width:
                                                          getTaskContainerWidth(
                                                            task,
                                                          ),
                                                    ),
                                                    margin: EdgeInsets.only(
                                                      left: 20,
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Wrap(
                                                                children: [
                                                                  Text(
                                                                    task.title,
                                                                    style: Theme.of(context)
                                                                        .textTheme
                                                                        .bodyMedium
                                                                        ?.copyWith(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Row(
                                                              children: [
                                                                Text(
                                                                  task.isDone
                                                                      ? "Completed"
                                                                      : taskhasStarted(
                                                                          task.startsAt,
                                                                        )
                                                                      ? getTimeRemaining(
                                                                          task.endsAt,
                                                                        )
                                                                      : timeisShort(
                                                                          task.startsAt,
                                                                        )[0]
                                                                      ? "Starts in ${timeisShort(task.startsAt)[1]}"
                                                                      : "Starts at \n${formatedTime(task.startsAt)}",
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                expandingList
                                                                        .value[index]
                                                                    ? Row(
                                                                        children: [
                                                                          PopupMenuButton(
                                                                            icon: Icon(
                                                                              Icons.more_vert,
                                                                            ),
                                                                            onSelected:
                                                                                (
                                                                                  value,
                                                                                ) async {
                                                                                  if (value ==
                                                                                      "edit") {
                                                                                    showModalBottomSheet(
                                                                                      context: context,
                                                                                      isScrollControlled: true,
                                                                                      shape: RoundedRectangleBorder(
                                                                                        borderRadius: BorderRadiusGeometry.vertical(
                                                                                          top: Radius.circular(
                                                                                            30,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      builder:
                                                                                          (
                                                                                            context,
                                                                                          ) {
                                                                                            return EditTaskPage(
                                                                                              task: task,
                                                                                              type: task.isDone
                                                                                                  ? editReuseList[1]
                                                                                                  : taskhasEnded(
                                                                                                      task.endsAt,
                                                                                                    )
                                                                                                  ? editReuseList[2]
                                                                                                  : editReuseList[0],
                                                                                            );
                                                                                          },
                                                                                    );
                                                                                  } else if (value ==
                                                                                      "remove") {
                                                                                    final delete = await showDialog(
                                                                                      context: context,
                                                                                      builder:
                                                                                          (
                                                                                            context,
                                                                                          ) => AlertDialog(
                                                                                            title: Text(
                                                                                              "Delete Record",
                                                                                            ),
                                                                                            content: Text(
                                                                                              "Are you sure you want to delete this. This action cannot be undone.",
                                                                                            ),
                                                                                            actions: [
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  Navigator.of(
                                                                                                    context,
                                                                                                  ).pop(
                                                                                                    false,
                                                                                                  );
                                                                                                },
                                                                                                child: Text(
                                                                                                  "Cancel",
                                                                                                  style: TextStyle(
                                                                                                    color: Colors.blue,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  Navigator.of(
                                                                                                    context,
                                                                                                  ).pop(
                                                                                                    true,
                                                                                                  );
                                                                                                },
                                                                                                child: Text(
                                                                                                  "Delete",
                                                                                                  style: TextStyle(
                                                                                                    color: Colors.red,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                    );
                                                                                    if (delete ==
                                                                                        true) {
                                                                                      setState(
                                                                                        () {
                                                                                          task.delete();
                                                                                          onTaskDeleted(
                                                                                            task,
                                                                                          );
                                                                                          ScaffoldMessenger.of(
                                                                                            context,
                                                                                          ).showSnackBar(
                                                                                            SnackBar(
                                                                                              backgroundColor: Colors.blue,
                                                                                              content: const Text(
                                                                                                "Task deleted successfully",
                                                                                                style: TextStyle(
                                                                                                  fontSize: 13,
                                                                                                  fontWeight: FontWeight.bold,
                                                                                                  color: Colors.white,
                                                                                                ),
                                                                                              ),
                                                                                              duration: const Duration(
                                                                                                seconds: 3,
                                                                                              ),
                                                                                            ),
                                                                                          );
                                                                                        },
                                                                                      );
                                                                                    }
                                                                                  } else if (value ==
                                                                                      "complete") {
                                                                                    final complete = await showDialog(
                                                                                      context: context,
                                                                                      builder:
                                                                                          (
                                                                                            context,
                                                                                          ) => AlertDialog(
                                                                                            title: Text(
                                                                                              "Comfirm Task Completion",
                                                                                            ),
                                                                                            content: Text(
                                                                                              "Kindly Comfirm Task as been successfully completed.",
                                                                                            ),
                                                                                            actions: [
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  Navigator.of(
                                                                                                    context,
                                                                                                  ).pop(
                                                                                                    false,
                                                                                                  );
                                                                                                },
                                                                                                child: Text(
                                                                                                  "Cancel",
                                                                                                  style: TextStyle(
                                                                                                    color: Colors.red,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              TextButton(
                                                                                                onPressed: () {
                                                                                                  Navigator.of(
                                                                                                    context,
                                                                                                  ).pop(
                                                                                                    true,
                                                                                                  );
                                                                                                },
                                                                                                child: Text(
                                                                                                  "Confirm",
                                                                                                  style: TextStyle(
                                                                                                    color: Colors.blue,
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            ],
                                                                                          ),
                                                                                    );
                                                                                    if (complete ==
                                                                                        true) {
                                                                                      task.isDone = true;
                                                                                      task.completedAt = DateTime.now();
                                                                                      task.save();
                                                                                      onTaskCompleted(
                                                                                        task,
                                                                                      );
                                                                                      onCheckboxTapped(
                                                                                        task,
                                                                                      );
                                                                                      ScaffoldMessenger.of(
                                                                                        // ignore: use_build_context_synchronously
                                                                                        context,
                                                                                      ).showSnackBar(
                                                                                        SnackBar(
                                                                                          backgroundColor: Colors.blue,
                                                                                          content: const Text(
                                                                                            "Task Completed!!!",
                                                                                            style: TextStyle(
                                                                                              fontSize: 13,
                                                                                              fontWeight: FontWeight.bold,
                                                                                              color: Colors.white,
                                                                                            ),
                                                                                          ),
                                                                                          duration: const Duration(
                                                                                            seconds: 3,
                                                                                          ),
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                            itemBuilder:
                                                                                (
                                                                                  context,
                                                                                ) => [
                                                                                  PopupMenuItem(
                                                                                    value: "edit",
                                                                                    child: Text(
                                                                                      task.isDone
                                                                                          ? "Reuse"
                                                                                          : taskhasEnded(
                                                                                              task.endsAt,
                                                                                            )
                                                                                          ? "Reschedule"
                                                                                          : "Edit",
                                                                                    ),
                                                                                  ),
                                                                                  PopupMenuItem(
                                                                                    value: "remove",
                                                                                    child: Text(
                                                                                      "Remove",
                                                                                    ),
                                                                                  ),
                                                                                  task.isDone ==
                                                                                          false
                                                                                      ? PopupMenuItem(
                                                                                          value: "complete",
                                                                                          child: Text(
                                                                                            "Complete",
                                                                                          ),
                                                                                        )
                                                                                      : PopupMenuItem(
                                                                                          child: Container(),
                                                                                        ),
                                                                                ],
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Container(),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        SizeTransition(
                                                          sizeFactor:
                                                              CurvedAnimation(
                                                                parent:
                                                                    _animationControllers[index],
                                                                curve: Curves
                                                                    .easeInCubic,
                                                              ),
                                                          child: SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child: Wrap(
                                                              alignment:
                                                                  WrapAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  task.description,
                                                                  style: Theme.of(context)
                                                                      .textTheme
                                                                      .bodySmall
                                                                      ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        fontSize:
                                                                            11,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        })
                                        .toList()
                                        .expand(
                                          (element) => [
                                            element,
                                            Column(
                                              children: [
                                                SizedBox(height: 20),
                                                Divider(
                                                  thickness: 1,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 20),
                                              ],
                                            ),
                                          ],
                                        )
                                        .toList()
                                      ..removeLast(),
                              )
                            : Padding(
                                padding: const EdgeInsets.all(40.0),
                                child: Center(
                                  child: Text(
                                    "No tasks yet. Click the + button to add a new task.",
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                  ),
                                ),
                              );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
