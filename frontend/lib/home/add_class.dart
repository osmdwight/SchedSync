
import 'package:flutter/material.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/service/class_service.dart';

final _classService = ClassService();

Future showAddClassSheet(
  BuildContext context, {
  required BaseAppUser currentUser,

  bool isEdit = false,
  String? classCode,
  String? className,
  TimeOfDay? timeStart,
  TimeOfDay? timeEnd,
  List? selectedDays,
  String? professor,
  String? location,
}) async {
  // Controllers
  final classNameController = TextEditingController(text: className ?? "");
  final professorController = TextEditingController(text: professor ?? "");
  final locationController = TextEditingController(text: location ?? "");

  final classCodeController = TextEditingController(text: classCode ?? "");

  TimeOfDay startTime = timeStart ?? TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = timeEnd ?? TimeOfDay(hour: 10, minute: 0);
  List days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  List selected = selectedDays ?? [];

  final timeStartController = TextEditingController(
    text: startTime.format(context),
  );
  final timeEndController = TextEditingController(
    text: endTime.format(context),
  );

  Future pickStartTime(StateSetter setState) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );
    if (picked != null) {
      setState(() {
        startTime = picked;
        timeStartController.text = startTime.format(context);
      });
    }
  }

  Future pickEndTime(StateSetter setState) async {
    final picked = await showTimePicker(context: context, initialTime: endTime);
    if (picked != null) {
      setState(() {
        endTime = picked;
        timeEndController.text = endTime.format(context);
      });
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(/* ... */),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  TextField(
                    controller:
                        classCodeController, 
                    readOnly: isEdit,
                    decoration: InputDecoration(
                      labelText: "Class Code *",
                      hintText: "e.g. MATH101",
                      filled: isEdit,
                      fillColor: isEdit ? Colors.grey.shade200 : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: classNameController,
                    decoration: const InputDecoration(
                      labelText: "Class Name *",
                    ),
                  ),
                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Days of Week *",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    children: days.map((d) {
                      final isSelected = selected.contains(d);
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              selected.add(d);
                            } else {
                              selected.remove(d);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async => await pickStartTime(setState),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: timeStartController,
                              readOnly: true, 
                              decoration: const InputDecoration(
                                labelText: "Time Start *",
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: GestureDetector(
                          onTap: () async => await pickEndTime(setState),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: timeEndController,
                              readOnly: true, 
                              decoration: const InputDecoration(
                                labelText: "Time End *",
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: professorController,
                    decoration: const InputDecoration(
                      labelText: "Professor (optional)",
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: "Location (optional)",
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (classNameController.text.isEmpty ||
                            classCodeController
                                .text
                                .isEmpty || 
                            selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Class Code, Class Name, and Days are required.",
                              ),
                            ),
                          );
                          return;
                        }

                        final timeStartStr = startTime.format(context);
                        final timeEndStr = endTime.format(context);

                        if (timeStartStr.isEmpty || timeEndStr.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Time Start and Time End are required.",
                              ),
                            ),
                          );
                          return;
                        }

                        final createdClass = await _classService.addClass(
                          context: context,
                          userId: currentUser.userId,
                          classCode: classCodeController.text.trim(),
                          className: classNameController.text.trim(),
                          timeStart: timeStartStr,
                          timeEnd: timeEndStr,
                          daysOfWeek: List<String>.from(selected),
                          professor: professorController.text.trim().isEmpty
                              ? null
                              : professorController.text.trim(),
                          location: locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                        );

                        if (createdClass != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Class added successfully.'),
                            ),
                          );
                          Navigator.pop(ctx, createdClass); 
                        }
                      },
                      child: const Text("Save"),
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
