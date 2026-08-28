import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_state.dart';
import '../widgets/bento_card.dart';

class AcademicApprovalsScreen extends StatefulWidget {
  const AcademicApprovalsScreen({super.key});

  @override
  State<AcademicApprovalsScreen> createState() => _AcademicApprovalsScreenState();
}

class _AcademicApprovalsScreenState extends State<AcademicApprovalsScreen> {
  final Map<String, TextEditingController> _remarkControllers = {};

  @override
  void dispose() {
    for (final controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateApprovalStatus(
    BuildContext context,
    DeanAppState appState,
    String rowKey,
    String status,
  ) async {
    final approval = appState.approvalsData.firstWhere(
      (item) => _resolveId(item) == rowKey,
      orElse: () => <String, dynamic>{},
    );
    if (approval.isEmpty) return;

    final remark = (_remarkControllers[rowKey]?.text ?? '').trim();
    if (remark.isNotEmpty) approval['remarks'] = remark;

    if (status == 'APPROVED') {
      await appState.approveRequest(rowKey);
    } else {
      await appState.rejectRequest(rowKey);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Request $rowKey marked as $status.'),
      backgroundColor: status == 'APPROVED' ? DeanTheme.successGreen : DeanTheme.dangerRose,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _saveRemark(BuildContext context, DeanAppState appState, String rowKey) {
    final remark = (_remarkControllers[rowKey]?.text ?? '').trim();
    if (remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a remark before saving.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final approval = appState.approvalsData.firstWhere(
      (item) => _resolveId(item) == rowKey,
      orElse: () => <String, dynamic>{},
    );
    if (approval.isNotEmpty) {
      approval['remarks'] = remark;
      setState(() {});
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Remark saved.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  String _resolveId(Map<String, dynamic> row) =>
      (row['request_id'] ?? row['display_id'] ?? row['id'] ?? '').toString();

  String _str(Map<String, dynamic> row, List<String> keys, String fallback) {
    for (final key in keys) {
      final val = row[key];
      if (val != null && val.toString().trim().isNotEmpty) return val.toString().trim();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final approvals = appState.approvalsData;

        final pendingCount = approvals
            .where((a) => (a['status'] ?? '').toString().toUpperCase() == 'PENDING')
            .length;
        final hodLeaveCount = approvals
            .where((a) =>
                (a['status'] ?? '').toString().toUpperCase() == 'PENDING' &&
                (a['type'] ?? '').toString().toLowerCase().contains('leave'))
            .length;
        final courseAllocCount = approvals
            .where((a) =>
                (a['status'] ?? '').toString().toUpperCase() == 'PENDING' &&
                (a['type'] ?? '').toString().toLowerCase().contains('course'))
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Queue summary cards ──────────────────────────────────────
              Row(children: [
                Expanded(child: _queueCard('Faculty Profile Approvals', '$pendingCount Pending',
                    'Requires Document Verification', Icons.person_outline, DeanTheme.primaryBlue)),
                const SizedBox(width: 14),
                Expanded(child: _queueCard('HOD Leave Applications', '$hodLeaveCount Pending',
                    'Executive Approval Required', Icons.time_to_leave, DeanTheme.warningAmber)),
                const SizedBox(width: 14),
                Expanded(child: _queueCard('Course Allocation Requests', '$courseAllocCount Pending',
                    'Cross-Dept Handling', Icons.apps_outlined, DeanTheme.infoPurple)),
              ]),
              const SizedBox(height: 20),

              // ── Approvals table ──────────────────────────────────────────
              BentoCard(
                title: 'Approve Academic Workflows',
                child: _buildBody(context, appState, approvals),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    DeanAppState appState,
    List<Map<String, dynamic>> approvals,
  ) {
    if (appState.isLoading && !appState.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading approvals from Supabase…', style: TextStyle(color: DeanTheme.textMuted)),
        ])),
      );
    }
    if (appState.lastError != null && approvals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Unable to load approvals: ${appState.lastError}',
            style: const TextStyle(color: DeanTheme.dangerRose)),
      );
    }
    if (approvals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('No pending academic approvals in Supabase database.',
            style: TextStyle(fontSize: 14, color: DeanTheme.textMuted))),
      );
    }

    // ── Column header row ────────────────────────────────────────────────
    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeanTheme.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sticky header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: DeanTheme.bgCanvas,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DeanTheme.cardBorder),
          ),
          child: const Row(children: [
            SizedBox(width: 160, child: Text('Request ID & Type', style: headerStyle)),
            SizedBox(width: 16),
            SizedBox(width: 140, child: Text('Applicant / Dept', style: headerStyle)),
            SizedBox(width: 16),
            SizedBox(width: 90,  child: Text('Date', style: headerStyle)),
            SizedBox(width: 16),
            SizedBox(width: 220, child: Text('Summary & Remarks', style: headerStyle)),
            SizedBox(width: 16),
            SizedBox(width: 210, child: Text('Action & Status', style: headerStyle)),
          ]),
        ),
        const SizedBox(height: 8),

        // Data rows — each a card, not a DataTable cell, so height is unconstrained
        ...approvals.map((a) => _approvalCard(context, appState, a)),
      ],
    );
  }

  Widget _approvalCard(
    BuildContext context,
    DeanAppState appState,
    Map<String, dynamic> approval,
  ) {
    final rowKey    = _resolveId(approval).isNotEmpty ? _resolveId(approval) : '—';
    final type      = _str(approval, ['type'], '—');
    final name      = _str(approval, ['applicant_name', 'faculty_name'], '—');
    final dept      = _str(approval, ['department', 'dept'], '—');
    final dateRaw   = _str(approval, ['created_at', 'approved_at', 'updated_at'], '');
    final date      = dateRaw.isNotEmpty ? dateRaw.split('T').first : '—';
    final summary   = _str(approval, ['summary', 'description', 'hod_remarks', 'remarks'], '—');
    final status    = _str(approval, ['status'], 'PENDING');

    final controller = _remarkControllers.putIfAbsent(
      rowKey,
      () => TextEditingController(text: _str(approval, ['remarks', 'hod_remarks'], '')),
    );

    final statusUpper = status.toUpperCase();
    final statusColor = switch (statusUpper) {
      'APPROVED' => DeanTheme.successGreen,
      'REJECTED' => DeanTheme.dangerRose,
      _           => DeanTheme.primaryBlue,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DeanTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Col 1: Request ID & Type ─────────────────────────────────
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rowKey,
                    style: const TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 11, color: DeanTheme.warningAmber)),
                const SizedBox(height: 4),
                Text(type,
                    style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Col 2: Applicant / Dept ──────────────────────────────────
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 4),
                Text(dept,
                    style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Col 3: Date ──────────────────────────────────────────────
          SizedBox(
            width: 90,
            child: Text(date, style: const TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: 16),

          // ── Col 4: Summary & Remark input ────────────────────────────
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Add remarks…',
                    hintStyle: const TextStyle(fontSize: 11),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => _saveRemark(context, appState, rowKey),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.note_alt_outlined, size: 13),
                  label: const Text('Save Remark', style: TextStyle(fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ── Col 5: Action & Status ───────────────────────────────────
          SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                  ),
                  child: Text(statusUpper,
                      style: TextStyle(
                          color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                // Approve button (full width)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: statusUpper == 'APPROVED'
                        ? null
                        : () => _updateApprovalStatus(context, appState, rowKey, 'APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DeanTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Approve', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 6),

                // Reject button (full width)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: statusUpper == 'REJECTED'
                        ? null
                        : () => _updateApprovalStatus(context, appState, rowKey, 'REJECTED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DeanTheme.dangerRose,
                      side: BorderSide(
                          color: statusUpper == 'REJECTED'
                              ? DeanTheme.cardBorder
                              : DeanTheme.dangerRose),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 14),
                    label: const Text('Reject', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueCard(
      String title, String count, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeanTheme.cardBorder),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
          Text(count,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
        ])),
      ]),
    );
  }
}
