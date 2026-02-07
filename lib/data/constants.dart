import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/data/notifiers.dart';
import 'package:to_do_app/models/task.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color.fromARGB(115, 42, 42, 42),
  scaffoldBackgroundColor: const Color.fromARGB(221, 28, 28, 28),

  iconTheme: const IconThemeData(color: Colors.white70),
  textTheme: TextTheme(
    bodyLarge: TextStyle(
      color: const Color.fromARGB(255, 235, 234, 234),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(color: Colors.white70, fontSize: 10),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  scaffoldBackgroundColor: const Color.fromARGB(255, 239, 238, 238),

  iconTheme: const IconThemeData(color: Color.fromARGB(221, 36, 36, 36)),

  textTheme: TextTheme(
    bodyLarge: TextStyle(
      color: const Color.fromARGB(255, 22, 22, 22),
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    bodySmall: TextStyle(color: Color.fromARGB(221, 36, 36, 36), fontSize: 10),
    bodyMedium: TextStyle(
      color: const Color.fromARGB(221, 36, 36, 36),
      fontSize: 14,
    ),
  ),

  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    elevation: 0,
    // shape: Border.all(style: BorderStyle.solid),
  ),
);

BoxDecoration boxDec({
  required Color color,
  required Color borderColor,
  double width = 1,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(width: width, color: borderColor),
  );
}

TextStyle kTasktextStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);

List editReuseList = ["Edit", "Reuse", "Reschedule"];

void updateExpandingList() {
  final taskBox = Hive.box<Task>('tasks');
  expandingList.value = List.generate(taskBox.length, (_) => false);
}

void addExpandingList() {
  final taskBox = Hive.box<Task>('tasks');
  expandingList.value = List.generate(taskBox.length + 1, (_) => false);
}

int timeinHour(String taskTime, double taskDuration) {
  final int hours = taskTime == "Hours"
      ? taskDuration.round()
      : taskTime == "Days"
      ? taskDuration.round() * 24
      : taskTime == "Weeks"
      ? taskDuration.round() * 24 * 7
      : taskTime == "Months"
      ? taskDuration.round() * 24 * 30
      : 0;
  return hours;
}

List reverseTimeData(int time) {
  final int days = time ~/ 24;
  final int weeks = days ~/ 24;
  final int months = weeks ~/ 24;

  List finalList = [];
  if (time <= timeRuleListDuration[0]) {
    finalList = [0, time];
  } else if (days <= timeRuleListDuration[1]) {
    finalList = [1, days];
  } else if (weeks <= timeRuleListDuration[2]) {
    finalList = [2, weeks];
  } else {
    finalList = [3, months];
  }

  return finalList;
}

List timeisShort(DateTime time) {
  DateTime now = DateTime.now();
  Duration diff = time.difference(now);
  bool isShort = (diff.inHours).round() < 48;
  int remainingTime = 0;
  String remainingTimeString;
  if (diff.inMinutes <= 120) {
    remainingTime = (diff.inMinutes).round();
    remainingTimeString = remainingTime > 1
        ? "$remainingTime Mins"
        : "$remainingTime Min";
  } else {
    remainingTime = (diff.inHours).round();
    remainingTimeString = "$remainingTime Hrs";
  }
  return [isShort, remainingTimeString];
}

int getTimeDiff(DateTime timeA, DateTime timeB) {
  Duration diff = timeB.difference(timeA);
  return (diff.inHours).round();
}

bool taskhasStarted(DateTime startingDate) {
  DateTime now = DateTime.now();
  return startingDate.isBefore(now);
}

bool taskhasEnded(DateTime endingDate) {
  DateTime now = DateTime.now();
  return endingDate.isBefore(now);
}

String formatedTime(DateTime date) {
  String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
  return formattedDate;
}

Color getTaskColor(DateTime sdate, DateTime edate) {
  DateTime start = sdate;
  DateTime end = edate;
  DateTime now = DateTime.now();

  if (now.isAfter(end)) {
    return Colors.red;
  }

  if (now.isAfter(start)) {
    return Colors.green;
  }

  return Colors.grey;
}

double getTaskContainerWidth(DateTime sdate, DateTime edate) {
  if (taskhasStarted(sdate)) {
    return 3.0;
  }
  return 1.0;
}

