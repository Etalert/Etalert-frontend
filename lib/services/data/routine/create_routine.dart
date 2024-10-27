import 'package:frontend/services/api.dart';
import 'package:dio/dio.dart';

Future<void> createRoutine(
    String googleId, String name, int duration, int order, List<String> days) async {
  try {
    final response = await Api.dio.post(
      '/users/routines',
      data: {
        "googleId": googleId,
        "name": name,
        "duration": duration,
        "order": order,
        "days": days, // Include the 'days' field
      },
    );

    if (response.statusCode == 201) {
      print('Routine created successfully');
    } else {
      print(
          'Failed to create routine: ${response.statusCode} ${response.data}');
      throw Exception('Failed to create routine');
    }
  } on DioError catch (e) {
    print('DioError: ${e.message}');
    if (e.response != null) {
      print('Response: ${e.response?.data}');
    }
    rethrow; // Rethrow to handle it in the UI layer
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
}
