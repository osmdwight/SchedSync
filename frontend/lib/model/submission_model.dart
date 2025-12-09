class SubmissionModel {
  final String taskId;
  final String userId;
  final String title;
  final String description;
  final String submissionDate;
  final String deadline;
  final String status;
  final String classId;

  SubmissionModel({
    required this.taskId,
    required this.userId,
    required this.title,
    required this.description,
    required this.submissionDate,
    required this.deadline,
    required this.status,
    required this.classId,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      taskId: json['task_id'],
      userId: json['user_id'],
      title: json['Title'] ?? "", 
      description: json['description'] ?? "",
      submissionDate: json['submission_date'],
      deadline: json['deadline'],
      status: json['status'],
      classId: json['class_id'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "task_id": taskId,
      "user_id": userId,
      "Title": title, 
      "description": description,
      "submission_date": submissionDate,
      "deadline": deadline,
      "status": status,
      "class_id": classId.split(" ").first, 
    };
  }
}
