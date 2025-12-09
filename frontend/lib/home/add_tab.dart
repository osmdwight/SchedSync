import 'package:flutter/material.dart';
import 'package:schedsync_app/model/base_app_user.dart';
import 'add_class.dart';
import 'add_submissions.dart';
import 'add_exams.dart';

Future<void> showAddTabDialog(
  BuildContext context,
  BaseAppUser currentUser,
) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      final theme = Theme.of(context);

      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  offset: Offset(0, 4),
                  color: Colors.black26,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Class Schedule'),
                  onTap: () {
                    Navigator.pop(context, true);
                    showAddClassSheet(context, currentUser: currentUser);
                    
                  },
                ),

                ListTile(
                  title: const Text('Submission'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddSubmissionSheet(
                      context,
                      currentUser, 
                    );
                  },
                ),

                ListTile(
                  title: const Text('Exam'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showAddExamSheet(context, currentUser);
                  },
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
