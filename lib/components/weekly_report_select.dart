import 'package:flutter/material.dart';
import 'package:frontend/screens/routine_report.dart';

class WeeklyReportSelect extends StatefulWidget {
  final String googleId;
  final String startDate;
  final String endDate;
  const WeeklyReportSelect({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.googleId,
  });

  @override
  State<WeeklyReportSelect> createState() => _WeeklyReportSelectState();
}

class _WeeklyReportSelectState extends State<WeeklyReportSelect> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineReport(
                googleId: widget.googleId,
                startDate: widget.startDate,
                endDate: widget.endDate),
          ),
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 0.5,
              color: Color.fromARGB(255, 145, 145, 145),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${widget.startDate} - ${widget.endDate}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSecondary),
          ],
        ),
      ),
    );
  }
}
