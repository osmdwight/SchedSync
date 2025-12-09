import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:schedsync_app/home/edit_exam.dart';
import 'package:schedsync_app/model/class_model.dart';
import 'package:schedsync_app/model/submission_model.dart';
import 'package:schedsync_app/service/class_service.dart';
import 'package:schedsync_app/service/exam_service.dart';
import 'package:schedsync_app/service/submission_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:schedsync_app/Profile/profile_screen.dart';
import 'package:schedsync_app/class/class_screen.dart';
import 'package:schedsync_app/home/add_tab.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'package:schedsync_app/model/exam_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen(
    this.switchTheme, {
    super.key,
    required this.currentUser,
    required this.logout,
  });

  final void Function() switchTheme;
  final VoidCallback logout;
  final BaseAppUser currentUser;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<ExamModel> exams = [];
  List<ClassModel> classes = [];
  List<Appointment> appointments = [];
  List<SubmissionModel> submissions = [];
  bool isLoadingSubmissions = true;

  bool isLoadingExams = true;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
     _loadExams();
    _loadClasses();
    _loadSubmissions();

    _pages = [
      Center(child: Text("Dashboard Page")),
      Center(child: Text("Add Schedule")),
      ClassScreen(
        switchTheme: widget.switchTheme,
        currentUser: widget.currentUser,
        logout: widget.logout,
      ),
    ];
  }

 Future _loadSubmissions() async {
    final service = SubmissionService();
    final data = await service.getUserSubmissions(widget.currentUser.userId);
    setState(() {
        submissions = data;
        isLoadingSubmissions = false;
        appointments = _buildAppointments(); 
    });
} 

Future _loadClasses() async {
    final data = await ClassService.getUserClasses(widget.currentUser.userId);
    setState(() {
        classes = data;
        appointments = _buildAppointments();
    });
} 

