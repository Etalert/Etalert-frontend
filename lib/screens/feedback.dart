import 'package:flutter/material.dart';
import 'package:frontend/components/sidebar.dart';
import 'package:frontend/models/feedback/feedback.dart';
import 'package:frontend/services/data/feedback/create_feedback.dart';
import 'package:go_router/go_router.dart';

class UserFeedBack extends StatefulWidget {
  final String googleId;
  const UserFeedBack({super.key, required this.googleId});

  @override
  State<UserFeedBack> createState() => _UserFeedBackState();
}

class _UserFeedBackState extends State<UserFeedBack> {
  @override
  Widget build(BuildContext context) {
    TextEditingController feedbackController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: Sidebar(googleId: widget.googleId),
      body: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your experience with ETAlert?',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please provide your feedback below.',
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: feedbackController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    hintText: 'Enter your feedback here',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final feedback = UserFeedback(
                                googleId: widget.googleId,
                                feedback: feedbackController.text,
                              );
                              createFeedback(feedback);
                              context.go('/${widget.googleId}');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: const Text('Submit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
