import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/data/constants.dart';
import 'package:to_do_app/data/notification_service.dart';
import 'package:to_do_app/models/task.dart';
import 'package:uuid/uuid.dart';

class EditTaskPage extends StatefulWidget {
  const EditTaskPage({super.key, required this.type, required this.task});
  final String type;
  final Task task;

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  // Text Controllers
  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController startingTimeController = TextEditingController();

  List categoryList = taskCategories.keys.toList();
  List priorityList = ["High", "Medium", "Low"];
  List priorityValueList = [3, 2, 1];

  List timeRuleList = ["Hours", "Days", "Weeks", "Months"];
  List<double> timeRuleListDuration = [24, 7, 20, 12];
  String scheduleTime = "Hours";
  String scheduleTimeDisplay = "Hours";
  double scheduleDuration = 1;
  double maxscheduleDuration = 24;

  String taskTime = "Hours";
  String taskTimeDisplay = "Hours";
  double taskDuration = 1;
  double maxtaskDuration = 24;

  int pickedCategory = -1;
  int pickedPriority = 1;
  bool isautoresheduled = false;

  @override
  void initState() {
    super.initState();
    updateTaskInfo();
  }

  void updateTaskInfo() {
    pickedCategory = categoryList.indexOf(widget.task.category);
    pickedPriority = priorityValueList.indexOf(widget.task.priority);
    titleController.text = widget.task.title;
    descController.text = widget.task.description;
    isautoresheduled = widget.task.autoreshedule;
    startingTimeController.text = widget.type == editReuseList[0]
        ? DateFormat('yyyy-MM-dd HH:mm').format(widget.task.startsAt)
        : '';
    int taskIndexNow = reverseTimeData(
      getTimeDiff(widget.task.startsAt, widget.task.endsAt),
    )[0];
    int taskperiodValueNow = reverseTimeData(
      getTimeDiff(widget.task.startsAt, widget.task.endsAt),
    )[1];
    int scheduleTimeIndexNow = reverseTimeData(
      getTimeDiff(widget.task.startsAt, widget.task.endsAt),
    )[0];
    int scheduleTimeperiodValueNow = reverseTimeData(
      getTimeDiff(widget.task.startsAt, widget.task.endsAt),
    )[1];
    taskTime = timeRuleList[taskIndexNow];
    taskTimeDisplay = timeRuleList[taskIndexNow];
    taskDuration = taskperiodValueNow.toDouble();

    scheduleTime = timeRuleList[scheduleTimeIndexNow];
    scheduleTimeDisplay = timeRuleList[scheduleTimeIndexNow];
    scheduleDuration = scheduleTimeperiodValueNow.toDouble();
  }

