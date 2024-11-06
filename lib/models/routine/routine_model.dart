class Routine {
  final String id;
  final String name;
  final int duration;
  final int order;

  Routine({
    required this.id,
    required this.name,
    required this.duration,
    required this.order,
  });

  // Factory method to create a Routine from JSON
  factory Routine.fromJson(Map<String, dynamic> json) {
    final id = json['Id'] ?? json['id'] ?? '';
    final name = json['Name'] ?? json['name'] ?? '';
    final duration = json['Duration'] ?? json['duration'] ?? 0;
    final order = json['Order'] ?? json['order'] ?? 0;

    return Routine(
      id: id,
      name: name,
      duration: duration,
      order: order,
    );
  }

  // Convert Routine object to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'duration': duration,
        'order': order,
      };
}

extension RoutineCopyWith on Routine {
  Routine copyWith({
    String? name,
    int? duration,
    int? order,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      order: order ?? this.order,
    );
  }
}
