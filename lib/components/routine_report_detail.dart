import 'package:flutter/material.dart';

class RoutineReportDetail extends StatelessWidget {
  final String date;
  final String startTime;
  final String endTime;
  final String actualEndTime;
  final int skewness;
  const RoutineReportDetail({
    super.key,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.actualEndTime,
    required this.skewness,
  });

  @override
  Widget build(BuildContext context) {
    String convertSkewnessToMinutes(int skewness) {
      if (skewness <= 0) {
        String minute = skewness.abs() <= 1
            ? '${skewness.abs()} min'
            : '${skewness.abs()} mins';
        return minute;
      } else {
        return '$skewness ${skewness.abs() == 1 ? 'min' : 'mins'}';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.only(bottom: 16),
        decoration: const BoxDecoration(
            border: Border(
          bottom: BorderSide(
            width: 0.5,
            color: Color.fromARGB(255, 220, 220, 220),
          ),
        )),
        child: Column(
          children: [
            Text(
              date,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time: $startTime',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'End Time: $endTime',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actual End Time: $actualEndTime',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${skewness <= 0 ? 'Late' : 'Early'}: ${convertSkewnessToMinutes(skewness)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
