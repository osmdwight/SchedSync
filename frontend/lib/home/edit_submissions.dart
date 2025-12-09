import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/model/submission_model.dart';
import 'package:schedsync_app/service/class_service.dart';
import 'package:schedsync_app/service/submission_service.dart';

class EditSubmissionPage extends StatefulWidget {
  final SubmissionModel submission;
  final BaseAppUser currentUser;

  const EditSubmissionPage({
    super.key,
    required this.submission,
    required this.currentUser,
  });

  @override
  State<EditSubmissionPage> createState() => _EditSubmissionPageState();
}

class _EditSubmissionPageState extends State<EditSubmissionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  List<ClassModel> userClasses = [];
  String? selectedClassCode;

  late DateTime selectedDate;
  late TimeOfDay selectedDeadlineTime;

  String status = "pending";

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.submission.title);
    descriptionController =
        TextEditingController(text: widget.submission.description);

    selectedClassCode = widget.submission.classId.toString();

    selectedDate =
        DateTime.tryParse(widget.submission.submissionDate) ?? DateTime.now();

    final dt = DateTime.tryParse("2000-01-01 ${widget.submission.deadline}") ??
        DateTime.now();
    selectedDeadlineTime = TimeOfDay.fromDateTime(dt);

    status = widget.submission.status.toLowerCase();

    loadClasses();
  }

  Future<void> loadClasses() async {
    final classes =
        await ClassService.getUserClasses(widget.currentUser.userId);
    setState(() => userClasses = classes);
  }

  Future<void> pickSubmissionDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // Future<void> pickDeadlineTime() async {
  //   final picked = await showTimePicker(
  //     context: context,
  //     initialTime: selectedDeadlineTime,
  //   );
  //   if (picked != null) {
  //     setState(() => selectedDeadlineTime = picked);
  //   }
  // }

  // SAVE CHANGES
  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> updateBody = {};

    // TITLE
    if (titleController.text.trim() != widget.submission.title) {
      updateBody["Title"] = titleController.text.trim();
    }

    // DESCRIPTION
    if (descriptionController.text.trim() != widget.submission.description) {
      updateBody["description"] = descriptionController.text.trim();
    }

    // CLASS
    if (selectedClassCode != widget.submission.classId) {
      updateBody["class_id"] = selectedClassCode!;
    }

    // SUBMISSION DATE
    final newSubmissionDate = DateFormat("yyyy-MM-dd").format(selectedDate);
    if (newSubmissionDate != widget.submission.submissionDate) {
      updateBody["submission_date"] = newSubmissionDate;
    }

    // DEADLINE (HH:MM only)
    // final newDeadline =
    //     "${selectedDeadlineTime.hour.toString().padLeft(2, '0')}:${selectedDeadlineTime.minute.toString().padLeft(2, '0')}";

    // if (newDeadline != widget.submission.deadline) {
    //   updateBody["deadline"] = newDeadline;
    // }

    // STATUS
    final normalizedStatus = status.toLowerCase();
    if (normalizedStatus != widget.submission.status.toLowerCase()) {
      updateBody["status"] = normalizedStatus;
    }

    if (updateBody.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nothing to update")),
      );
      return;
    }

    final success = await SubmissionService().updateSubmission(
      userId: widget.currentUser.userId!,
      taskId: widget.submission.taskId,
      updates: updateBody,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subDateFormatted = DateFormat("MMMM dd, yyyy").format(selectedDate);
    final timeFormatted = selectedDeadlineTime.format(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Submission")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Submission Title"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: selectedClassCode,
                decoration: const InputDecoration(labelText: "Select Class"),
                items: userClasses.map((c) {
                  return DropdownMenuItem(
                    value: c.classCode.toString(),
                    child: Text("${c.classCode} • ${c.className}"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedClassCode = v),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // DATE
              Text("Submission Date",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: pickSubmissionDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(subDateFormatted,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 20),

              // // TIME
              // Text("Deadline Time",
              //     style: Theme.of(context)
              //         .textTheme
              //         .titleMedium!
              //         .copyWith(fontWeight: FontWeight.bold)),
              // const SizedBox(height: 8),

              // GestureDetector(
              //   onTap: pickDeadlineTime,
              //   child: Container(
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              //     decoration: BoxDecoration(
              //       color: Colors.grey.shade200,
              //       borderRadius: BorderRadius.circular(12),
              //     ),
              //     child: Text(
              //       timeFormatted,
              //       style: const TextStyle(
              //           fontSize: 16, fontWeight: FontWeight.w600),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 20),

              // STATUS
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "Status"),
                items: const [
                  DropdownMenuItem(
                      value: "pending", child: Text("PENDING")),
                  DropdownMenuItem(
                      value: "completed", child: Text("COMPLETED")),
                ],
                onChanged: (v) => setState(() => status = v!),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: saveChanges,
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
