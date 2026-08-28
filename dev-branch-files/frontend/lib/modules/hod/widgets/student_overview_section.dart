import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../theme.dart';

class StudentOverviewSection extends StatelessWidget {
  final StudentOverviewSummary summary;

  const StudentOverviewSection({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.people_alt_rounded,
                  color: AppTheme.accentGreen,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Student Demographics & Compliance Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Total Enrolled: ${summary.totalStudents} Students',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Year Distribution Cards Grid
        Row(
          children: [
            Expanded(child: _buildYearBadge('1st Year', '${summary.year1Count} Students', AppTheme.accentBlue)),
            const SizedBox(width: 10),
            Expanded(child: _buildYearBadge('2nd Year', '${summary.year2Count} Students', AppTheme.accentGreen)),
            const SizedBox(width: 10),
            Expanded(child: _buildYearBadge('3rd Year', '${summary.year3Count} Students', AppTheme.accentPurple)),
            const SizedBox(width: 10),
            Expanded(child: _buildYearBadge('4th Year', '${summary.year4Count} Students', AppTheme.accentOrange)),
          ],
        ),
        const SizedBox(height: 16),

        // Compliance Alert Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;

            final children = [
              _buildAlertCard(
                title: 'Low Attendance Alert',
                countText: '${summary.lowAttendanceCount} Students < 75%',
                icon: Icons.warning_amber_rounded,
                color: AppTheme.accentRose,
                bgColor: AppTheme.badgeRedBg,
              ),
              _buildAlertCard(
                title: 'Fee Status Defaulters',
                countText: '${summary.feeDefaultersCount} Pending Dues',
                icon: Icons.monetization_on_outlined,
                color: AppTheme.accentAmber,
                bgColor: AppTheme.badgeOrangeBg,
              ),
              _buildAlertCard(
                title: 'Students on Leave Today',
                countText: '${summary.onLeaveToday} Approved Leaves',
                icon: Icons.beach_access_outlined,
                color: AppTheme.accentBlue,
                bgColor: AppTheme.badgeBlueBg,
              ),
              _buildAlertCard(
                title: 'Exam Eligibility Rate',
                countText: '${summary.examEligiblePct}% Eligible',
                icon: Icons.verified_outlined,
                color: AppTheme.accentGreen,
                bgColor: AppTheme.badgeGreenBg,
              ),
            ];

            if (isNarrow) {
              return Column(
                children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList(),
              );
            }

            return Row(
              children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 10), child: c))).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearBadge(String yearLabel, String countLabel, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(yearLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(countLabel, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String countText,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(countText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
