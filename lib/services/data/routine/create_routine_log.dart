import 'package:frontend/services/api.dart';

Future<void> createRoutineLog(
    String routineId,
    String googleId,
    String date,
    String startTime,
    String endTime,
    String actualEndTime,
    int skewness) async {
  try {
    await Api.dio.post('/users/routine-logs', data: {
      'routineId': routineId,
      'googleId': googleId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'actualEndTime': actualEndTime,
      'skewness': skewness,
    });
  } catch (e) {
    rethrow;
  }
}