  Future<void> _selectDateTime() async {
    // 1. Pick the Date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // 2. Pick the Time
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        // 3. Combine them
        final fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // 4. Update the text field
        setState(() {
          startingTimeController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(fullDateTime);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30),
        topRight: Radius.circular(30),
      ),
      child: Container(
        width: double.infinity,
        height: 550,
        padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  "${widget.type} Task",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text("Task Category", style: kTasktextStyle),
                  ),
                  Text(":", style: kTasktextStyle),
                  Expanded(
                    flex: 10,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(categoryList.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                pickedCategory = index;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: pickedCategory == index
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.white,
                                ),
                              ),
                              child: Text(
                                categoryList[index],
                                style: TextStyle(
                                  color: pickedCategory == index
                                      ? Colors.blue
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text("Title :", style: kTasktextStyle),
                  ),
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TextField(
                        controller: titleController,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text("Description :", style: kTasktextStyle),
                  ),
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: TextField(
                        controller: descController,
                        // expands: true,
                        maxLines: 5,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text("Priority", style: kTasktextStyle),
                  ),
                  Text(":", style: kTasktextStyle),
                  Expanded(
                    flex: 10,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(priorityList.length, (index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                pickedPriority = index;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: pickedPriority == index
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.white,
                                ),
                              ),
                              child: Text(
                                priorityList[index],
                                style: TextStyle(
                                  color: pickedPriority == index
                                      ? Colors.blue
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text("Starts At : ", style: kTasktextStyle),
                  ),
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: startingTimeController,
                        readOnly: true,
                        onTap: _selectDateTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          labelText: "Select Date & Time",
                          labelStyle: kTasktextStyle,
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text("Task Period :", style: kTasktextStyle)),
                  DropdownButton(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    elevation: 2,
                    style: kTasktextStyle,
                    borderRadius: BorderRadius.circular(10),
                    value: taskTime,
                    items: List.generate(timeRuleList.length, (index) {
                      return DropdownMenuItem(
                        value: timeRuleList[index],
                        child: Text(timeRuleList[index]),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        scheduleTime = value.toString();
                        double x =
                            timeRuleListDuration[timeRuleList.indexOf(value)];
                        if (x < scheduleDuration) {
                          taskDuration = x;
                        }
                        maxtaskDuration = x;
                        taskTimeDisplay = value.toString();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              Slider.adaptive(
                max: maxtaskDuration,
                divisions: maxtaskDuration.round(),
                value: taskDuration,
                thumbColor: Colors.white,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
                onChanged: (value) {
                  setState(() {
                    taskDuration = value;
                    if (value == 1) {}
                  });
                },
              ),
              SizedBox(height: 10),
              Center(
                child: Text(
                  "Task Period : ${taskDuration.round().toString()} ${ruleGrammer(taskTimeDisplay, taskDuration.round())}",
                  style: kTasktextStyle,
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text("Auto Reschedule :", style: kTasktextStyle),
                  ),
                  Switch(
                    value: isautoresheduled,
                    activeThumbColor: Colors.blue,
                    activeTrackColor: Colors.white,
                    onChanged: (bool value) {
                      setState(() {
                        isautoresheduled = value;
                      });
                    },
                  ),
                ],
              ),
              isautoresheduled
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Reschedule Period :",
                            style: kTasktextStyle,
                          ),
                        ),
                        DropdownButton(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          elevation: 2,
                          style: kTasktextStyle,
                          borderRadius: BorderRadius.circular(10),
                          value: scheduleTime,
                          items: List.generate(timeRuleList.length, (index) {
                            return DropdownMenuItem(
                              value: timeRuleList[index],
                              child: Text(timeRuleList[index]),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              scheduleTime = value.toString();
                              double x =
                                  timeRuleListDuration[timeRuleList.indexOf(
                                    value,
                                  )];
                              if (x < scheduleDuration) {
                                scheduleDuration = x;
                              }
                              maxscheduleDuration = x;
                              scheduleTimeDisplay = value.toString();
                            });
                          },
                        ),
                      ],
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              isautoresheduled
                  ? Slider.adaptive(
                      max: maxscheduleDuration,
                      divisions: maxscheduleDuration.round(),
                      value: scheduleDuration,
                      thumbColor: Colors.white,
                      activeColor: Colors.white,
                      inactiveColor: Colors.white30,
                      onChanged: (value) {
                        setState(() {
                          scheduleDuration = value;
                          if (value == 1) {
                            // scheduleTimeDisplay =
                          }
                        });
                      },
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              isautoresheduled
                  ? Center(
                      child: Text(
                        "Reschedule Period : ${scheduleDuration.round().toString()} ${ruleGrammer(scheduleTimeDisplay, scheduleDuration.round())}",
                        style: kTasktextStyle,
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              SizedBox(
                height: 40,
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      if (pickedCategory != -1 &&
                          titleController.text.isNotEmpty &&
                          descController.text.isNotEmpty &&
                          startingTimeController.text.isNotEmpty) {
                        final taskBox = Hive.box<Task>('tasks');
                        final start = DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).parse(startingTimeController.text);
                        final int hoursToAdd = taskTime == "Hours"
                            ? taskDuration.round()
                            : 0;
                        final int daysToAdd = taskTime == "Days"
                            ? taskDuration.round()
                            : taskTime == "Weeks"
                            ? taskDuration.round() * 7
                            : taskTime == "Months"
                            ? taskDuration.round() * 30
                            : 0;
                        if (editReuseList[0] == widget.type ||
                            editReuseList[2] == widget.type) {
                          widget.task.title = titleController.text;
                          widget.task.description = descController.text;
                          widget.task.category = taskCategories.keys
                              .toList()[pickedCategory];
                          widget.task.priority =
                              priorityValueList[pickedPriority];
                          widget.task.autoreshedule = isautoresheduled;
                          widget.task.reshedulePeriod = isautoresheduled
                              ? timeinHour(taskTime, scheduleDuration)
                              : 0;
                          widget.task.startsAt = start;
                          widget.task.endsAt = start.add(
                            Duration(hours: hoursToAdd, days: daysToAdd),
                          );
                          widget.task.updatedAt = DateTime.now();
                          widget.task.save();
                          scheduleTaskNotifications(widget.task);
                        } else {
                          final uuid = Uuid();
                          String id = uuid.v4();
                          final newTask = Task(
                            id: id,
                            title: titleController.text,
                            description: descController.text,
                            category: taskCategories.keys
                                .toList()[pickedCategory],
                            priority: priorityValueList[pickedPriority],
                            autoreshedule: isautoresheduled,
                            reshedulePeriod: isautoresheduled
                                ? timeinHour(taskTime, scheduleDuration)
                                : 0,
                            startsAt: start,
                            endsAt: start.add(
                              Duration(hours: hoursToAdd, days: daysToAdd),
                            ),
                          );
                          taskBox.put(newTask.id, newTask);
                          scheduleTaskNotifications(newTask);
                        }
                        updateExpandingList();
                        SnackBar(
                          backgroundColor: Colors.blue,
                          content: Text(
                            "Task ${widget.type} Successfully!!!",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          duration: const Duration(seconds: 3),
                        );
                      } else {
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: const Text(
                            "Kindly input all the required fields",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          duration: const Duration(seconds: 3),
                        );
                      }
                    });
                  },

                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(10),
                    ),
                  ),
                  child: Text(
                    "${widget.type} Task",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String ruleGrammer(String word, int counter) {
    String result = "";
    if (counter <= 1) {
      result = word.substring(0, word.length - 1);
    } else {
      result = word;
    }
    return result;
  }
}
