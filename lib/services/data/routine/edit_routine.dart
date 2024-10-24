import 'package:dio/dio.dart';
import 'package:frontend/services/api.dart';

Future<void> editRoutine(
  String routineId, String name, int duration, int order, List<String> days) async {
  try {
    if (routineId.isEmpty) {
      throw Exception('Routine ID cannot be empty');
    }

    // Ensure the request data is valid
    final data = {
      'googleId': routineId,
      'name': name,
      'duration': duration,
      'order': order,
      'days': days,
    };

    print('Sending PATCH request with data: $data');

    final response = await Api.dio.patch(
      '/users/routines/edit/$routineId',
      data: data,
      options: Options(
        headers: {'Content-Type': 'application/json'}, // Ensure correct headers
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update routine: ${response.data}');
    }
  } catch (e) {
    print('Error in editRoutine: $e'); // Log the error
    rethrow;
  }
}
