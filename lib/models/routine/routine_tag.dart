class RoutineTag {
  final String id;
  final String name;
  final List<String> routinesId;

  RoutineTag({
    required this.id,
    required this.name,
    required this.routinesId,
  });

  factory RoutineTag.fromJson(Map<String, dynamic> json) {
    return RoutineTag(
      id: json['Id'],
      name: json['Name'],
      routinesId: List<String>.from(json['Routines'] ?? []),
    );
  }
}
