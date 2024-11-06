class WeeklyReport {
  final String id;
  final String name;
  final String startDate;
  final String endDate;
  final String tag;
  final List<ReportDetails> details;

  WeeklyReport({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.tag,
    required this.details,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      id: json['Id'],
      name: json['Name'],
      startDate: json['StartDate'],
      endDate: json['EndDate'],
      tag: json['Tag'],
      details: (json['Details'] as List)
          .map((item) => ReportDetails.fromJson(item))
          .toList(),
    );
  }
}

class ReportDetails {
  final String date;
  final String startTime;
  final String endTime;
  final String actualEndTime;
  final int skewness;

  ReportDetails({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.actualEndTime,
    required this.skewness,
  });

  factory ReportDetails.fromJson(Map<String, dynamic> json) {
    return ReportDetails(
      date: json['Date'],
      startTime: json['StartTime'],
      endTime: json['EndTime'],
      actualEndTime: json['ActualEndTime'],
      skewness: json['Skewness'],
    );
  }
}
