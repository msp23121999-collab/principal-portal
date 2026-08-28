import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme.dart';

class DepartmentPassDonutChart extends StatelessWidget {
  final double overallPassPercentage;
  final List<Map<String, dynamic>>? studentsData;

  const DepartmentPassDonutChart({
    super.key,
    this.overallPassPercentage = 0.0,
    this.studentsData,
  });

  @override
  Widget build(BuildContext context) {
    int cat90 = 0;
    int cat85 = 0;
    int cat80 = 0;
    int catBelow80 = 0;

    if (studentsData != null && studentsData!.isNotEmpty) {
      final Map<String, List<double>> deptCgpaMap = {};
      for (final s in studentsData!) {
        final dept = (s['department'] ?? s['dept'] ?? 'OTHER').toString();
        final cgpa = double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
        deptCgpaMap.putIfAbsent(dept, () => []).add(cgpa);
      }

      deptCgpaMap.forEach((dept, cgpas) {
        if (cgpas.isNotEmpty) {
          final passCount = cgpas.where((c) => c >= 5.0).length;
          final passPct = (passCount / cgpas.length) * 100.0;
          if (passPct >= 90.0) {
            cat90++;
          } else if (passPct >= 85.0) {
            cat85++;
          } else if (passPct >= 80.0) {
            cat80++;
          } else {
            catBelow80++;
          }
        }
      });
    }

    final int totalDeptsCalculated = cat90 + cat85 + cat80 + catBelow80;
    final double totalF = totalDeptsCalculated > 0 ? totalDeptsCalculated.toDouble() : 1.0;

    final List<Map<String, dynamic>> categories = totalDeptsCalculated > 0
        ? [
            {'label': '90% and above', 'count': '$cat90 Departments', 'color': DeanTheme.successGreen, 'pct': cat90 / totalF},
            {'label': '85% - 89.99%', 'count': '$cat85 Departments', 'color': DeanTheme.primaryBlue, 'pct': cat85 / totalF},
            {'label': '80% - 84.99%', 'count': '$cat80 Departments', 'color': DeanTheme.warningAmber, 'pct': cat80 / totalF},
            {'label': 'Below 80%', 'count': '$catBelow80 Departments', 'color': DeanTheme.dangerRose, 'pct': catBelow80 / totalF},
          ]
        : [
            {'label': '90% and above', 'count': '0 Departments', 'color': DeanTheme.successGreen, 'pct': 0.0},
            {'label': '85% - 89.99%', 'count': '0 Departments', 'color': DeanTheme.primaryBlue, 'pct': 0.0},
            {'label': '80% - 84.99%', 'count': '0 Departments', 'color': DeanTheme.warningAmber, 'pct': 0.0},
            {'label': 'Below 80%', 'count': '0 Departments', 'color': DeanTheme.dangerRose, 'pct': 0.0},
          ];

    final displayCenterPct = overallPassPercentage > 0 ? '${overallPassPercentage.toStringAsFixed(2)}%' : '0.00%';

    return Row(
      children: [
        // Donut Chart with Center Text
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _DonutChartPainter(categories: categories),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayCenterPct,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: DeanTheme.textDark,
                    ),
                  ),
                  const Text(
                    'Overall Pass',
                    style: TextStyle(
                      fontSize: 9,
                      color: DeanTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Categories Legend List
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: cat['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat['label'].toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: DeanTheme.textDark,
                            ),
                          ),
                          Text(
                            cat['count'].toString(),
                            style: const TextStyle(
                              fontSize: 9,
                              color: DeanTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;

  _DonutChartPainter({required this.categories});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 16.0;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -pi / 2;

    bool hasData = false;
    for (final cat in categories) {
      if ((cat['pct'] as double) > 0) hasData = true;
    }

    if (!hasData) {
      final Paint bgPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);
      return;
    }

    for (final cat in categories) {
      final double pct = cat['pct'] as double;
      final double sweepAngle = pct * 2 * pi;

      final Paint paint = Paint()
        ..color = cat['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
