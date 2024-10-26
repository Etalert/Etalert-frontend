import 'package:flutter/material.dart';
import 'package:frontend/components/routine_report_detail.dart';

class RoutineReportDropdown extends StatefulWidget {
  final int averageSkewedTime;
  final String routineName;
  final bool isLate;
  final String id;

  const RoutineReportDropdown({
    super.key,
    required this.averageSkewedTime,
    required this.routineName,
    required this.isLate,
    required this.id,
  });

  @override
  State<RoutineReportDropdown> createState() => _RoutineReportDropdownState();
}

class _RoutineReportDropdownState extends State<RoutineReportDropdown> {
  bool _isExpanded = false;

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
                  child: Text(
                    widget.routineName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.isLate ? 'Late' : 'Early',
                      style: const TextStyle(
                        color: Color.fromARGB(255, 99, 99, 99),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.averageSkewedTime} ${widget.averageSkewedTime > 1 ? 'mins' : 'min'}',
                      style: TextStyle(
                          color: widget.isLate
                              ? Colors.red[700]
                              : Colors.green[600],
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
                        RoutineReportDetail(
                          date: '28 Oct 2024',
                          startTime: '08:00',
                          endTime: '08:30',
                          actualEndTime: '08:35',
                          skewness: -5,
                        ),
                        RoutineReportDetail(
                          date: '29 Oct 2024',
                          startTime: '08:00',
                          endTime: '08:30',
                          actualEndTime: '08:20',
                          skewness: 10,
                        ),
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
