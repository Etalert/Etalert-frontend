import 'package:frontend/services/api.dart';

Future<void> deleteScheduleByRecurrenceId(
    int recurrenceId, String? date) async {
  try {
    if (date != null) {
      print('service: ' + date);
      final response = await Api.dio
          .delete('/users/schedules/recurrence/$recurrenceId/$date');

      if (response.statusCode == 200) {
        return;
      }
    }
    final response =
        await Api.dio.delete('/users/schedules/recurrence/$recurrenceId');

    if (response.statusCode == 200) {
      return;
    }
  } catch (e) {
    rethrow;
  }
}
