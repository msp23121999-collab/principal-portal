import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class ProgrammesCoursesScreen extends StatelessWidget {
  const ProgrammesCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final subjects = appState.subjectsData;

    return DefaultTabController(
      length: 4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs for Program Categories
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: DeanTheme.cardBorder)),
              child: const TabBar(
                labelColor: DeanTheme.primaryBlue,
                unselectedLabelColor: DeanTheme.textMuted,
                indicatorColor: DeanTheme.primaryBlue,
                tabs: [
                  Tab(text: 'Undergraduate (B.E. / B.Tech)'),
                  Tab(text: 'Postgraduate (M.E. / M.Tech)'),
                  Tab(text: 'MBA / MCA'),
                  Tab(text: 'Ph.D. Research Programs'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Course Catalog Table
            BentoCard(
              title: 'Master Course Catalog & Allocation Master List',
              child: subjects.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No course subjects found in Supabase (public.subjects).',
                          style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Course Code', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Course Title', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Semester', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Course Type', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Credits', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Allocated Faculty', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: subjects.map((s) {
                          final code = (s['code'] ?? s['subject_code'] ?? '—').toString();
                          final title = (s['name'] ?? s['subject_name'] ?? 'Course Title').toString();
                          final dept = (s['department_code'] ?? s['department'] ?? '—').toString();
                          final sem = (s['semester'] != null) ? 'Semester ${s['semester']}' : '—';
                          final type = (s['type'] ?? 'Theory').toString();
                          final credits = (s['credits'] ?? '0').toString();
                          final faculty = (s['faculty_assigned'] ?? 'Unassigned').toString();
                          return _buildCatalogRow(code, title, dept, sem, type, credits, faculty);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildCatalogRow(String code, String title, String dept, String sem, String type, String credits, String faculty) {
    return DataRow(
      cells: [
        DataCell(Text(code, style: const TextStyle(fontWeight: FontWeight.bold, color: DeanTheme.primaryBlue))),
        DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(dept)),
        DataCell(Text(sem)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
          child: Text(type, style: const TextStyle(color: DeanTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        DataCell(Text(credits, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(faculty, style: const TextStyle(color: DeanTheme.successGreen, fontWeight: FontWeight.bold))),
      ],
    );
  }
}
