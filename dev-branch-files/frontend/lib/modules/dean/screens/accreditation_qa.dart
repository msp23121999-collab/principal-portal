import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';

class AccreditationQaScreen extends StatefulWidget {
  const AccreditationQaScreen({super.key});

  @override
  State<AccreditationQaScreen> createState() => _AccreditationQaScreenState();
}

class _AccreditationQaScreenState extends State<AccreditationQaScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          // NAAC 7 Criteria Scores Matrix
          BentoCard(
            title: 'NAAC 7 Criteria Self-Assessment Score Breakdown (Out of 4.00)',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCriteriaCard('Crit 1: Curricular Aspects', '3.82', 0.95, DeanTheme.successGreen),
                _buildCriteriaCard('Crit 2: Teaching-Learning & Eval', '3.65', 0.91, DeanTheme.successGreen),
                _buildCriteriaCard('Crit 3: Research & Extension', '3.42', 0.85, DeanTheme.primaryBlue),
                _buildCriteriaCard('Crit 4: Infrastructure & Learning', '3.90', 0.97, DeanTheme.successGreen),
                _buildCriteriaCard('Crit 5: Student Support', '3.75', 0.93, DeanTheme.successGreen),
                _buildCriteriaCard('Crit 6: Governance & Leadership', '3.80', 0.95, DeanTheme.successGreen),
                _buildCriteriaCard('Crit 7: Institutional Values', '3.88', 0.97, DeanTheme.successGreen),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Document Audit Verification Checklist Table
          BentoCard(
            title: 'Accreditation Document Verification Master List',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Criterion Code & Description', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Responsible Dept', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Submitted Files', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Audit Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: [
                  _buildDocumentRow(appState, 'REQ-903', 'Crit 1.1.2 BoS Minutes & Syllabus Proofs', 'Academic Cell', '28 PDFs Uploaded', 'Verified'),
                  _buildDocumentRow(appState, 'REQ-904', 'Crit 2.3.1 Student-Faculty Ratio & Load Proofs', 'IQAC / Dean Office', '14 Files Uploaded', 'Verified'),
                  _buildDocumentRow(appState, 'DOC-001', 'Crit 3.1.3 Funded Research Project Grants', 'Research Cell', '42 Proofs Uploaded', 'Pending Verification'),
                  _buildDocumentRow(appState, 'REQ-901', 'Crit 5.2.1 Student Placement Certificates', 'Placement Cell', '650 Proofs Uploaded', 'Verified'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaCard(String name, String score, double pct, Color col) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: DeanTheme.bgCanvas, borderRadius: BorderRadius.circular(12), border: Border.all(color: DeanTheme.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(score, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: col)),
              Text('${(pct * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pct, backgroundColor: const Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(col)),
        ],
      ),
    );
  }

  DataRow _buildDocumentRow(DeanAppState appState, String docId, String desc, String dept, String files, String defaultStatus) {
    // Find the actual status from approvalsData
    String currentStatus = defaultStatus;
    for (final approval in appState.approvalsData) {
      if (approval['id'] == docId || approval['request_id'] == docId) {
        currentStatus = approval['status'] ?? defaultStatus;
        break;
      }
    }

    final Color statusColor = currentStatus == 'Verified' ? DeanTheme.successGreen : DeanTheme.warningAmber;
    final displayStatus = currentStatus == 'Verified' ? 'Verified' : 'Pending Verification';

    return DataRow(
      cells: [
        DataCell(Text(desc, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(dept)),
        DataCell(Text(files)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(displayStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        DataCell(
          currentStatus == 'Verified'
              ? Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: DeanTheme.successGreen))
              : OutlinedButton(
                  onPressed: () {
                    appState.verifyDocument(docId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document verified successfully!'),
                        backgroundColor: Color.fromARGB(255, 34, 197, 94),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero),
                  child: const Text('Verify Document', style: TextStyle(fontSize: 10)),
                ),
        ),
      ],
    );
  }

  DataRow _buildAuditRow(String desc, String dept, String files, String status, Color col) {
    return DataRow(
      cells: [
        DataCell(Text(desc, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(dept)),
        DataCell(Text(files)),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: col.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          child: Text(status, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold)),
        )),
        DataCell(OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), minimumSize: Size.zero),
          child: const Text('Verify Document', style: TextStyle(fontSize: 10)),
        )),
      ],
    );
  }
}
