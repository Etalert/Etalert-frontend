import 'package:frontend/services/api.dart';
import 'package:frontend/models/routine/routine_model.dart';

Future<List<Routine>> getAllRoutines(String googleId) async {
  try {
    final response = await Api.dio.get('/users/routines/$googleId');
    print('Raw response data: ${response.data}'); // Debug log
    
    if (response.statusCode == 200) {
      final List<dynamic> data = List<dynamic>.from(response.data);
      return data.map<Routine>((json) {
        // Convert the dynamic map to Map<String, dynamic>
        final Map<String, dynamic> routineMap = Map<String, dynamic>.from(json);
        return Routine.fromJson(routineMap);
      }).toList();
    }
    
    return [];
    
  } catch (e) {
    print('Error loading routines: $e');
    rethrow;
  }
}