import 'package:flutter/material.dart';
import '../../theme.dart';

class DepartmentPerformanceComboChart extends StatelessWidget {
  final List<Map<String, dynamic>>? studentsData;
  final List<Map<String, dynamic>>? departmentsData;

  const DepartmentPerformanceComboChart({
    super.key,
    this.studentsData,
    this.departmentsData,
  });

  @override
  Widget build(BuildContext context) {
    // Dynamic Department Performance Calculation from Supabase student records
    final List<Map<String, dynamic>> depts = [];

    if (studentsData != null && studentsData!.isNotEmpty) {
      final Map<String, List<double>> deptCgpaMap = {};
      for (final s in studentsData!) {
        final dept = (s['department'] ?? s['dept'] ?? 'OTHER').toString();
        final cgpa = double.tryParse(s['cgpa']?.toString() ?? '0') ?? 0.0;
        deptCgpaMap.putIfAbsent(dept, () => []).add(cgpa);
      }

      deptCgpaMap.forEach((deptCode, cgpas) {
        if (cgpas.isNotEmpty) {
          final avgCgpa = cgpas.reduce((a, b) => a + b) / cgpas.length;
          final passCount = cgpas.where((c) => c >= 5.0).length;
          final passPct = (passCount / cgpas.length) * 100.0;
          depts.add({
            'code': deptCode,
            'pass': passPct,
            'sgpa': avgCgpa,
          });
        }
      });
    }

    // Fallback if database table returns empty or zero rows
    final List<Map<String, dynamic>> displayDepts = depts.isNotEmpty
        ? depts
        : [
            {'code': 'CSE', 'pass': 0.0, 'sgpa': 0.0},
            {'code': 'IT', 'pass': 0.0, 'sgpa': 0.0},
            {'code': 'ECE', 'pass': 0.0, 'sgpa': 0.0},
            {'code': 'EEE', 'pass': 0.0, 'sgpa': 0.0},
            {'code': 'MECH', 'pass': 0.0, 'sgpa': 0.0},
            {'code': 'CIVIL', 'pass': 0.0, 'sgpa': 0.0},
          ];

    return Column(
      children: [
        // Legend Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(width: 12, height: 12, color: DeanTheme.primaryBlue),
                const SizedBox(width: 6),
                const Text('Pass Percentage (%)', style: TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
              ],
            ),
            const SizedBox(width: 24),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(color: DeanTheme.successGreen, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 6),
                const Text('Average SGPA (Out of 10)', style: TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Custom Painted Combo Chart (Bar + Line)
        SizedBox(
          height: 220,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ComboChartPainter(depts: displayDepts),
          ),
        ),
      ],
    );
  }
}

class _ComboChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> depts;

  _ComboChartPainter({required this.depts});

  @override
  void paint(Canvas canvas, Size size) {
    final double leftPadding = 35.0;
    final double rightPadding = 25.0;
    final double bottomPadding = 30.0;
    final double topPadding = 20.0;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    final int barCount = depts.length;
    final double groupWidth = chartWidth / (barCount > 0 ? barCount : 1);
    final double barWidth = groupWidth * 0.35;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    final Paint barPaint = Paint()
      ..color = DeanTheme.primaryBlue
      ..style = PaintingStyle.fill;

    final Paint linePaint = Paint()
      ..color = DeanTheme.successGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final Paint dotPaint = Paint()
      ..color = DeanTheme.successGreen
      ..style = PaintingStyle.fill;

    final Paint dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw horizontal grid lines (0%, 20%, 40%, 60%, 80%, 100%)
    for (int i = 0; i <= 5; i++) {
      final double y = topPadding + (chartHeight / 5) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${100 - i * 20}%',
          style: const TextStyle(fontSize: 9, color: DeanTheme.textMuted),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 6, y - textPainter.height / 2));
    }

    final List<Offset> linePoints = [];

    // Draw bars & compute line positions
    for (int i = 0; i < barCount; i++) {
      final item = depts[i];
      final double passVal = double.tryParse(item['pass'].toString()) ?? 0.0;
      final double sgpaVal = double.tryParse(item['sgpa'].toString()) ?? 0.0;

      final double centerX = leftPadding + (i * groupWidth) + (groupWidth / 2);
      final double barLeft = centerX - (barWidth / 2);

      // Pass % Bar (0 to 100%)
      final double barHeight = (passVal / 100.0) * chartHeight;
      final double barTop = topPadding + (chartHeight - barHeight);

      final RRect barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(barLeft, barTop, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(barRect, barPaint);

      // Value label on top of bar
      if (passVal > 0) {
        final valText = TextPainter(
          text: TextSpan(
            text: '${passVal.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
          ),
          textDirection: TextDirection.ltr,
        );
        valText.layout();
        valText.paint(canvas, Offset(centerX - (valText.width / 2), barTop - valText.height - 2));
      }

      // SGPA Line point (0 to 10 scale)
      final double lineY = topPadding + (chartHeight - ((sgpaVal / 10.0) * chartHeight));
      linePoints.add(Offset(centerX, lineY));

      // Department Code Label below X Axis
      final deptText = TextPainter(
        text: TextSpan(
          text: item['code'].toString(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
        ),
        textDirection: TextDirection.ltr,
      );
      deptText.layout();
      deptText.paint(canvas, Offset(centerX - (deptText.width / 2), topPadding + chartHeight + 8));
    }

    // Draw SGPA Line
    if (linePoints.length > 1) {
      final Path path = Path();
      path.moveTo(linePoints[0].dx, linePoints[0].dy);
      for (int i = 1; i < linePoints.length; i++) {
        path.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Draw SGPA Dots
    for (final pt in linePoints) {
      canvas.drawCircle(pt, 4, dotPaint);
      canvas.drawCircle(pt, 4, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ComboChartPainter oldDelegate) => true;
}