String getTimeRemaining(DateTime targetDate) {
  DateTime now = DateTime.now();

  Duration difference = targetDate.difference(now);
  if (difference.isNegative) {
    int m = difference.inMinutes * -1;
    int h = difference.inHours * -1;
    int d = difference.inDays * -1;
    if (m < 120) {
      return "Task OverDue\n by $m minutes";
    }

    if (h < 48) {
      return "Task OverDue\n by $h hours";
    }

    if (d < 7) {
      return "Task OverDue\n by $d days";
    }

    if (d < 28) {
      int weeks = (d / 7).floor();
      return "Task OverDue\n by $weeks ${weeks == 1 ? 'week' : 'weeks'}";
    }

    if (d < 365) {
      int months = (d / 30).floor();
      return "Task OverDue\n by$months ${months == 1 ? 'month' : 'months'}";
    }

    int years = (d / 365).floor();
    return "Task OverDue\n by$years ${years == 1 ? 'year' : 'years'}";
  }

  int minutes = difference.inMinutes;
  int hours = difference.inHours;
  int days = difference.inDays;

  if (minutes < 120) {
    return "$minutes minutes \nremaining";
  }

  if (hours < 48) {
    return "$hours hours \nremaining";
  }

  if (days < 7) {
    return "$days days \nremaining";
  }

  if (days < 28) {
    int weeks = (days / 7).floor();
    return "$weeks ${weeks == 1 ? 'week' : 'weeks'} \nremaining";
  }

  if (days < 365) {
    int months = (days / 30).floor();
    return "$months ${months == 1 ? 'month' : 'months'} \nremaining";
  }

  int years = (days / 365).floor();
  return "$years ${years == 1 ? 'year' : 'years'} \nremaining";
}

List<double> timeRuleListDuration = [48, 28, 20, 15];

Color fillColorOne = Color.fromARGB(255, 218, 218, 218);

final Map<String, Map<String, dynamic>> taskCategories = {
  "Work": {"color": Colors.blue, "icon": Icons.work_outline},
  "Personal": {"color": Colors.teal, "icon": Icons.person_outline},
  "Study": {"color": Colors.indigo, "icon": Icons.school_outlined},
  "Health": {"color": Colors.green, "icon": Icons.local_hospital_outlined},
  "Fitness": {"color": Colors.blueGrey, "icon": Icons.fitness_center_outlined},
  "Finance": {
    "color": Colors.green.shade900,
    "icon": Icons.account_balance_wallet_outlined,
  },
  "Home & Chores": {"color": Colors.brown, "icon": Icons.home_outlined},
  "Social & Events": {"color": Colors.deepPurple, "icon": Icons.event_outlined},
  "Others": {"color": Colors.grey.shade400, "icon": Icons.more_horiz},
  "Critical": {"color": Colors.red, "icon": Icons.warning_amber_outlined},
};
// Handle Sorting

int timeFactor(Task task) {
  final now = DateTime.now();
  final diff = task.endsAt.difference(now);

  if (diff.isNegative) return 3; // overdue
  if (diff.inHours <= 24) return 2; // due today
  if (diff.inHours <= 48) return 1; // due soon
  return 0;
}

int taskWeight(Task task) {
  return task.priority + timeFactor(task);
}

void sortTasks(List<Task> tasks) {
  tasks.sort((a, b) {
    // 1️⃣ Incomplete tasks first
    if (a.isDone != b.isDone) {
      return a.isDone ? 1 : -1;
    }

    // 2️⃣ BOTH INCOMPLETE → use urgency ranking
    if (!a.isDone && !b.isDone) {
      // Weight (desc)
      final weightDiff = taskWeight(b) - taskWeight(a);
      if (weightDiff != 0) return weightDiff;

      // Earliest deadline
      final deadlineDiff = a.endsAt.compareTo(b.endsAt);
      if (deadlineDiff != 0) return deadlineDiff;

      // Oldest created first
      return a.createdAt.compareTo(b.createdAt);
    }

    // 3️⃣ BOTH COMPLETED → sort by completion date
    final aCompleted = a.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bCompleted = b.completedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    // Most recently completed first
    return bCompleted.compareTo(aCompleted);
  });
}

// Handle search!!!!!!!!!!

bool matchesQuery(Task task, String query) {
  if (query.isEmpty) return true;

  final q = norm(query);

  return norm(task.title).contains(q) ||
      norm(task.description).contains(q) ||
      norm(task.category).contains(q);
}

String norm(String text) => text.toLowerCase().trim();
List<Task> getFilteredTasks({
  required List<Task> allTasks,
  required String query,
}) {
  final filtered = allTasks.where((task) => matchesQuery(task, query)).toList();

  sortTasks(filtered);

  return filtered;
}
