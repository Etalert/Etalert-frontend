import 'package:flutter/material.dart';
import 'package:frontend/components/routine_report_detail.dart';
import 'package:frontend/models/routine/weekly_report.dart';

class RoutineReportDropdown extends StatefulWidget {
  final WeeklyReport weeklyReport;

  const RoutineReportDropdown({
    super.key,
    required this.weeklyReport,
  });

  @override
  State<RoutineReportDropdown> createState() => _RoutineReportDropdownState();
}

class _RoutineReportDropdownState extends State<RoutineReportDropdown> {
  bool _isExpanded = false;

  int get averageSkewedTime {
    int totalSkewness = 0;
    for (var element in widget.weeklyReport.details) {
      totalSkewness += element.skewness;
    }

    int averageSkewedTime = totalSkewness ~/ widget.weeklyReport.details.length;
    return averageSkewedTime;
  }

  bool get isLate {
    bool isLate = averageSkewedTime > 0;
    return isLate;
  }

  String shortedDay(String day) {
    String shortedDay = day.substring(0, 3);
    return shortedDay;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: const BoxDecoration(
          color: Color.fromARGB(31, 200, 199, 199),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.weeklyReport.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Repeated: ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.weeklyReport.days.length == 7)
                          Text(
                            'Everyday',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 13,
                            ),
                          )
                        else
                          ...widget.weeklyReport.days.map((e) {
                            return Text(
                              widget.weeklyReport.days.last == e
                                  ? shortedDay(e)
                                  : '${shortedDay(e)}, ',
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ],
                )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isLate ? 'Late' : 'Early',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 99, 99, 99),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$averageSkewedTime ${averageSkewedTime > 1 ? 'mins' : 'min'}',
                      style: TextStyle(
                          color: isLate ? Colors.red[700] : Colors.green[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.onSecondary,
                    )
                  ],
                )
              ],
            ),
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                            top: BorderSide(
                          color: Color.fromARGB(255, 220, 220, 220),
                        )),
                      ),
                    ),
                    Column(
                      children: [
                        ...widget.weeklyReport.details.map((e) {
                          return RoutineReportDetail(
                            date: e.date,
                            startTime: e.startTime,
                            endTime: e.endTime,
                            actualEndTime: e.actualEndTime,
                            skewness: e.skewness,
                          );
                        }).toList(),
                      ],
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
