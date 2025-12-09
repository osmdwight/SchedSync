import 'package:flutter/material.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/service/class_service.dart';

class EditClassScreen extends StatefulWidget {
  final ClassModel classItem;
  final BaseAppUser currentUser;

  const EditClassScreen({
    super.key,
    required this.classItem,
    required this.currentUser,
  });

  @override
  State<EditClassScreen> createState() => _EditClassScreenState();
}

class _EditClassScreenState extends State<EditClassScreen> {
  late TextEditingController nameCtrl;
  late TextEditingController codeCtrl;
  late TextEditingController profCtrl;
  late TextEditingController locCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.classItem.className);
    codeCtrl = TextEditingController(text: widget.classItem.classCode);
    profCtrl = TextEditingController(text: widget.classItem.professor ?? "");
    locCtrl = TextEditingController(text: widget.classItem.location ?? "");
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    codeCtrl.dispose();
    profCtrl.dispose();
    locCtrl.dispose();
    super.dispose();
  }

  Future<void> save() async {
  final updatedData = {
    "class_name": nameCtrl.text,
    "professor": profCtrl.text,
    "location": locCtrl.text,
    "time_start": widget.classItem.timeStart,
    "time_end": widget.classItem.timeEnd,
    "days_of_week": widget.classItem.daysOfWeek,
  };

  final success = await ClassService().updateClass(
    userId: widget.currentUser.userId!,
    classCode: widget.classItem.classCode,  
    updatedData: updatedData,
  );

  if (success) {
    Navigator.pop(context, true);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to update class")),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Class"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Class Name")),
              const SizedBox(height: 15),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Class Code - Not editable"),readOnly: true,),
              const SizedBox(height: 15),
            TextField(controller: profCtrl, decoration: const InputDecoration(labelText: "Professor")),
              const SizedBox(height: 15),
            TextField(controller: locCtrl, decoration: const InputDecoration(labelText: "Location")),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: save,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
