import 'package:flutter/material.dart';
import 'package:frontend/components/routine_report_dropdown.dart';
import 'package:frontend/models/routine/weekly_report.dart';
import 'package:frontend/screens/setting.dart';
import 'package:frontend/services/data/routine/weekly_report.dart';
import 'package:go_router/go_router.dart';

class RoutineReport extends StatefulWidget {
  final String googleId;
  final String startDate;
  final String endDate;
  const RoutineReport(
      {super.key,
      required this.googleId,
      required this.startDate,
      required this.endDate});

  @override
  State<RoutineReport> createState() => _RoutineReportState();
}

class _RoutineReportState extends State<RoutineReport> {
  List<WeeklyReport> weeklyReport = [];
  bool isLoading = true;

  getWeeklyReportData(String googleId, String startDate) async {
    var report = await getWeeklyReport(googleId, startDate);
    setState(() {
      weeklyReport = report!;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getWeeklyReportData(widget.googleId, widget.startDate);
  }

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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
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
                      padding:
                          const EdgeInsets.only(left: 20, top: 20, bottom: 20),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text('${widget.startDate} - ${widget.endDate}',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 30, left: 20, right: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Routines Report',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.go('/setting/${widget.googleId}'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Edit routines',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...weeklyReport.map((e) {
                            return RoutineReportDropdown(
                              weeklyReport: e,
                            );
                          }).toList(),
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
