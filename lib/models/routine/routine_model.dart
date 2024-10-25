class Routine {
  final String id;
  final String name;
  final int duration;
  final int order;
  final List<String> days;

  Routine({
    required this.id,
    required this.name,
    required this.duration,
    required this.order,
    required this.days,
  });

  // Factory method to create a Routine from JSON
  factory Routine.fromJson(Map<String, dynamic> json) {
    final id = json['Id'] ?? json['id'] ?? '';
    final name = json['Name'] ?? json['name'] ?? '';
    final duration = json['Duration'] ?? json['duration'] ?? 0;
    final order = json['Order'] ?? json['order'] ?? 0;
    final days = _parseDays(json['Days'] ?? json['days']);

    return Routine(
      id: id,
      name: name,
      duration: duration,
      order: order,
      days: days,
    );
  }

  static List<String> _parseDays(dynamic daysData) {
    if (daysData == null) return [];
    if (daysData is List && daysData.isNotEmpty) {
      return daysData.map((e) => e.toString()).toList();
    }
    return [];
  }

  // Convert Routine object to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'duration': duration,
        'order': order,
        'days': days,
      };
}
