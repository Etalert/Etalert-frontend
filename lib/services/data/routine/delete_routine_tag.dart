import 'package:frontend/services/api.dart';

Future<void> deleteRoutineTag(String tagId) async {
  try {
    final response = await Api.dio.delete('/users/tags/$tagId');
  } catch (e) {
    rethrow;
  }
}
