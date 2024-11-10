import 'package:dio/dio.dart';
import 'package:frontend/models/routine/routine_tag.dart';
import 'package:frontend/services/api.dart';

Future<List<RoutineTag>> getRoutineTags(String googleId) async {
  try {
    final response = await Api.dio.get('/users/tags/$googleId');

    if (response.statusCode == 200) {
      final List<RoutineTag> routineTags = (response.data as List)
          .map((routineTag) => RoutineTag.fromJson(routineTag))
          .toList();

      return routineTags;
    } else {
      print(
          'Failed to get routine tags: ${response.statusCode} ${response.data}');
      throw Exception('Failed to get routine tags');
    }
  } on DioException catch (e) {
    print('DioError: ${e.message}');
    if (e.response != null) {
      print('Response: ${e.response?.data}');
    }
    rethrow;
  } catch (e) {
    print('Error: $e');
    rethrow;
  }
}
