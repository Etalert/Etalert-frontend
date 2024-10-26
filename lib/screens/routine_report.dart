import 'package:flutter/material.dart';
import 'package:frontend/components/routine_report_dropdown.dart';

class RoutineReport extends StatefulWidget {
  final String googleId;
  final String weekDate;
  const RoutineReport(
      {super.key, required this.googleId, required this.weekDate});

  @override
  State<RoutineReport> createState() => _RoutineReportState();
}

class _RoutineReportState extends State<RoutineReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weekly Report',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 217, 217, 217)
                        .withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 7,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(widget.weekDate,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
              child: Row(
                children: [
                  Text(
                    'Routines Report',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    RoutineReportDropdown(
                        id: '1',
                        routineName: 'Eat Breakfast',
                        averageSkewedTime: 10,
                        isLate: false),
                    RoutineReportDropdown(
                        id: '2',
                        routineName: 'Take a shower',
                        averageSkewedTime: 14,
                        isLate: true),
                    RoutineReportDropdown(
                        id: '3',
                        routineName: 'Play with dog',
                        averageSkewedTime: 1,
                        isLate: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
