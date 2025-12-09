import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/service/class_service.dart';
import 'package:schedsync_app/service/exam_service.dart';
import 'package:schedsync_app/model/base_app_user.dart';

Future<void> showAddExamSheet(
  BuildContext context,
  BaseAppUser currentUser,
) async {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final examService = ExamService();

  DateTime? selectedDate;
  //TimeOfDay? selectedDeadline;

  final dateController = TextEditingController();
  final timeController = TextEditingController();

  List<ClassModel> userClasses = [];
  String? selectedClassCode;
  bool loadedClasses = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          Future<void> loadClasses() async {
            if (loadedClasses) return;

            final fetched = await ClassService.getUserClasses(
              currentUser.userId,
            );

            setState(() {
              userClasses = fetched;
              loadedClasses = true;
            });
          }

          loadClasses();

          Future<void> pickDate() async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: now,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: DateTime(2100),
            );

            if (picked != null) {
              setState(() {
                selectedDate = picked;
                dateController.text = DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          }

          // Future<void> pickDeadline() async {
          //   final picked = await showTimePicker(
          //     context: ctx,
          //     initialTime: const TimeOfDay(hour: 9, minute: 0),
          //   );

          //   if (picked != null) {
          //     setState(() {
          //       selectedDeadline = picked;
          //       timeController.text = picked.format(ctx);
          //     });
          //   }
          // }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Exam Title *',
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedClassCode,
                    decoration: const InputDecoration(
                      labelText: "Select Class *",
                    ),
                    items: !loadedClasses
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              enabled: false,
                              child: Text("Loading classes..."),
                            ),
                          ]
                        : userClasses.map((cls) {
                            return DropdownMenuItem(
                              value: cls.classCode,
                              child: Text(
                                "${cls.classCode} • ${cls.className}",
                              ),
                            );
                          }).toList(),
                    onChanged: loadedClasses
                        ? (value) {
                            setState(() {
                              selectedClassCode = value;

                              final cls = userClasses.firstWhere(
                                (c) => c.classCode == value,
                              );

                              final startTime = cls.timeStart;

                              timeController.text = startTime;
                            });
                          }
                        : null,
                  ),

                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: pickDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Exam Date *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // GestureDetector(
                  //   onTap: pickDeadline,
                  //   child: AbsorbPointer(
                  //     child: TextField(
                  //       controller: timeController,
                  //       decoration: const InputDecoration(
                  //         labelText: 'Deadline Time *',
                  //         suffixIcon: Icon(Icons.access_time),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            selectedDate == null ||
                            //selectedDeadline == null ||
                            selectedClassCode == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please complete all required fields.",
                              ),
                            ),
                          );
                          return;
                        }

                        final examDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate!);

                        final classObj = userClasses.firstWhere(
                          (c) => c.classCode == selectedClassCode,
                        );

                        final classTime = classObj.timeStart;

                        final parsedTime = DateFormat(
                          "h:mm a",
                        ).parse(classTime);

                        final deadline =
                            "${examDate}T${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}:00";

                        final success = await examService.addExam(
                          context: context,
                          userId: currentUser.userId,
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          examDate: examDate,
                          deadline: deadline,
                          classId: selectedClassCode!,
                        );

                        if (success) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("Exam added successfully!"),
                            ),
                          );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
