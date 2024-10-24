import 'package:frontend/services/api.dart';
import 'package:frontend/models/routine/routine_model.dart';

Future<List<Routine>> getAllRoutines(String googleId) async {
  try {
    final response = await Api.dio.get('/users/routines/$googleId');
    print('Raw response data: ${response.data}'); // Debug log

    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> data = response.data;

      return data.map((json) {
        return Routine.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } else {
      throw Exception('Failed to load routines: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading routines: $e');
    rethrow;
  }
}


