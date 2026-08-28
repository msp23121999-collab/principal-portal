import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class ResearchInnovationScreen extends StatelessWidget {
  const ResearchInnovationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    final projects = appState.researchProjectsData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Research KPI Cards
          Row(
            children: [
              Expanded(child: _buildResearchKpiCard('Active Sponsored Projects', '${projects.length} Projects', 'Live from Supabase', Icons.science_outlined, DeanTheme.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: _buildResearchKpiCard('Total Sanctioned Grants', '—', 'DST / AICTE / ICMR', Icons.monetization_on_outlined, DeanTheme.successGreen)),
              const SizedBox(width: 14),
              Expanded(child: _buildResearchKpiCard('Patents Published / Granted', '—', 'IPR Office', Icons.verified_user_outlined, DeanTheme.infoPurple)),
              const SizedBox(width: 14),
              Expanded(child: _buildResearchKpiCard('Scopus / WoS Papers', '—', 'Research Cell', Icons.menu_book_outlined, DeanTheme.warningAmber)),
            ],
          ),
          const SizedBox(height: 20),

          // Sponsored Projects Master Table
          BentoCard(
            title: 'Active Funded Research Projects Master List',
            child: projects.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                        'No research projects found in Supabase (public.hod_research_contributions).',
                        style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Project Title', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Principal Investigator (PI)', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Funding Agency', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Sanctioned Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Project Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: projects.map((p) {
                        final title = (p['title'] ?? p['project_title'] ?? 'Research Project').toString();
                        final pi = (p['pi_name'] ?? p['faculty_name'] ?? 'Faculty PI').toString();
                        final dept = (p['department'] ?? p['dept'] ?? '—').toString();
                        final agency = (p['funding_agency'] ?? p['agency'] ?? 'Sponsor').toString();
                        final amount = (p['amount'] ?? p['sanctioned_amount'] ?? '—').toString();
                        final status = (p['status'] ?? 'Active').toString();
                        return _buildProjectRow(title, pi, dept, agency, amount, status, DeanTheme.primaryBlue);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchKpiCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DeanTheme.cardBorder)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
                Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                Text(sub, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildProjectRow(String title, String pi, String dept, String agency, String amount, String status, Color col) {
    return DataRow(
      cells: [
        DataCell(Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(pi)),
        DataCell(Text(dept)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
          child: Text(agency, style: const TextStyle(color: DeanTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        DataCell(Text(amount, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}
