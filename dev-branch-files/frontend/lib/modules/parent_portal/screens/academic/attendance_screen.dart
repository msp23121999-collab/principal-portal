import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../models/models.dart';

/// Attendance screen for the Parent Portal.
///
/// Sections:
///   A. My Child's Attendance — overall %
///   B. Subject-wise Attendance — per subject breakdown
///   C. Period-wise Attendance — date / period / subject / status table
///   D. Class Attendance — whole-class stats (separate from child's data)
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendance = MockData.mockAttendance;
    final classAtt = MockData.mockClassAttendance;
    final periods = MockData.mockPeriodAttendance;
    final student = MockData.singleStudent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── A. My Child's Attendance ─────────────────────────────────
            _childSectionHeader('My Child\'s Attendance',
                '${student.name} • ${student.registerNumber}'),
            const SizedBox(height: 12),
            _buildChildOverall(attendance),
            const SizedBox(height: 24),

            // ── B. Subject-wise Attendance ───────────────────────────────
            const SectionHeader(title: 'Subject-wise Attendance'),
            const SizedBox(height: 8),
            _buildSubjectList(attendance),
            const SizedBox(height: 24),

            // ── C. Period-wise Attendance ────────────────────────────────
            const SectionHeader(title: 'Period-wise Attendance'),
            const SizedBox(height: 8),
            _buildPeriodTable(periods),
            const SizedBox(height: 28),

            // ── D. Class Attendance (separate) ───────────────────────────
            _classSectionHeader(),
            const SizedBox(height: 12),
            _buildClassAttendance(classAtt),
          ],
        ),
      ),
    );
  }

  // ─── Section label helpers ───────────────────────────────────────────────

  Widget _childSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _classSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text('Class Attendance',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text('Class-level data — not your child\'s',
              style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF8B5CF6),
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // ─── A. Child Overall Attendance ────────────────────────────────────────

  Widget _buildChildOverall(Attendance att) {
    final pct = att.overallPercentage;
    final isGood = pct >= 85;
    final color = isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular gauge — 130×130 gives enough inner space for readable text
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                SizedBox(
                  width: 130,
                  height: 130,
                  child: CircularProgressIndicator(
                    value: pct / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade100,
                    color: color,
                  ),
                ),
                // Inner text — constrained to fit safely inside the stroke ring
                SizedBox(
                  width: 90,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$pct%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: color,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const Text(
                        'Overall',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow(Icons.check_circle_rounded, 'Total Present',
                    att.totalPresent.toString(), const Color(0xFF10B981)),
                const SizedBox(height: 14),
                _statRow(Icons.cancel_rounded, 'Total Absent',
                    att.totalAbsent.toString(), const Color(0xFFEF4444)),
                const SizedBox(height: 14),
                _statRow(Icons.info_outline_rounded,
                    'Minimum Required', '85%',
                    isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500))),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: color)),
      ],
    );
  }

  // ─── B. Subject-wise Attendance ─────────────────────────────────────────

  Widget _buildSubjectList(Attendance att) {
    return Column(
      children: att.subjectAttendance.map((s) {
        final isGood = s.percentage >= 85;
        final barColor =
            isGood ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(s.subject,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.textPrimary)),
                    ),
                    Text('${s.percentage}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: barColor)),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.percentage / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade100,
                    color: barColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _subjectStat('Present', s.present.toString(),
                        const Color(0xFF10B981)),
                    const SizedBox(width: 24),
                    _subjectStat(
                        'Absent', s.absent.toString(), const Color(0xFFEF4444)),
                    const Spacer(),
                    StatusBadge(status: s.status),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _subjectStat(String label, String value, Color color) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── C. Period-wise Attendance Table ────────────────────────────────────

  Widget _buildPeriodTable(List<PeriodAttendance> records) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            color: const Color(0xFF1A3C6E),
            child: Row(
              children: const [
                Expanded(flex: 3, child: _TH('Date')),
                Expanded(flex: 1, child: _TH('Period')),
                Expanded(flex: 3, child: _TH('Subject')),
                Expanded(flex: 2, child: _TH('Status')),
              ],
            ),
          ),
          // Data rows
          ...records.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final isPresent = r.status == 'Present';
            final dateStr =
                '${r.date.day.toString().padLeft(2, '0')} ${_month(r.date.month)} ${r.date.year}';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              color: i.isEven ? Colors.white : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(dateStr,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500))),
                  Expanded(
                      flex: 1,
                      child: Text('P${r.period}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary))),
                  Expanded(
                      flex: 3,
                      child: Text(r.subject,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPresent
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPresent
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 12,
                                color: isPresent
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.status,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPresent
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── D. Class Attendance ─────────────────────────────────────────────────

  Widget _buildClassAttendance(ClassAttendance ca) {
    final pct = ca.percentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FE), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Color(0xFF8B5CF6)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'This shows the attendance for the entire class section — not your child\'s individual attendance.',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats grid
          Row(
            children: [
              Expanded(
                  child: _classStatCard('Class Strength',
                      ca.classStrength.toString(), Icons.groups_rounded,
                      const Color(0xFF3B82F6), const Color(0xFFEFF6FF))),
              const SizedBox(width: 12),
              Expanded(
                  child: _classStatCard('Present',
                      ca.presentStudents.toString(),
                      Icons.check_circle_outline_rounded,
                      const Color(0xFF10B981), const Color(0xFFECFDF5))),
              const SizedBox(width: 12),
              Expanded(
                  child: _classStatCard('Absent',
                      ca.absentStudents.toString(),
                      Icons.cancel_outlined,
                      const Color(0xFFEF4444), const Color(0xFFFEF2F2))),
              const SizedBox(width: 12),
              Expanded(
                  child: _classStatCard('Class %',
                      '${pct.toStringAsFixed(1)}%',
                      Icons.bar_chart_rounded,
                      const Color(0xFF8B5CF6), const Color(0xFFF5F3FF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _classStatCard(String label, String value, IconData icon,
      Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _month(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun',
       'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

class _TH extends StatelessWidget {
  final String label;
  const _TH(this.label);

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.3));
}
