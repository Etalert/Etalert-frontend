import 'package:frontend/services/api.dart';

Future<void> updateRoutineTag(
    String tagId, String tagName, List<String> routineId) async {
  try {
    final response = await Api.dio.patch('/users/tags/$tagId', data: {
      'name': tagName,
      'routines': routineId,
    });
  } catch (e) {
    rethrow;
  }
}
