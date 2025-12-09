import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/service/class_service.dart';
import 'package:schedsync_app/service/submission_service.dart';
import 'package:schedsync_app/model/base_app_user.dart';

Future<void> showAddSubmissionSheet(
  BuildContext context,
  BaseAppUser currentUser,
) async {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final submissionService = SubmissionService();

  DateTime? selectedDate;
  //TimeOfDay? selectedTime;

  final dateController = TextEditingController();
  //final timeController = TextEditingController();

  String status = "pending";

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
                  // drag indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Submission Title *',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Class dropdown
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
                              value: cls.classCode.toString(),
                              child: Text(
                                "${cls.classCode} • ${cls.className}",
                              ),
                            );
                          }).toList(),
                    onChanged: loadedClasses
                        ? (value) {
                            setState(() {
                              selectedClassCode = value;
                            });
                          }
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Date picker
                  GestureDetector(
                    onTap: pickDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: dateController,
                        decoration: const InputDecoration(
                          labelText: 'Submission Date *',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Time picker
                  

                  const SizedBox(height: 16),

                  // Status toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Mark as done"),
                      Switch(
                        value: status == "done",
                        onChanged: (val) {
                          setState(() {
                            status = val ? "done" : "pending";
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Save button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            selectedClassCode == null ||
                            selectedDate == null 
                            //selectedTime == null
                            ) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please complete all required fields.",
                              ),
                            ),
                          );
                          return;
                        }

                        final submissionDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate!);

                         final classObj = userClasses.firstWhere(
                          (c) => c.classCode == selectedClassCode,
                        );


                        final classTime = classObj.timeStart; // "9:00 AM"

                        final parsedTime = DateFormat(
                          "h:mm a",
                        ).parse(classTime);

                        final deadline =
                            "${submissionDate}T${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}:00";
                        final success = await submissionService.addSubmission(
                          context: context,
                          userId: currentUser.userId,
                          Title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          submissionDate: submissionDate,
                          deadline: deadline,
                          classId: selectedClassCode!,
                          status: status,
                        );

                        if (success) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("Submission added successfully!"),
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
