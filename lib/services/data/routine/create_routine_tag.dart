import 'package:dio/dio.dart';
import 'package:frontend/services/api.dart';

Future<void> createRoutineTag(
    String googleId, String name, List<String> routineId) async {
  try {
    final response = await Api.dio.post(
      '/users/tags',
      data: {
        "googleId": googleId,
        "name": name,
        "routineId": routineId,
      },
    );

    if (response.statusCode == 201) {
      print('Routine tag created successfully');
    } else {
      print(
          'Failed to create routine tag: ${response.statusCode} ${response.data}');
      throw Exception('Failed to create routine tag');
    }
  } on DioException catch (e) {
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
