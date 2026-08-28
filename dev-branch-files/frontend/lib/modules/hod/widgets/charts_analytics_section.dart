import 'package:flutter/material.dart';
import '../theme.dart';

class ChartsAnalyticsSection extends StatelessWidget {
  const ChartsAnalyticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: AppTheme.accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Department Analytics & Academic Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isWide)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _AttendanceTrendCard()),
                  SizedBox(width: 16),
                  Expanded(flex: 4, child: _SyllabusCompletionCard()),
                ],
              )
            else ...[
              const _AttendanceTrendCard(),
              const SizedBox(height: 16),
              const _SyllabusCompletionCard(),
            ],
          ],
        );
      },
    );
  }
}

class _AttendanceTrendCard extends StatelessWidget {
  const _AttendanceTrendCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview & Monthly Trends',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time student & faculty attendance tracking',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.badgeGreenBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Overall 94.2%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.badgeGreenText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Faculty Attendance Progress
          _buildProgressRow(
            label: 'Faculty Attendance Today',
            valueText: '22 / 24 (91.6%)',
            pct: 0.916,
            color: AppTheme.accentBlue,
          ),
          const SizedBox(height: 14),

          // Student Attendance Progress
          _buildProgressRow(
            label: 'Student Attendance Today',
            valueText: '452 / 480 (94.1%)',
            pct: 0.941,
            color: AppTheme.accentGreen,
          ),
          const SizedBox(height: 14),

          // Semester Pass Percentage
          _buildProgressRow(
            label: 'Previous Semester Pass Rate',
            valueText: '96.4% Passed',
            pct: 0.964,
            color: AppTheme.accentPurple,
          ),
          const SizedBox(height: 18),

          // Month Comparison Chart Bars (Visual representation)
          const Text(
            'Monthly Student Attendance Comparison',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMonthBar('Feb', 0.88, Colors.blue.shade300),
              _buildMonthBar('Mar', 0.91, Colors.blue.shade400),
              _buildMonthBar('Apr', 0.89, Colors.blue.shade300),
              _buildMonthBar('May', 0.94, Colors.blue.shade600),
              _buildMonthBar('Jun', 0.96, AppTheme.accentGreen),
              _buildMonthBar('Jul', 0.94, AppTheme.accentBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required String valueText,
    required double pct,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
            Text(valueText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthBar(String month, double pct, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 60 * pct,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(month, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _SyllabusCompletionCard extends StatelessWidget {
  const _SyllabusCompletionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Syllabus & Course Progress',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Curriculum coverage and lesson diary status',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // Circular Ring Indicators Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressRing('Syllabus', '78%', 0.78, AppTheme.accentGreen),
              _buildProgressRing('Lesson Plan', '84%', 0.84, AppTheme.accentBlue),
              _buildProgressRing('Course Diary', '92%', 0.92, AppTheme.accentPurple),
            ],
          ),
          const SizedBox(height: 20),

          // Course Status Items
          _buildCourseProgressItem('IOT2028: Sensors & Actuators', 'Unit 4 of 5 Completed', 0.80),
          const SizedBox(height: 10),
          _buildCourseProgressItem('IOT2029: Embedded C Programming', 'Unit 3 of 5 Completed', 0.65),
          const SizedBox(height: 10),
          _buildCourseProgressItem('IOT2030: Cloud Protocols (MQTT/CoAP)', 'Unit 4 of 5 Completed', 0.85),
        ],
      ),
    );
  }

  Widget _buildProgressRing(String label, String valueText, double pct, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: pct,
                strokeWidth: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildCourseProgressItem(String title, String subtitle, double pct) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
