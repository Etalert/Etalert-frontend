import 'package:frontend/models/routine/routine_model.dart';
import 'package:frontend/services/api.dart';

Future<List<Routine>> getRoutinesByTagId(String tagId) async {
  try {
    final response = await Api.dio.get('/users/tags/routines/$tagId');

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;

      List<Routine> routines = data.map((json) {
        return Routine.fromJson(Map<String, dynamic>.from(json));
      }).toList();

      routines.sort((a, b) => a.order.compareTo(b.order));

      return routines;
    } else {
      throw Exception('Failed to load routines: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading routines: $e');
    rethrow;
  }
}
