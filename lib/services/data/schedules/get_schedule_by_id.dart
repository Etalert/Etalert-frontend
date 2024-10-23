import 'package:frontend/models/schedules/schedules.dart';
import 'package:frontend/services/api.dart';

Future<Schedule> getScheduleById(String id) async {
  try {
    final response = await Api.dio.get('/users/schedules/$id');

    if (response.statusCode == 200) {
      final data = response.data;
      Schedule res = Schedule.fromJson(data);
      return res;
    }
  } catch (e) {
    rethrow;
  }
  throw Exception('Failed to get schedule by id');
}
