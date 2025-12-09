import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/model/exam_model.dart';
import 'package:schedsync_app/service/class_service.dart';
import 'package:schedsync_app/service/exam_service.dart';

class EditExamPage extends StatefulWidget {
  final ExamModel exam;
  final BaseAppUser currentUser;

  const EditExamPage({
    super.key,
    required this.exam,
    required this.currentUser,
  });

  @override
  State<EditExamPage> createState() => _EditExamPageState();
}

class _EditExamPageState extends State<EditExamPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  List<ClassModel> userClasses = [];
  String? selectedClassCode;

  late DateTime selectedDateTime;
  String status = "pending";

  @override
  void initState() {
    super.initState();

    // NEW: Exam title
    titleController = TextEditingController(text: widget.exam.examTitle);

    descriptionController = TextEditingController(text: widget.exam.description);

    selectedClassCode = widget.exam.classId;

    selectedDateTime =
        DateTime.tryParse(widget.exam.examDatetime) ?? DateTime.now();

    status = widget.exam.status;

    loadClasses();
  }

  Future<void> loadClasses() async {
    final classes = await ClassService.getUserClasses(widget.currentUser.userId);
    setState(() => userClasses = classes);
  }
Future<void> pickDate() async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: selectedDateTime,
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );
  if (pickedDate == null) return;

  setState(() {
    selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
    );
  });
}

 

  Future<void> saveChanges() async {
  if (!_formKey.currentState!.validate()) return;

  final updateBody = <String, dynamic>{
    "exam_id": widget.exam.examId,
  };

  // TITLE
  if (titleController.text.trim() != widget.exam.examTitle) {
    updateBody["exam_title"] = titleController.text.trim();
  }

  // CLASS 
  if (selectedClassCode == null || selectedClassCode!.isEmpty) {
    selectedClassCode = widget.exam.classId; 
  }

  if (selectedClassCode != widget.exam.classId) {
    updateBody["class_id"] = selectedClassCode!;
  }

  // DESCRIPTION
  if (descriptionController.text.trim() != widget.exam.description) {
    updateBody["description"] = descriptionController.text.trim();
  }

  // DATETIME
  final newExamDate = DateFormat("yyyy-MM-dd").format(selectedDateTime);

  final newDeadline =
      "${DateFormat("yyyy-MM-dd").format(selectedDateTime)}T"
      "${selectedDateTime.hour.toString().padLeft(2, '0')}:"
      "${selectedDateTime.minute.toString().padLeft(2, '0')}";

  if (newExamDate != widget.exam.examDate) {
    updateBody["exam_date"] = newExamDate;
  }

  if (newDeadline != widget.exam.deadline) {
    updateBody["deadline"] = newDeadline;
  }

  // STATUS
  if (status != widget.exam.status) {
    updateBody["status"] = status;
  }

  // If nothing changed
  if (updateBody.length == 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nothing to update")),
    );
    return;
  }

  final success = await ExamService().updateExam(
    userId: widget.currentUser.userId,
    updateBody: updateBody,
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
    final dateFormatted = DateFormat("MMMM dd, yyyy").format(selectedDateTime);
    final timeFormatted = DateFormat("h:mm a").format(selectedDateTime);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Exam")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              //  Exam Title
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Exam Title"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 20),

              //  CLASS DROPDOWN
              DropdownButtonFormField<String>(
                value: selectedClassCode,
                decoration: const InputDecoration(labelText: "Select Class"),
                items: userClasses.map((c) {
                  return DropdownMenuItem(
                    value: c.classCode,
                    child: Text("${c.classCode} • ${c.className}"),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedClassCode = v),
              ),

              const SizedBox(height: 20),

              // DESCRIPTION
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),

              const SizedBox(height: 20),

              // DATE + TIME
              Text("Exam Date & Time",
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateFormatted,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      //   Text(timeFormatted,
                      //       style: TextStyle(
                      //           color: Colors.grey.shade600, fontSize: 14)),
                      // 
                      ],
                    ),
                    IconButton(
                      onPressed: pickDate,
                      icon: const Icon(Icons.edit_calendar, size: 28),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // STATUS
              DropdownButtonFormField(
                value: status,
                items: ["pending", "completed"]
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                    .toList(),
                onChanged: (v) => status = v!,
                decoration: const InputDecoration(labelText: "Status"),
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
