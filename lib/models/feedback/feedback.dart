class UserFeedback {
  final String googleId;
  final String feedback;

  UserFeedback({
    required this.googleId,
    required this.feedback,
  });

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      googleId: json['googleId'],
      feedback: json['feedback'],
    );
  }
}
