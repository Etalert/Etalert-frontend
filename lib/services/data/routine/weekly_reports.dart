import 'dart:convert';

import 'package:frontend/models/routine/weekly_report_list.dart';
import 'package:frontend/services/api.dart';

Future<List<WeeklyReportList>?> getWeeklyReportList(String googleId) async {
  try {
    final response = await Api.dio.get('/users/weekly-report-lists/$googleId');

    if (response.statusCode == 200) {
      final data = response.data;
      List<dynamic> res = json.decode(json.encode(data));
      return res
          .map<WeeklyReportList>((json) => WeeklyReportList.fromJson(json))
          .toList();
    }
  } catch (e) {
    rethrow;
  }
  return null;
}
