import 'package:frontend/services/api.dart';

Future<void> deleteRoutine(String routineId) async {
  try {
    final response = await Api.dio.delete('/users/routines/$routineId');

    if (response.statusCode != 200) {
      throw Exception('Failed to delete routine');
    }
  } catch (e) {
    print('Error deleting routine: $e');
    rethrow;
  }
}
