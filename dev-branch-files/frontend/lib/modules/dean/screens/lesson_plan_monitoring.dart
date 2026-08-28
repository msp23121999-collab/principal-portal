import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class LessonPlanMonitoringScreen extends StatelessWidget {
  const LessonPlanMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final diaryEntries = appState.courseDiaryData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coverage Cards
          Row(
            children: [
              Expanded(child: _buildCoverageCard('Course Diary Entries', '${diaryEntries.length}', 'Live from Supabase', DeanTheme.successGreen)),
              const SizedBox(width: 14),
              Expanded(child: _buildCoverageCard('Approved by HODs', '—', 'HOD Sign-off', DeanTheme.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: _buildCoverageCard('Pending HOD Approval', '—', 'Action Required', DeanTheme.warningAmber)),
              const SizedBox(width: 14),
              Expanded(child: _buildCoverageCard('Syllabus Lagging (>1 Wk)', '—', 'Remedial Classes', DeanTheme.dangerRose)),
            ],
          ),
          const SizedBox(height: 20),

          // Syllabus Coverage Master Table
          BentoCard(
            title: 'Syllabus Unit Coverage & Course Diary Tracker',
            child: diaryEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No course diary records found in Supabase (public.hod_course_diaries).',
                        style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Subject Code & Title', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Faculty Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Planned vs Completed', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Syllabus Coverage', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('HOD Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: diaryEntries.map((d) {
                        final subject = (d['subject_name'] ?? d['subject_code'] ?? 'Subject').toString();
                        final faculty = (d['faculty_name'] ?? 'Faculty').toString();
                        final dept = (d['department'] ?? '—').toString();
                        final hours = '${d['completed_hours'] ?? 0} / ${d['planned_hours'] ?? 0} Hrs';
                        final double pct = (d['planned_hours'] != null && d['planned_hours'] > 0)
                            ? ((d['completed_hours'] ?? 0) / d['planned_hours']).toDouble()
                            : 0.0;
                        final status = (d['status'] ?? 'Submitted').toString();
                        return _buildCoverageRow(subject, faculty, dept, hours, pct, status, DeanTheme.primaryBlue);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageCard(String title, String main, String sub, Color col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DeanTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
          const SizedBox(height: 4),
          Text(main, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: col)),
          Text(sub, style: TextStyle(fontSize: 10, color: col, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  DataRow _buildCoverageRow(String subject, String faculty, String dept, String hours, double pct, String status, Color col) {
    return DataRow(
      cells: [
        DataCell(Text(subject, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(faculty)),
        DataCell(Text(dept)),
        DataCell(Text(hours, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(SizedBox(
          width: 140,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${(pct * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: col)),
              const SizedBox(height: 2),
              LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(col)),
            ],
          ),
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}
