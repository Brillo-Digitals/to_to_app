import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:to_do_app/data/constants.dart';
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/pages/edit_task_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  TextEditingController searchController = TextEditingController();

  bool isGridView = false;
  String searchQuery = '';
  List<Task> taskList = [];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    isGridView = box.get('isGridView', defaultValue: false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              IconButton(
                onPressed: () {
                  setState(() {
                    isGridView = !isGridView;
                    final box = Hive.box('settings');
                    box.put('isGridView', isGridView);
                  });
                },
                icon: Icon(
                  isGridView ? Icons.view_column : Icons.view_list,
                  size: 30,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.search, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    controller: searchController,
                    cursorColor: Colors.blue,
                    cursorHeight: 12,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hint: Text(
                        "Search",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(10),
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Task>('tasks').listenable(),
                builder: (context, Box<Task> box, _) {
                  final allTasks = box.values.toList();

                  final filteredTasks = getFilteredTasks(
                    allTasks: allTasks,
                    query: searchQuery,
                  );

                  sortTasks(filteredTasks);

                  return filteredTasks.isNotEmpty
                      ? isGridView
                            ? recentGrid(
                                key: ValueKey('grid'),
                                tasks: filteredTasks,
                              )
                            : recentList(
                                key: ValueKey('list'),
                                tasks: filteredTasks,
                              )
                      : Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              "No tasks found.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                            ),
                          ),
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget recentGrid({required Key key, required List<Task> tasks}) {
    return GridView.builder(
      key: key,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.2,
        mainAxisExtent: 250,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Hero(
          tag: 'item_$index',
          flightShuttleBuilder:
              (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                return AnimatedBuilder(
                  animation: animation.drive(
                    CurveTween(curve: Curves.easeInOut),
                  ),
                  builder: (context, child) {
                    return child!;
                  },
                  child: flightDirection == HeroFlightDirection.push
                      ? fromHeroContext.widget
                      : toHeroContext.widget,
                );
              },
          child: Container(
            decoration: boxDec(
              color: Theme.of(context).primaryColor,
              borderColor: getTaskColor(task.startsAt, task.endsAt),
              width: getTaskContainerWidth(task.startsAt, task.endsAt),
            ),
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor:
                                taskCategories[task.category]!['color']
                                    as Color,
                            child: Icon(
                              taskCategories[task.category]!['icon']
                                  as IconData,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Wrap(
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    "${formatedTime(task.startsAt)} \nto ${formatedTime(task.endsAt)}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.vertical(
                                    top: Radius.circular(30),
                                  ),
                                ),
                                builder: (context) {
                                  return EditTaskPage(
                                    task: task,
                                    type: task.isDone
                                        ? editReuseList[1]
                                        : taskhasEnded(task.endsAt)
                                        ? editReuseList[2]
                                        : editReuseList[0],
                                  );
                                },
                              );
                            },
                            child: Icon(
                              task.isDone
                                  ? Icons.autorenew
                                  : taskhasEnded(task.endsAt)
                                  ? Icons.event_repeat
                                  : Icons.edit,
                              size: 20,
                            ),
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: () async {
                              final delete = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Delete Record"),
                                  content: Text(
                                    "Are you sure you want to delete this. This action cannot be undone.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (delete == true) {
                                task.delete();
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: Icon(Icons.delete, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: 100,
                        child: Text(
                          task.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget recentList({required Key key, required List<Task> tasks}) {
    return ListView.builder(
      key: key,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 110),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Hero(
          tag: 'item_$index',
          flightShuttleBuilder:
              (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                return AnimatedBuilder(
                  animation: animation.drive(
                    CurveTween(curve: Curves.easeInOut),
                  ),
                  builder: (context, child) {
                    return child!;
                  },
                  child: flightDirection == HeroFlightDirection.push
                      ? fromHeroContext.widget
                      : toHeroContext.widget,
                );
              },
          child: Container(
            decoration: boxDec(
              color: Theme.of(context).primaryColor,
              borderColor: getTaskColor(task.startsAt, task.endsAt),
              width: getTaskContainerWidth(task.startsAt, task.endsAt),
            ),
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor:
                                taskCategories[task.category]!['color']
                                    as Color,
                            child: Icon(
                              taskCategories[task.category]!['icon']
                                  as IconData,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "${formatedTime(task.startsAt)} to ${formatedTime(task.endsAt)}",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadiusGeometry.vertical(
                                    top: Radius.circular(30),
                                  ),
                                ),
                                builder: (context) {
                                  return EditTaskPage(
                                    task: task,
                                    type: task.isDone
                                        ? editReuseList[1]
                                        : taskhasEnded(task.endsAt)
                                        ? editReuseList[2]
                                        : editReuseList[0],
                                  );
                                },
                              );
                            },
                            child: Icon(
                              task.isDone
                                  ? Icons.autorenew
                                  : taskhasEnded(task.endsAt)
                                  ? Icons.event_repeat
                                  : Icons.edit,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () async {
                              final delete = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text("Delete Record"),
                                  content: Text(
                                    "Are you sure you want to delete this. This action cannot be undone.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: Text(
                                        "Delete",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (delete == true) {
                                setState(() {
                                  task.delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                });
                              }
                            },
                            child: Icon(Icons.delete, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      task.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
