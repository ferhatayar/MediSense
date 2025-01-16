import 'package:flutter/material.dart';

class Medication {
  String name;
  String type;
  Color color;
  int durationDays;
  DateTime startDate;
  String? strength;
  List<MedicationTime> times;

  Medication({
    required this.name,
    required this.type,
    required this.color,
    required this.durationDays,
    required this.startDate,
    required this.strength,
    required this.times,
  });
}

class MedicationTime {
  DateTime time;
  int count;
  bool? used;

  MedicationTime({
    required this.time,
    required this.count,
    this.used,
  });

  @override
  String toString() {
    String timeString = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    return 'Time: $timeString, Count: $count, Used: $used';
  }
}
