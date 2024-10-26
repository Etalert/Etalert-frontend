import 'package:flutter/material.dart';
import 'package:frontend/components/sidebar.dart';
import 'package:frontend/components/weekly_report_select.dart';
import 'package:frontend/models/routine/weekly_report_list.dart';
import 'package:frontend/services/data/routine/weekly_reports.dart';

class WeeklyReports extends StatefulWidget {
  final String googleId;
  const WeeklyReports({super.key, required this.googleId});

  @override
  State<WeeklyReports> createState() => _WeeklyReportsState();
}

class _WeeklyReportsState extends State<WeeklyReports> {
  List<WeeklyReportList>? weeklyReporDates;

  Future<void> getWeeklyReportDateList(String googleId) async {
    weeklyReporDates = await getWeeklyReportList(googleId);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getWeeklyReportList(widget.googleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Reports',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            )),
      ),
      drawer: Sidebar(googleId: widget.googleId),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ...weeklyReporDates?.map((e) {
                      return WeeklyReportSelect(
                        googleId: widget.googleId,
                        startDate: e.startDate,
                        endDate: e.endDate,
                      );
                    }).toList() ??
                    [
                      const Center(
                        child: Text('No weekly reports available'),
                      ),
                    ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}