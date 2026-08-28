import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class ExaminationManagementScreen extends StatelessWidget {
  const ExaminationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final signoffs = appState.examinationSignoffsData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Examination Process Pipeline
          BentoCard(
            title: 'End-Semester Examination Workflow Pipeline',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPipelineStep('1. Question Banks', 'Database Sync', Icons.cloud_upload_outlined, DeanTheme.successGreen),
                const Icon(Icons.arrow_forward, color: DeanTheme.cardBorder),
                _buildPipelineStep('2. CIA 1 & CIA 2', 'Student Marks', Icons.fact_check_outlined, DeanTheme.successGreen),
                const Icon(Icons.arrow_forward, color: DeanTheme.cardBorder),
                _buildPipelineStep('3. End-Sem Exams', 'In Progress', Icons.edit_calendar, DeanTheme.primaryBlue),
                const Icon(Icons.arrow_forward, color: DeanTheme.cardBorder),
                _buildPipelineStep('4. Mark Moderation', 'Pending Sign-off', Icons.find_in_page_outlined, DeanTheme.warningAmber),
                const Icon(Icons.arrow_forward, color: DeanTheme.cardBorder),
                _buildPipelineStep('5. Dean Sign-off', '${signoffs.length} Pending', Icons.approval_outlined, DeanTheme.dangerRose),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Department Mark Sheet Verification Table
          BentoCard(
            title: 'Department Mark Sheet Status & Moderation List',
            child: signoffs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No examination signoffs found in Supabase (dean.dean_examination_signoffs).',
                        style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Exam Session', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total Subjects', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Verified Mark Sheets', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Moderation Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Dean Action', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: signoffs.map((s) {
                        final id = (s['id'] ?? '').toString();
                        final dept = (s['department'] ?? s['dept'] ?? 'Department').toString();
                        final session = (s['exam_session'] ?? 'Current Session').toString();
                        final totalSubjects = '${s['total_subjects'] ?? 0} Subjects';
                        final verified = '${s['verified_mark_sheets'] ?? 0} / ${s['total_subjects'] ?? 0} Verified';
                        final status = (s['status'] ?? 'PENDING').toString();
                        return _buildExamRow(context, appState, id, dept, session, totalSubjects, verified, status, DeanTheme.primaryBlue);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep(String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
          Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  DataRow _buildExamRow(BuildContext context, DeanAppState appState, String id, String dept, String session, String subjects, String verified, String status, Color col) {
    final isSignedOff = status.toUpperCase() == 'PASSED' || status.toUpperCase() == 'APPROVED' || status.toUpperCase() == 'SIGNED_OFF';

    return DataRow(
      cells: [
        DataCell(Text(dept, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(session)),
        DataCell(Text(subjects)),
        DataCell(Text(verified, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: (isSignedOff ? DeanTheme.successGreen : col).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(isSignedOff ? 'PASSED & PUBLISHED' : status, style: TextStyle(color: isSignedOff ? DeanTheme.successGreen : col, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        DataCell(ElevatedButton(
          onPressed: isSignedOff || id.isEmpty
              ? null
              : () async {
                  final payload = {
                    'status': 'PASSED',
                    'published': true,
                    'published_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  };
                  print('[DEAN TRACE] UPDATE dean.dean_examination_signoffs id: $id');
                  final res = await DeanSupabaseService.instance.updateExaminationSignoff(id, payload);
                  print('[DEAN TRACE] UPDATE dean.dean_examination_signoffs success: ${res != null}');
                  if (res != null) {
                    await appState.fetchAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Examination sign-off for $dept saved to Supabase!'), backgroundColor: DeanTheme.successGreen),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update sign-off in Supabase.'), backgroundColor: DeanTheme.dangerRose),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSignedOff ? Colors.grey : col,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: Text(isSignedOff ? 'Signed Off' : 'Sign Off & Publish', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}
