class ClassModel {
  final String classCode; // PK
  final String userId;    // SK
  final String className;
  final String timeStart;
  final String timeEnd;
  final List<String> daysOfWeek;
  final String? professor;
  final String? location;

  ClassModel({
    required this.classCode,
    required this.userId,
    required this.className,
    required this.timeStart,
    required this.timeEnd,
    required this.daysOfWeek,
    this.professor,
    this.location,
  });

  String get schedule {
    final days = daysOfWeek.join(" | ");
    return "$days • $timeStart - $timeEnd";
  }

factory ClassModel.fromJson(Map<String, dynamic> json) {
  return ClassModel(
    classCode: json['class_code'] ?? json['classCode'] ?? '',
    userId: json['user_id'] ?? json['userId'] ?? '',
    className: json['class_name'] ?? json['className'] ?? '',
    timeStart: json['time_start'] ?? json['timeStart'] ?? '',
    timeEnd: json['time_end'] ?? json['timeEnd'] ?? '',
    daysOfWeek: List<String>.from(
      json['days_of_week'] ?? json['daysOfWeek'] ?? [],
    ),
    professor: json['professor'],
    location: json['location'],
  );
}

}

