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

  // Updated fromJson to handle missing fields
  factory Routine.fromJson(Map<String, dynamic> json) {
    // Use a fallback ID (name + order) if the actual ID is missing
    final fallbackId = '${json['Name'] ?? ''}_${json['Order'] ?? 0}';
    // Print the JSON response to ensure correct data
    print('Creating Routine from JSON: $json');
    return Routine(
      id: (json['id'] ?? fallbackId) as String, // Use fallback ID if necessary
      name: (json['Name'] ?? 'Unnamed') as String,
      duration: (json['Duration'] ?? 0) as int,
      order: (json['Order'] ?? 0) as int,
      days: List<String>.from(json['days'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'duration': duration,
      'order': order,
      'days': days,
    };
  }
}
