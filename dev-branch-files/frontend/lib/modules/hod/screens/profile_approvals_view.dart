import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../export_dialog_helper.dart';
import '../responsive.dart';

class ProfileApprovalsModuleView extends StatefulWidget {
  const ProfileApprovalsModuleView({super.key});

  @override
  State<ProfileApprovalsModuleView> createState() => _ProfileApprovalsModuleViewState();
}

class _ProfileApprovalsModuleViewState extends State<ProfileApprovalsModuleView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _fs = FirestoreService.instance;

  String _selectedFilter = 'All Update Requests'; // 'All Update Requests', 'Pending HOD Review', 'Verified & Approved'
  String _selectedCategory = 'Qualifications & Degrees'; // 'Qualifications & Degrees', 'Research & Publications', 'Certifications & Awards', 'All Categories'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.streamAll(_fs.profileApprovals),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final query = _searchCtrl.text.toLowerCase();

        final filtered = docs.where((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          final faculty = (data['faculty'] as String? ?? '').toLowerCase();
          final displayId = (data['displayId'] as String? ?? '').toLowerCase();
          final updateType = (data['updateType'] as String? ?? '').toLowerCase();
          final status = (data['status'] as String? ?? 'PENDING HOD');

          // Search query check
          if (query.isNotEmpty) {
            final matchesQuery = faculty.contains(query) || displayId.contains(query) || updateType.contains(query);
            if (!matchesQuery) return false;
          }

          // Filter pill check
          if (_selectedFilter == 'Pending HOD Review' && status != 'PENDING HOD') {
            return false;
          }
          if (_selectedFilter == 'Verified & Approved' && status != 'APPROVED') {
            return false;
          }

          return true;
        }).toList();

        final pendingCount = docs.where((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return data['status'] == 'PENDING HOD';
        }).length;

        final approvedCount = docs.where((d) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          return data['status'] == 'APPROVED';
        }).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. TOP BREADCRUMB HEADER ──
              HodSectionHeader(
                title: 'Profile Approvals',
                breadcrumb: 'Dashboard > Profile Approvals',
                academicYear: 'Academic Year 2025 - 2026',
              ),
              const SizedBox(height: 12),

              // ── 2. HERO BANNER CARD (Faculty Profile Verification Hub) ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF2563EB),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faculty Profile Verification Hub',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Verify faculty degree additions, research publications, certifications, and academic record updates.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Print Button
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Printing Profile Approvals Report...'),
                                backgroundColor: Color(0xFFD97706),
                              ),
                            );
                          },
                          icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFFD97706)),
                          label: const Text(
                            'Print',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEB),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        HodExportDialog.buildExportButton(
                          context,
                          onPressed: () => HodExportDialog.show(
                            context,
                            title: 'Export Profile Approvals Data',
                            subtitle: 'Select export format for Profile Approvals records:',
                            moduleName: 'Profile Approvals',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 3. FILTER CONTROLS CONTAINER CARD ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildFilterRadioPill('All Update Requests'),
                        const SizedBox(width: 8),
                        _buildFilterRadioPill('Pending HOD Review'),
                        const SizedBox(width: 8),
                        _buildFilterRadioPill('Verified & Approved'),
                        const SizedBox(width: 12),
                        // Dropdown Category Filter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              items: const [
                                DropdownMenuItem(value: 'Qualifications & Degrees', child: Text('Qualifications & Degrees')),
                                DropdownMenuItem(value: 'Research & Publications', child: Text('Research & Publications')),
                                DropdownMenuItem(value: 'Certifications & Awards', child: Text('Certifications & Awards')),
                                DropdownMenuItem(value: 'All Categories', child: Text('All Categories')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openAddModal(context, docs.length),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        'Submit Approval Request',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), // Corporate Blue
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── 4. PROFILE UPDATE REGISTER CARD ──
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Search Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF2563EB)),
                              SizedBox(width: 8),
                              Text(
                                'Profile Update Register',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 260,
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search faculty...',
                                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Metric KPI Cards Row (3 Bento Box Cards)
                      Row(
                        children: [
                          Expanded(
                            child: _buildBentoCard(
                              title: 'TOTAL REQUESTS',
                              value: '${docs.length}',
                              subtitle: 'Profile updates',
                              icon: Icons.assignment_outlined,
                              bgColor: const Color(0xFFEFF6FF),
                              borderColor: const Color(0xFFDBEAFE),
                              accentColor: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBentoCard(
                              title: 'PENDING REVIEW',
                              value: '$pendingCount',
                              subtitle: 'Awaiting verification',
                              icon: Icons.pending_actions,
                              bgColor: const Color(0xFFFFF7ED),
                              borderColor: const Color(0xFFFED7AA),
                              accentColor: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildBentoCard(
                              title: 'APPROVED UPDATES',
                              value: '$approvedCount',
                              subtitle: 'Verified by HOD',
                              icon: Icons.check_circle_outline,
                              bgColor: const Color(0xFFECFDF5),
                              borderColor: const Color(0xFFA7F3D0),
                              accentColor: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Register Roster Table (Full Width Responsive Layout)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                dataRowMaxHeight: 64,
                                columnSpacing: 28,
                                horizontalMargin: 16,
                            columns: const [
                              DataColumn(label: Text('Faculty', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Update Type', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('New Value', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Document', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: filtered.map((doc) {
                              final d = Map<String, dynamic>.from(doc.data() as Map);
                              final status = (d['status'] as String? ?? 'PENDING HOD');
                              final isApproved = status == 'APPROVED';
                              final isRejected = status == 'REJECTED';

                              return DataRow(cells: [
                                // Faculty & Request ID
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        (d['faculty'] as String?) ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        (d['displayId'] as String?) ?? '-',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Update Type
                                DataCell(
                                  Text(
                                    (d['updateType'] as String?) ?? '-',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                  ),
                                ),

                                // New Value (Highlighted Bold Green Text)
                                DataCell(
                                  Text(
                                    (d['newValue'] as String?) ?? '-',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),

                                // Document (Blue Link Text)
                                DataCell(
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Opening document: ${d['document']}')),
                                      );
                                    },
                                    child: Text(
                                      (d['document'] as String?) ?? '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                // Status Badge
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isApproved
                                          ? const Color(0xFFDCFCE7)
                                          : isRejected
                                              ? const Color(0xFFFEE2E2)
                                              : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isApproved
                                              ? Icons.check_circle
                                              : isRejected
                                                  ? Icons.cancel
                                                  : Icons.hourglass_empty,
                                          size: 14,
                                          color: isApproved
                                              ? const Color(0xFF16A34A)
                                              : isRejected
                                                  ? const Color(0xFFDC2626)
                                                  : const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isApproved
                                              ? 'APPROVED'
                                              : isRejected
                                                  ? 'REJECTED'
                                                  : 'PENDING',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isApproved
                                                ? const Color(0xFF16A34A)
                                                : isRejected
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFFD97706),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Actions
                                DataCell(
                                  status == 'PENDING HOD'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () => _openApproveModal(context, doc.id, d),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF16A34A),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                minimumSize: const Size(64, 28),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                elevation: 0,
                                              ),
                                              child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 6),
                                            OutlinedButton(
                                              onPressed: () => _openRejectModal(context, doc.id, d),
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: const Color(0xFFFEF2F2),
                                                side: const BorderSide(color: Color(0xFFFECACA)),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                minimumSize: const Size(60, 28),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              child: const Text('Reject', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isApproved ? Icons.check_circle : Icons.cancel,
                                                size: 14,
                                                color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isApproved ? 'APPROVED' : 'REJECTED',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ]);
                            }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── FILTER RADIO PILL WIDGET BUILDER ──
  Widget _buildFilterRadioPill(String title) {
    final isActive = _selectedFilter == title;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = title),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── BENTO BOX KPI CARD WIDGET BUILDER ──
  Widget _buildBentoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── MODAL DIALOGS ──
  void _openAddModal(BuildContext context, int count) {
    final facultyCtrl = TextEditingController(text: 'Prof. P. Ramya');
    final typeCtrl = TextEditingController(text: 'Research & Publications');
    final oldCtrl = TextEditingController(text: '28 Publications');
    final newCtrl = TextEditingController(text: '29 Publications (+1 IEEE Paper)');
    final docCtrl = TextEditingController(text: 'IEEE_Acceptance_Letter.pdf');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Submit Profile Update Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: facultyCtrl, decoration: const InputDecoration(labelText: 'Faculty Name *')),
                const SizedBox(height: 10),
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Update Type *')),
                const SizedBox(height: 10),
                TextField(controller: oldCtrl, decoration: const InputDecoration(labelText: 'Previous Value')),
                const SizedBox(height: 10),
                TextField(controller: newCtrl, decoration: const InputDecoration(labelText: 'New Updated Value *')),
                const SizedBox(height: 10),
                TextField(controller: docCtrl, decoration: const InputDecoration(labelText: 'Supporting Document')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (facultyCtrl.text.trim().isEmpty || typeCtrl.text.trim().isEmpty) return;

              final newId = 'REQ-2026-${(count + 1).toString().padLeft(2, '0')}';
              await _fs.addDoc(_fs.profileApprovals, {
                'displayId': newId,
                'faculty': facultyCtrl.text.trim(),
                'updateType': typeCtrl.text.trim(),
                'oldValue': oldCtrl.text.trim(),
                'newValue': newCtrl.text.trim(),
                'document': docCtrl.text.trim().isEmpty ? 'Document_Pending.pdf' : docCtrl.text.trim(),
                'status': 'PENDING HOD',
                'hodRemarks': '',
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request for ${facultyCtrl.text.trim()} submitted successfully!'),
                  backgroundColor: const Color(0xFF2563EB),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openApproveModal(BuildContext context, String docId, Map<String, dynamic> d) {
    final remarksCtrl = TextEditingController(text: 'Verified document. Approved.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Request: ${d['displayId']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Faculty: ${d['faculty']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Update Type: ${d['updateType']}'),
              const SizedBox(height: 4),
              Text('New Value: ${d['newValue']}', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(controller: remarksCtrl, decoration: const InputDecoration(labelText: 'HOD Remarks')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _fs.updateDoc(_fs.profileApprovals, docId, {
                'status': 'APPROVED',
                'hodRemarks': remarksCtrl.text.trim(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request ${d['displayId']} APPROVED!'),
                  backgroundColor: const Color(0xFF16A34A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text('Confirm Approval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openRejectModal(BuildContext context, String docId, Map<String, dynamic> d) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Request: ${d['displayId']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Faculty: ${d['faculty']}'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reason for Rejection *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              await _fs.updateDoc(_fs.profileApprovals, docId, {
                'status': 'REJECTED',
                'hodRemarks': reasonCtrl.text.trim(),
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request ${d['displayId']} REJECTED.'),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
