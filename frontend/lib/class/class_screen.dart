import 'package:flutter/material.dart';
import 'package:schedsync_app/class/course_screen.dart';
import 'package:schedsync_app/home/home_screen.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/service/class_service.dart';

class ClassScreen extends StatefulWidget {
  final BaseAppUser currentUser;
  final void Function() switchTheme;
  final void Function() logout;

  const ClassScreen({
    super.key,
    required this.currentUser,
    required this.switchTheme,
    required this.logout,
  });

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  bool _isLoading = true;
  List<ClassModel> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    try {
      final fetchedClasses = await ClassService.getUserClasses(
        widget.currentUser.userId,
      );

      setState(() {
        _classes = fetchedClasses;
        _isLoading = false;
      });

      print("Fetched classes: $fetchedClasses");
    } catch (e) {
      print("Error fetching classes: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(
                widget.switchTheme,
                currentUser: widget.currentUser,
                logout: widget.logout,
              ),
            ),
          ),
        ),
        title: const Text("My Classes"),
        centerTitle: true,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
          ? const Center(
              child: Text(
                "No classes added yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                return ClassCard(
                  classItem: _classes[index],
                  currentUser: widget.currentUser, 
                );
              },
            ),
    );
  }
}

class ClassCard extends StatelessWidget {
  const ClassCard({
    super.key,
    required this.classItem,
    required this.currentUser,
  });

  final ClassModel classItem;
  final BaseAppUser currentUser;

  @override
  Widget build(BuildContext context) {
 final textColor = Theme.of(context).colorScheme.onBackground;

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => CourseScreen(
                classItem: classItem,
                currentUser: currentUser, 
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classItem.className,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classItem.schedule,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
