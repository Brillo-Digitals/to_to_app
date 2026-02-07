import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String category;

  @HiveField(4)
  int priority;

  @HiveField(5)
  bool autoreshedule;

  @HiveField(6)
  bool isDone;

  @HiveField(7)
  int reshedulePeriod;

  @HiveField(8)
  DateTime startsAt;

  @HiveField(9)
  DateTime endsAt;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  @HiveField(12)
  DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.autoreshedule,
    required this.reshedulePeriod,
    this.isDone = false,
    required this.startsAt,
    required this.endsAt,
    DateTime? createdAt,
    DateTime? completedAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
