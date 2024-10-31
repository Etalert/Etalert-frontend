import 'package:frontend/models/feedback/feedback.dart';
import 'package:frontend/services/api.dart';

Future<void> createFeedback(UserFeedback feedback) async {
  try {
    final response = await Api.dio.post('/users/create-feedbacks', data: {
      'googleId': feedback.googleId,
      'feedback': feedback.feedback,
    });

    if (response.statusCode == 200) {
      return;
    }
  } catch (e) {
    rethrow;
  }
}
