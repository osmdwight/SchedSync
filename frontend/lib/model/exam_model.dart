class ExamModel {
  final String examId;
  final String userId;
  final String classId;
  final String examTitle;
  final String description;

  final String examDatetime;

  final String status;

  ExamModel({
    required this.examId,
    required this.userId,
    required this.classId,
    required this.examTitle,
    required this.description,
    required this.examDatetime,
    required this.status,
  });

  /// Extract exam_date (yyyy-MM-dd)
  String get examDate {
    if (examDatetime.contains("T")) {
      return examDatetime.split("T")[0];
    }
    return examDatetime;
  }

  /// Extract deadline (full datetime)
  String get deadline => examDatetime;

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      examId: json['exam_id'] ?? '',
      userId: json['user_id'] ?? '',
      classId: json['class_id'] ?? '',
      examTitle: json['exam_title'] ?? '',
      description: json['description'] ?? '',

      examDatetime: json['exam_datetime']
          ?? json['deadline']
          ?? json['exam_date']
          ?? '',

      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exam_id': examId,
      'user_id': userId,
      'class_id': classId,
      'exam_title': examTitle,
      'description': description,
      'exam_datetime': examDatetime,
      'status': status,
    };
  }
}
