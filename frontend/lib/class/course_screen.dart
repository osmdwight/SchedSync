import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedsync_app/class/edit_class.dart';
import 'package:schedsync_app/home/edit_submissions.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/model/exam_model.dart';
import 'package:schedsync_app/model/submission_model.dart';
import 'package:schedsync_app/service/class_service.dart';
import 'package:schedsync_app/service/exam_service.dart';
import 'package:schedsync_app/home/edit_exam.dart';
import 'package:schedsync_app/service/submission_service.dart';

class CourseScreen extends StatefulWidget {
  final ClassModel classItem;
  final BaseAppUser currentUser; 

  const CourseScreen({
    super.key,
    required this.classItem,
    required this.currentUser, 
  });

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  List<ExamModel> exams = [];
  final List<SubmissionModel> Submissions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadExams();
    loadSubmissions();
  }

  Future<void> loadSubmissions() async {
    try {
      final service = SubmissionService();

      // Get ALL submissions for logged-in user
      final allSubs = await service.getUserSubmissions(
        widget.currentUser.userId!,
      );

      // Filter only submissions that belong to this class
      final filtered = allSubs
          .where(
            (s) =>
                s.classId.toString() ==
                widget.classItem.classCode.toString().split(" ").first,
          )
          .toList();

      setState(() {
        Submissions.clear();
        Submissions.addAll(filtered);
      });
    } catch (e) {
      print("ERROR loading submissions: $e");
    }
  }

  // FETCH ALL EXAMS
  Future<void> loadExams() async {
    try {
      final service = ExamService();

      // Load ALL exams for the logged-in user
      final data = await service.getExams(widget.currentUser.userId, context);

      // Convert to model list
      final allExams = data.map((json) => ExamModel.fromJson(json)).toList();

      // Filter only exams for this class
      final onlyThisClass = allExams
          .where((e) => e.classId == widget.classItem.classCode)
          .toList();

      setState(() {
        exams = onlyThisClass;
        loading = false;
      });
    } catch (e) {
      print("ERROR loading exams: $e");
      setState(() => loading = false);
    }
  }

  // FORMAT DATETIME
  String formatDateTime(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return "${DateFormat('MMM dd, yyyy').format(dt)} — ${DateFormat('h:mm a').format(dt)}";
    } catch (_) {
      return raw;
    }
  }

  // UI START
  @override
  Widget build(BuildContext context) {
    final c = widget.classItem;
     final textColor = Theme.of(context).colorScheme.onBackground;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Classes"),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Class"),
                  content: const Text(
                    "Are you sure you want to delete this class?",
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: const Text("Delete"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              final success = await ClassService().deleteClass(
                userId: widget.currentUser.userId!,
                classCode: widget.classItem.classCode,
              );

              if (success) {
                Navigator.pop(context, true); // refresh parent screen
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to delete class")),
                );
              }
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CLASS HEADER CARD
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.className,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge!
                                        .copyWith(color: textColor),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${c.timeStart} - ${c.timeEnd}",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    c.daysOfWeek.join(" | "),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == "edit") {
                                    final updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => EditClassScreen(
                                          classItem: widget.classItem,
                                          currentUser: widget.currentUser,
                                        ),
                                      ),
                                    );

                                    if (updated == true) {
                                      setState(() {}); // refresh the screen
                                    }
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: "edit",
                                    child: Text("Edit"),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          //Professor
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Color.fromARGB(255, 6, 139, 103),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.professor ?? "",
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 6, 139, 103),
                                  fontSize: 18,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // COURSE CODE
                  const Text(
                    "COURSE CODE",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    c.classCode,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: textColor,
                    ),
                  ),
                  const Divider(height: 28),

                  // LOCATION
                  const Text(
                    "LOCATION",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.location ?? "",
                   style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: textColor,
                    ),
                  ),
                  const Divider(height: 30),

                  // EXAMS LIST
                  const Text(
                    "EXAMS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  if (exams.isEmpty)
                    const Text(
                      "No exams yet.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...exams.map((e) {
                      return ListTile(
                        leading: const Icon(Icons.calendar_month),

                        title: Text(e.examTitle),
                        subtitle: Text(formatDateTime(e.examDatetime)),

                        // STATUS + POPUP MENU
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // STATUS BADGE
                            Text(
                              e.status.toUpperCase(),
                              style: TextStyle(
                                color: e.status.toLowerCase() == "completed"
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // ⋯ MENU
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == "edit") {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => EditExamPage(
                                        exam: e,
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );

                                  if (updated == true) {
                                    await Future.delayed(
                                      const Duration(milliseconds: 600),
                                    );
                                    loadExams();
                                  }
                                }

                                if (value == "delete") {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Exam"),
                                      content: const Text(
                                        "Are you sure you want to delete this exam?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final success = await ExamService()
                                        .deleteExam(
                                          examId: e.examId!,
                                          userId: widget.currentUser.userId!,
                                        );

                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Exam deleted successfully!",
                                          ),
                                        ),
                                      );
                                      await Future.delayed(
                                        const Duration(milliseconds: 500),
                                      );
                                      loadExams();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Failed to delete exam.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "edit",
                                  child: Text("Edit"),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              icon: const Icon(Icons.more_horiz),
                            ),
                          ],
                        ),
                      );
                    }),

                  // SUBMISSIONS
                  const Text(
                    "SUBMISSIONS",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  if (Submissions.isEmpty)
                    const Text(
                      "No submissions yet.",
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...Submissions.map(
                      (s) => ListTile(
                        leading: const Icon(Icons.assignment),

                        title: Text(s.title),
                        subtitle: Text("${s.submissionDate}  •  ${s.deadline}"),

                        //  Status + PopupMenu row
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // STATUS BADGE
                            Text(
                              s.status.toUpperCase(),
                              style: TextStyle(
                                color: s.status.toLowerCase() == "completed"
                                    ? Colors.green
                                    : Colors.orange, // pending = orange/yellow
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // ⋯ MENU
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == "edit") {
                                  final updated = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (ctx) => EditSubmissionPage(
                                        submission: s,
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );

                                  if (updated == true) {
                                    loadSubmissions();
                                  }
                                }

                                if (value == "delete") {
                                  final confirm = await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete Submission"),
                                      content: const Text(
                                        "Are you sure you want to delete this submission?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    final success = await SubmissionService()
                                        .deleteSubmission(
                                          taskId: s.taskId,
                                          userId: widget.currentUser.userId!,
                                        );

                                    if (success) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Submission deleted successfully!",
                                          ),
                                        ),
                                      );
                                      await Future.delayed(
                                        const Duration(milliseconds: 300),
                                      );
                                      loadSubmissions();
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Failed to delete submission.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: "edit",
                                  child: Text("Edit"),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              icon: const Icon(Icons.more_horiz),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
