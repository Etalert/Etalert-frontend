import 'package:frontend/services/api.dart';

Future<List<String>?> getScheduleByRecurrenceId(int recurrenceId, String date) async {
  try {
    final response = await Api.dio.get('/users/schedules/recurrence/$recurrenceId/$date');

    if (response.statusCode == 200) {
      final data = response.data;
      List<String> res = List<String>.from(data);
      return res;
    }
  } catch (e) {
    rethrow;
  }
  throw Exception('Failed to get schedule by group id');
}
