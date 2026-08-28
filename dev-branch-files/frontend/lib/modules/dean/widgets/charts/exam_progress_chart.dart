import 'package:flutter/material.dart';
import 'dart:math';
import '../../theme.dart';

class ExaminationStatusProgressChart extends StatelessWidget {
  final List<Map<String, dynamic>>? markSheetsData;
  final int totalDeptsCount;

  const ExaminationStatusProgressChart({
    super.key,
    this.markSheetsData,
    this.totalDeptsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    int ciaCompleted = 0;
    int semCompleted = 0;
    int resultsPublished = 0;
    int resultsPending = 0;

    if (markSheetsData != null && markSheetsData!.isNotEmpty) {
      for (final item in markSheetsData!) {
        final type = (item['assessment_type'] ?? '').toString();
        final status = (item['status'] ?? '').toString();

        if (type.contains('CIA') && status == 'Submitted') ciaCompleted++;
        if (type.contains('End') || type.contains('Sem')) {
          if (status == 'Submitted' || status == 'Approved') semCompleted++;
        }
        if (status == 'Approved' || status == 'Published') resultsPublished++;
        if (status == 'Draft' || status == 'Pending') resultsPending++;
      }
    }

    final int targetDepts = totalDeptsCount > 0 ? totalDeptsCount : 28;

    // Progress percentage
    final double overallProgressPct = markSheetsData != null && markSheetsData!.isNotEmpty
        ? ((ciaCompleted + semCompleted) / (targetDepts * 2)).clamp(0.0, 1.0)
        : 0.0;

    final String progressText = '${(overallProgressPct * 100).toStringAsFixed(0)}%';

    return Row(
      children: [
        // Radial Progress Meter
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(130, 130),
                painter: _RadialProgressPainter(progress: overallProgressPct),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_turned_in, size: 18, color: DeanTheme.primaryBlue),
                  const SizedBox(height: 2),
                  Text(
                    progressText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DeanTheme.textDark,
                    ),
                  ),
                  const Text(
                    'Overall Progress',
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

        // Status Breakdown List
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildExamStatusRow('CIA Examinations', '$ciaCompleted / $targetDepts', ciaCompleted > 0 ? 'In Progress' : 'Pending', DeanTheme.successGreen),
              const SizedBox(height: 6),
              _buildExamStatusRow('Semester Examinations', '$semCompleted / $targetDepts', semCompleted > 0 ? 'In Progress' : 'Pending', DeanTheme.primaryBlue),
              const SizedBox(height: 6),
              _buildExamStatusRow('Results Published', '$resultsPublished / $targetDepts', resultsPublished > 0 ? 'Completed' : 'Pending', DeanTheme.successGreen),
              const SizedBox(height: 6),
              _buildExamStatusRow('Results Pending', '$resultsPending / $targetDepts', 'Pending', DeanTheme.warningAmber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamStatusRow(String title, String count, String statusTag, Color statusColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
              Text(statusTag, style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark),
        ),
      ],
    );
  }
}

class _RadialProgressPainter extends CustomPainter {
  final double progress;

  _RadialProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 10.0;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final Paint progressPaint = Paint()
      ..color = DeanTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * pi, false, bgPaint);

    if (progress > 0) {
      canvas.drawArc(rect, -pi / 2, progress * 2 * pi, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialProgressPainter oldDelegate) => true;
}
