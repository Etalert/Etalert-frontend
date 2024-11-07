import 'package:frontend/services/api.dart';

Future<void> editRoutine(
  String routineId,
  String name,
  int duration,
  int order,
) async {
  try {
    if (routineId.isEmpty) {
      throw Exception('Routine ID cannot be empty');
    }

    final response = await Api.dio.patch(
      '/users/routines/edit/$routineId',
      data: {
        'name': name,
        'duration': duration,
        'order': order,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update routine: ${response.data}');
    }
  } catch (e) {
    print('Error in editRoutine: $e');
    rethrow;
  }
}