Future _loadExams() async {
    final service = ExamService();
    final data = await service.getExams(widget.currentUser.userId, context);
    setState(() {
        exams = data.map((json) => ExamModel.fromJson(json)).toList();
        isLoadingExams = false;
        appointments = _buildAppointments();
    });
} 

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

   

      
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/img/smallLogo.png',
              height: 36,
              color: isDark ? Colors.white : null,
              colorBlendMode: BlendMode.srcIn,
            ),
            const Text(' SchedSync'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: widget.switchTheme,
            icon: const Icon(Icons.brightness_6),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    widget.switchTheme,
                    currentUser: widget.currentUser,
                    logout: widget.logout,
                    goToHome: () {},
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),

      body: _selectedIndex == 0 ? _buildHomeContent() : _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) async {
          if (i == 1) {
            await showAddTabDialog(context, widget.currentUser);
           await _loadClasses(); 
           await _loadExams();
           await _loadSubmissions();

            if (_selectedIndex == 0) {
                 setState(() {
                 });
            }
            return;
          }
          setState(() => _selectedIndex = i);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Classes',
          ),
        ],
      ),
    );
  }

  // HOME PAGE UI
  Widget _buildHomeContent() {
    final textColor = Theme.of(context).colorScheme.onBackground;
     final userExams = exams
        .where((e) => e.userId == widget.currentUser.userId)
        .toList();

    // Definition for user submissions
    final userSubmissions = submissions
        .where((s) => s.userId == widget.currentUser.userId)
        .toList(); 


    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TODAY HEADER
          Text(
            'TODAY',
            style: const TextStyle(
              color: Colors.lightGreen,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            DateFormat('dd MMMM, yyyy').format(DateTime.now()),
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(color: textColor),
          ),

          const SizedBox(height: 10),

          // COUNTERS
          Text(
            "${userExams.length} Exams | ${userSubmissions.length} Submission",
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(color: textColor, fontSize: 18),
          ),

          const SizedBox(height: 12),

          // TOP: CALENDAR
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SfCalendar(
                view: CalendarView.day,
                appointmentBuilder: _appointmentBuilder,
                dataSource: ExamCalendarDataSource(appointments),
                todayHighlightColor: Colors.green,
                showCurrentTimeIndicator: true,
                headerHeight: 0,
                timeSlotViewSettings: const TimeSlotViewSettings(
                  startHour: 6,
                  endHour: 22,
                  timeIntervalHeight: 65,
                  timeFormat: 'h:mm a',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

        ],
      ),
    );
  }

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final Appointment appt = details.appointments.first;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: appt.color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Text(
          appt.subject,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  int? _convertDayToWeekday(String day) {
    const map = {
      "Mon": DateTime.monday,
      "Monday": DateTime.monday,
      "Tue": DateTime.tuesday,
      "Tuesday": DateTime.tuesday,
      "Wed": DateTime.wednesday,
      "Wednesday": DateTime.wednesday,
      "Thu": DateTime.thursday,
      "Thursday": DateTime.thursday,
      "Fri": DateTime.friday,
      "Friday": DateTime.friday,
      "Sat": DateTime.saturday,
      "Saturday": DateTime.saturday,
      "Sun": DateTime.sunday,
      "Sunday": DateTime.sunday,
    };
    return map[day];
  }

  DateTime? _mergeTime(DateTime base, String timeString) {
    try {
      final parsed = DateFormat("h:mm a").parse(timeString);
      return DateTime(
        base.year,
        base.month,
        base.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      return null;
    }
  }

  List<Appointment> _buildAppointments() {
    List<Appointment> all = [];

    for (final c in classes) {
      for (final d in c.daysOfWeek) {
        final weekday = _convertDayToWeekday(d);
        if (weekday == null) continue;

        //  NEXT OCCURRENCE 
        final now = DateTime.now();
        DateTime classDay = now.subtract(Duration(days: now.weekday - weekday));

        final start = _mergeTime(classDay, c.timeStart);
        final end = _mergeTime(classDay, c.timeEnd);
        if (start == null || end == null) continue;

        //  WEEKLY RECURRENCE
        String dayCode = _weekdayToRecurrenceCode(weekday);
        String recurRule = "FREQ=WEEKLY;BYDAY=$dayCode";

        //  GET EXAMS 
        List<String> todayTexts = [];

        for (final e in exams) {
          final dt = DateTime.tryParse(e.examDatetime ?? "");
          if (dt == null) continue;

          if (e.classId != c.classCode) continue;

          if (dt.year == classDay.year &&
              dt.month == classDay.month &&
              dt.day == classDay.day) {
            todayTexts.add("• EXAM: ${e.examTitle}");
          }
        }

        //  GET SUBMISSIONS 
        for (final s in submissions) {
          final dt = DateTime.tryParse(s.deadline);
          if (dt == null) continue;

          if (s.classId != c.classCode) continue;

          if (dt.year == classDay.year &&
              dt.month == classDay.month &&
              dt.day == classDay.day) {
            todayTexts.add("• SUBMISSION: ${s.title}");
          }
        }

        final subjectText = [
          "${c.className} (${c.classCode})",
          if (todayTexts.isNotEmpty) ...todayTexts,
        ].join("\n");

        //  ADD APPOINTMENT
        all.add(
          Appointment(
            startTime: start,
            endTime: end,
            subject: subjectText,
            color: todayTexts.isEmpty ? Colors.blue : Colors.orange,
            recurrenceRule: recurRule,
          ),
        );
      }
    }

    return all;
  }

  String _weekdayToRecurrenceCode(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "MO";
      case DateTime.tuesday:
        return "TU";
      case DateTime.wednesday:
        return "WE";
      case DateTime.thursday:
        return "TH";
      case DateTime.friday:
        return "FR";
      case DateTime.saturday:
        return "SA";
      case DateTime.sunday:
        return "SU";
      default:
        return "MO";
    }
  }
}

class ExamCalendarDataSource extends CalendarDataSource {
  ExamCalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}
