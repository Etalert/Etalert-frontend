class Routine {
  String? googleId;
  String name;
  int duration;
  int order;

  Routine(
      {this.googleId,
      required this.name,
      required this.duration,
      required this.order});

  factory Routine.fromJson(Map json) {
    return Routine(
      googleId: json['googleId']?.toString(), // Optional field
      name: json['Name']?.toString() ?? '', // Note the capital 'N' in 'Name'
      duration: json['Duration']?.toInt() ?? 0, // Note the capital 'D'
      order: json['Order']?.toInt() ?? 0, // Note the capital 'O'
    );
  }
}
