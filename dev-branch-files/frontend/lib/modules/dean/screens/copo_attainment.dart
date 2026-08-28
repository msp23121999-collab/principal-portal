import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class CopoAttainmentScreen extends StatelessWidget {
  const CopoAttainmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attainment KPI Summary Cards
          Row(
            children: [
              Expanded(child: _buildOBEKpiCard('Overall PO Attainment', '— / 3.0', 'Target: 2.50', Icons.analytics, DeanTheme.successGreen)),
              const SizedBox(width: 14),
              Expanded(child: _buildOBEKpiCard('Direct Attainment (Exams)', '— / 3.0', 'Weightage: 80%', Icons.fact_check_outlined, DeanTheme.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: _buildOBEKpiCard('Indirect (Exit Surveys)', '— / 3.0', 'Weightage: 20%', Icons.poll_outlined, DeanTheme.warningAmber)),
              const SizedBox(width: 14),
              Expanded(child: _buildOBEKpiCard('NBA Compliant Depts', '—', 'Tier-1 Standards', Icons.verified_outlined, DeanTheme.infoPurple)),
            ],
          ),
          const SizedBox(height: 20),

          // Department CO-PO Attainment Data Table
          BentoCard(
            title: 'Department Program Outcome (PO1 - PO12) Attainment Matrix',
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'CO-PO Attainment calculation engine is not currently configured with a dedicated Supabase database table.',
                  style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOBEKpiCard(String title, String val, String sub, IconData icon, Color color) {
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

  DataRow _buildCopoRow(String dept, String p1, String p2, String p3, String composite, String level, Color col) {
    return DataRow(
      cells: [
        DataCell(Text(dept, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(p1)),
        DataCell(Text(p2)),
        DataCell(Text(p3)),
        DataCell(Text(composite, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(level, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }
}
