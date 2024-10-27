import 'dart:convert';

import 'package:frontend/models/routine/weekly_report.dart';
import 'package:frontend/services/api.dart';

Future<List<WeeklyReport>?> getWeeklyReport(
    String googleId, String startDate) async {
  try {
    final response =
        await Api.dio.get('/users/weekly-reports/$googleId/$startDate');

    if (response.statusCode == 200) {
      final data = response.data;
      List<dynamic> res = json.decode(json.encode(data));
      List<WeeklyReport> weeklyReport =
          res.map<WeeklyReport>((json) => WeeklyReport.fromJson(json)).toList();
      return weeklyReport;
    }
  } catch (e) {
    rethrow;
  }
  return null;
}
