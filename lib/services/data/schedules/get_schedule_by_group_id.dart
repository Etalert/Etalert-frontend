import 'package:frontend/services/api.dart';

Future<List<String>?> getScheduleByGroupId(int groupId) async {
  try {
    String groupIdString = groupId.toString();
    final response = await Api.dio.get('/users/schedules/group/$groupIdString');

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
