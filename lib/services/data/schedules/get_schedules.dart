import 'dart:convert';

import 'package:frontend/models/schedules/schedules.dart';
import 'package:frontend/services/api.dart';

Future<List<Schedule>?> getAllSchedulesByDate(
    String googleId, String date) async {
  try {
    final response = await Api.dio.get('/users/schedules/all/$googleId/$date');

    if (response.statusCode == 200) {
      final data = response.data;
      List<Schedule> res = parseSchedules(json.encode(data));
      return res;
    }
  } catch (e) {
    rethrow;
  }
  return null;
}
