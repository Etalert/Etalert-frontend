class WeeklyReportList {
  final String id;
  final String startDate;
  final String endDate;

  WeeklyReportList({
    required this.id,
    required this.startDate,
    required this.endDate,
  });

  factory WeeklyReportList.fromJson(Map<String, dynamic> json) {
    return WeeklyReportList(
      id: json['id'],
      startDate: json['startDate'],
      endDate: json['endDate'],
    );
  }
}
