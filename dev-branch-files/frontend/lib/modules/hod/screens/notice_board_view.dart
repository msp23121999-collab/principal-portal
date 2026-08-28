import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../responsive.dart';
import '../hod_toast.dart';
import '../pdf_download_helper.dart';
import '../../faculty/services/profile_service.dart';

class NoticeBoardModuleView extends StatefulWidget {
  const NoticeBoardModuleView({super.key});

  @override
  State<NoticeBoardModuleView> createState() => _NoticeBoardModuleViewState();
}

class _NoticeBoardModuleViewState extends State<NoticeBoardModuleView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _fs = FirestoreService.instance;
  static final Map<String, String> _uploadedDocUrls = {};

  String _selectedFilter = 'All Notices';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Fallback initial data matching exact screenshot UI if Firestore is empty
  List<Map<String, dynamic>> get _fallbackNotices => [
        {
          'id': 'mock-nb-1',
          'displayId': 'NB-2026-01',
          'title': 'Sem holiday',
          'category': 'Holiday',
          'priority': 'MEDIUM',
          'audience': 'All Users',
          'postedBy': '${ProfileService.get()['name'] ?? 'Dr. K. Ravichandran'} (HOD)',
          'date': '01-Aug-2026',
          'status': 'PUBLISHED',
        },
      ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fs.streamAll(_fs.notifications),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> allItems = [];

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.docs.isNotEmpty) {
          allItems = snapshot.data!.docs.map((d) {
            final raw = d.data() as Map?;
            final data = raw != null ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
            data['id'] = d.id;
            return data;
          }).toList();
        } else {
          allItems = List<Map<String, dynamic>>.from(_fallbackNotices);
        }

        final query = _searchCtrl.text.toLowerCase().trim();
        final filteredBySearch = allItems.where((d) {
          final title = (d['title'] ?? '').toString().toLowerCase();
          final category = (d['category'] ?? '').toString().toLowerCase();
          final displayId = (d['displayId'] ?? '').toString().toLowerCase();
          final audience = (d['audience'] ?? '').toString().toLowerCase();
          final postedBy = (d['postedBy'] ?? '').toString().toLowerCase();
          return title.contains(query) ||
              category.contains(query) ||
              displayId.contains(query) ||
              audience.contains(query) ||
              postedBy.contains(query);
        }).toList();

        final filtered = filteredBySearch.where((d) {
          final status = (d['status'] ?? '').toString().toUpperCase();
          final priority = (d['priority'] ?? '').toString().toUpperCase();
          if (_selectedFilter == 'High Priority') {
            return priority == 'HIGH';
          } else if (_selectedFilter == 'Published') {
            return status == 'PUBLISHED';
          } else if (_selectedFilter == 'Drafts') {
            return status == 'DRAFT';
          }
          return true; // All Notices
        }).toList();

        final totalNotices = allItems.length;
        final highPriorityCount = allItems.where((d) => (d['priority'] ?? '').toString().toUpperCase() == 'HIGH').length;
        final publishedCount = allItems.where((d) => (d['status'] ?? '').toString().toUpperCase() == 'PUBLISHED').length;
        final draftCount = allItems.where((d) => (d['status'] ?? '').toString().toUpperCase() == 'DRAFT').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Page Header Title & Post Notice Button (No icon as requested)
              HodSectionHeader(
                title: 'Notice Board',
                breadcrumb: 'Dashboard › Dept Admin › Notice Board & Circulars',
                academicYear: 'Academic Year 2025 - 2026',
                actions: [
                  ElevatedButton(
                    onPressed: () => _openPostNoticeModal(context, allItems.length),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Corporate Blue/Indigo
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Post Notice',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Bento KPI Metric Cards (4 Cards in a Row)
              Row(
                children: [
                  Expanded(
                    child: _buildBentoKpiCard(
                      title: 'Total Notices',
                      value: '$totalNotices',
                      subtitle: 'This Semester',
                      icon: Icons.article_outlined,
                      iconColor: const Color(0xFF2563EB),
                      valueColor: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoKpiCard(
                      title: 'High Priority',
                      value: '$highPriorityCount',
                      subtitle: 'Urgent Actions',
                      icon: Icons.error_outline_rounded,
                      iconColor: const Color(0xFFDC2626),
                      valueColor: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoKpiCard(
                      title: 'Published',
                      value: '$publishedCount',
                      subtitle: 'Live on Portal',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      valueColor: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoKpiCard(
                      title: 'Drafts',
                      value: '$draftCount',
                      subtitle: 'Pending Publish',
                      icon: Icons.mark_as_unread_outlined,
                      iconColor: const Color(0xFFD97706),
                      valueColor: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Filter Options & Search Box Strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Radio Filter Pills
                    _buildFilterOption('All Notices'),
                    const SizedBox(width: 12),
                    _buildFilterOption('High Priority'),
                    const SizedBox(width: 12),
                    _buildFilterOption('Published'),
                    const SizedBox(width: 12),
                    _buildFilterOption('Drafts'),
                    const SizedBox(width: 20),

                    // Search notices... Input Box
                    SizedBox(
                      width: 260,
                      height: 38,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search notices...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Main Notices & Circulars Register Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Campaign / Megaphone Icon & Title
                      Row(
                        children: const [
                          Icon(
                            Icons.campaign_outlined,
                            color: Color(0xFF6366F1),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Notices & Circulars Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Full Width Responsive Data Table Layout
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                headingRowHeight: 46,
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 64,
                                horizontalMargin: 16,
                                columnSpacing: 28,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columns: const [
                                  DataColumn(
                                    label: Text(
                                      'Notice / ID',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Category',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Priority',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Audience',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Posted By',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Date',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Status',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Actions',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                                rows: filtered.map((d) {
                                  final priority = (d['priority'] ?? 'MEDIUM').toString().toUpperCase();
                                  final status = (d['status'] ?? 'PUBLISHED').toString().toUpperCase();

                                  return DataRow(cells: [
                                    // Notice & ID Column
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['title'] ?? 'Notice Title',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            d['displayId'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Category
                                    DataCell(
                                      Text(
                                        d['category'] ?? '-',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ),

                                    // Priority Badge
                                    DataCell(_buildPriorityBadge(priority)),

                                    // Audience
                                    DataCell(
                                      Text(
                                        d['audience'] ?? 'All Users',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ),

                                    // Posted By
                                    DataCell(
                                      Text(
                                        d['postedBy'] ?? '${ProfileService.get()['name'] ?? 'Dr. K. Ravichandran'} (HOD)',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ),

                                    // Date
                                    DataCell(
                                      Text(
                                        d['date'] ?? '01-Aug-2026',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ),

                                    // Status Badge (Green PUBLISHED)
                                    DataCell(_buildStatusBadge(status)),

                                    // Actions: Publish (if DRAFT), View Details, and Delete Icon
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (status.toUpperCase() == 'DRAFT') ...[
                                            ElevatedButton.icon(
                                              onPressed: () => _confirmPublishNotice(context, d),
                                              icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                                              label: const Text('Publish', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          IconButton(
                                            icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF3B82F6)),
                                            onPressed: () => _showNoticeDetailsModal(context, d),
                                            tooltip: 'View Notice Details',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                            onPressed: () => _confirmDeleteNotice(context, d),
                                            tooltip: 'Delete Notice',
                                          ),
                                        ],
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

  // Bento KPI Metric Card Builder
  Widget _buildBentoKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // Filter Pill Button
  Widget _buildFilterOption(String title) {
    final isSelected = _selectedFilter == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  // Priority Badge Pill Widget
  Widget _buildPriorityBadge(String priority) {
    Color bg;
    Color border;
    Color text;

    if (priority == 'HIGH') {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      text = const Color(0xFFDC2626);
    } else if (priority == 'MEDIUM') {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFD97706);
    } else {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFDBEAFE);
      text = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  // Status Badge Pill Widget (Green PUBLISHED)
  Widget _buildStatusBadge(String status) {
    final isPublished = status == 'PUBLISHED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPublished ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPublished ? const Color(0xFF16A34A) : const Color(0xFFD97706),
        ),
      ),
    );
  }

  // Confirmation modal to publish a draft notice
  void _confirmPublishNotice(BuildContext context, Map<String, dynamic> notice) {
    final title = notice['title'] ?? notice['subject'] ?? 'Notice';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Publish Notice?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to publish "$title"? Once published, this notice will be immediately visible to all selected target recipients.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final docId = notice['id'];
              if (docId != null && docId.toString().isNotEmpty && !docId.toString().startsWith('mock-')) {
                await _fs.updateDoc(_fs.notifications, docId.toString(), {
                  'status': 'PUBLISHED',
                });
              } else {
                setState(() {
                  notice['status'] = 'PUBLISHED';
                });
              }
              if (context.mounted) {
                HodToast.show(
                  context,
                  message: 'Notice "$title" published successfully.',
                  isSuccess: true,
                );
              }
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
            label: const Text('Confirm & Publish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  // Confirmation dialog before deleting a notice
  void _confirmDeleteNotice(BuildContext context, Map<String, dynamic> notice) {
    final title = notice['title'] ?? notice['subject'] ?? 'this notice';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text('Confirm Notice Deletion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final docId = notice['id'];
              if (docId != null && docId.toString().isNotEmpty) {
                await _fs.deleteDoc(_fs.notifications, docId.toString());
              }
              if (context.mounted) {
                HodToast.show(
                  context,
                  message: 'Notice "$title" deleted successfully.',
                  isError: true,
                );
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
            label: const Text('Delete Notice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // Modal dialog to view complete notice details (description, uploaded document, metadata)
  void _showNoticeDetailsModal(BuildContext context, Map<String, dynamic> notice) {
    final title = notice['title'] ?? notice['subject'] ?? 'Notice Details';
    final displayId = notice['displayId'] ?? notice['id'] ?? 'NB-2026';
    final category = notice['category'] ?? 'General';
    final priority = (notice['priority'] ?? 'MEDIUM').toString().toUpperCase();
    final audience = notice['audience'] ?? 'All Users';
    final postedBy = notice['postedBy'] ?? '${ProfileService.get()['name'] ?? 'Dr. K. Ravichandran'} (HOD)';
    final date = notice['date'] ?? '08-Aug-2026';
    final status = (notice['status'] ?? 'PUBLISHED').toString().toUpperCase();
    final description = notice['description'] ?? notice['content'] ?? notice['body'] ?? 'Official departmental circular regarding $title. Please find all guidelines and scheduled timelines attached.';
    final String? documentName = () {
      final raw = notice['documentName'] ?? notice['fileName'] ?? notice['attachment_name'] ?? notice['attachment'];
      if (raw == null) return null;
      final str = raw.toString().trim();
      if (str.isEmpty || str.toUpperCase() == 'NONE' || str == 'null') return null;
      return str;
    }();
    final String? documentUrl = notice['documentUrl'] ?? notice['attachment_url'] ?? notice['fileUrl'] ?? notice['url'] ?? (documentName != null ? _uploadedDocUrls[documentName] : null);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header with Close Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFF3B82F6), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                displayId,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 10),
                              _buildPriorityBadge(priority),
                              const SizedBox(width: 8),
                              _buildStatusBadge(status),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 20),

                // 2. Metadata Grid (Category, Audience, Posted By, Date)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailTile('Category', category, Icons.category_outlined),
                      ),
                      Expanded(
                        child: _buildDetailTile('Audience', audience, Icons.group_outlined),
                      ),
                      Expanded(
                        child: _buildDetailTile('Posted By', postedBy, Icons.person_outline),
                      ),
                      Expanded(
                        child: _buildDetailTile('Date', date, Icons.calendar_today_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Description / Circular Body Section
                const Text(
                  'Description / Circular Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Uploaded Document / Attachment Section
                const Text(
                  'Uploaded Document / Circular Attachment',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                if (documentName != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                documentName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'PDF Circular Document • Verified HOD Signature',
                                style: TextStyle(fontSize: 11, color: Color(0xFF4338CA)),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final rawUrl = documentUrl ?? _uploadedDocUrls[documentName];
                            if (rawUrl != null && rawUrl.isNotEmpty) {
                              final viewerUrl = _prepareViewerUrl(rawUrl, documentName);
                              html.window.open(viewerUrl, '_blank');
                              HodToast.show(
                                context,
                                message: 'Opening uploaded document "$documentName"...',
                                isSuccess: true,
                              );
                            } else {
                              PdfDownloadHelper.downloadDepartmentReportPdf(
                                title: 'CIRCULAR - $title',
                                headers: ['FIELD', 'NOTICE DETAILS'],
                                rows: [
                                  ['Notice ID', displayId],
                                  ['Notice Title', title],
                                  ['Category', category],
                                  ['Priority', priority],
                                  ['Target Audience', audience],
                                  ['Posted By', postedBy],
                                  ['Date Issued', date],
                                  ['Current Status', status],
                                  ['Circular Content', description],
                                ],
                              );
                              HodToast.show(
                                context,
                                message: 'PDF Document "$documentName" opened successfully!',
                                isSuccess: true,
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Colors.white),
                          label: const Text('View Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 20),
                        SizedBox(width: 10),
                        Text(
                          'No document uploaded for this notice.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // 5. Close Action Button
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF475569),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _prepareViewerUrl(String rawUrl, String fileName) {
    if (rawUrl.startsWith('blob:')) {
      return rawUrl;
    }
    if (rawUrl.startsWith('data:')) {
      try {
        final commaIndex = rawUrl.indexOf(',');
        if (commaIndex != -1) {
          final header = rawUrl.substring(0, commaIndex);
          final base64Str = rawUrl.substring(commaIndex + 1);
          final mimeMatch = RegExp(r'data:(.*?);').firstMatch(header);
          final mimeType = mimeMatch?.group(1) ?? 'application/pdf';
          final bytes = base64Decode(base64Str);
          final blob = html.Blob([bytes], mimeType);
          return html.Url.createObjectUrlFromBlob(blob);
        }
      } catch (_) {}
    }
    return rawUrl;
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Post New Notice Modal matching screenshot UI exactly
  void _openPostNoticeModal(BuildContext context, int count) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();

    String selectedAudience = 'All Users';
    String selectedBatch = 'All Batches';
    String priority = 'MEDIUM';
    String? selectedDocName;
    String? selectedDocUrl;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: 640,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Modal Header (Icon Badge + Title & Subtitle + Close X)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1), // Indigo/Purple
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.campaign_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Post New Notice',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Publish official academic circulars, announcements & documents.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Notice Title * Input Field
                  Row(
                    children: const [
                      Text(
                        'Notice Title ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '*',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g., Internal Assessment Schedule & Guidelines',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Category * and Priority Level (2 Column Row)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category * Input
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  'Category ',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                Text(
                                  '*',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: categoryCtrl,
                              decoration: InputDecoration(
                                hintText: 'Examination / Academic / Circular',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Priority Level Dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Priority Level',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: priority,
                              decoration: InputDecoration(
                                fillColor: const Color(0xFFF8FAFC),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: 'MEDIUM',
                                  child: Row(
                                    children: const [
                                      Text('● ', style: TextStyle(color: Color(0xFFD97706), fontSize: 12)),
                                      Text('MEDIUM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'HIGH',
                                  child: Row(
                                    children: const [
                                      Text('● ', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                                      Text('HIGH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'LOW',
                                  child: Row(
                                    children: const [
                                      Text('● ', style: TextStyle(color: Color(0xFF2563EB), fontSize: 12)),
                                      Text('LOW', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) => setModalState(() => priority = val ?? 'MEDIUM'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Target Audience & Batch Filters Box Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Audience & Batch Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Box: Select Target Group *
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Text(
                                          'Select Target Group ',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                        ),
                                        Text(
                                          '*',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    _buildAudienceRadioOption(
                                      title: 'All Users',
                                      isSelected: selectedAudience == 'All Users',
                                      onTap: () => setModalState(() => selectedAudience = 'All Users'),
                                    ),
                                    _buildAudienceRadioOption(
                                      title: 'Faculty Only',
                                      isSelected: selectedAudience == 'Faculty Only',
                                      onTap: () => setModalState(() => selectedAudience = 'Faculty Only'),
                                    ),
                                    _buildAudienceRadioOption(
                                      title: 'Students Only',
                                      isSelected: selectedAudience == 'Students Only',
                                      onTap: () => setModalState(() => selectedAudience = 'Students Only'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Right Box: Batch Selection (Enabled when Students Only is selected)
                            Builder(
                              builder: (context) {
                                final isBatchEnabled = selectedAudience == 'Students Only';
                                return Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isBatchEnabled ? Colors.white : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isBatchEnabled ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isBatchEnabled ? 'Batch Selection' : 'Batch Selection (Disabled)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isBatchEnabled ? FontWeight.bold : FontWeight.w500,
                                            color: isBatchEnabled ? const Color(0xFF334155) : const Color(0xFF94A3B8),
                                            fontStyle: isBatchEnabled ? FontStyle.normal : FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        if (isBatchEnabled) ...[
                                          _buildAudienceRadioOption(
                                            title: 'All Batches',
                                            isSelected: selectedBatch == 'All Batches',
                                            onTap: () => setModalState(() => selectedBatch = 'All Batches'),
                                          ),
                                          _buildAudienceRadioOption(
                                            title: 'Specific Batches',
                                            isSelected: selectedBatch == 'Specific Batches',
                                            onTap: () => setModalState(() => selectedBatch = 'Specific Batches'),
                                          ),
                                        ] else ...[
                                          _buildDisabledRadioOption('All Batches', isSelected: true),
                                          _buildDisabledRadioOption('Specific Batches', isSelected: false),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Description / Notice Content *
                  Row(
                    children: const [
                      Text(
                        'Description / Notice Content ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '*',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter full description or circular text details...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Upload Document / Attachment (Optional)
                  Row(
                    children: const [
                      Text(
                        'Upload Document / Attachment ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '(Optional)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: selectedDocName == null
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF4F46E5), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Attach Document (PDF, DOCX, PNG, JPG)',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Optional file attachment up to 10MB',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  final uploadInput = html.FileUploadInputElement()..accept = '.pdf,.doc,.docx,.png,.jpg,.jpeg';
                                  uploadInput.click();
                                  uploadInput.onChange.listen((e) {
                                    final files = uploadInput.files;
                                    if (files != null && files.isNotEmpty) {
                                      final file = files[0];
                                      final blobUrl = html.Url.createObjectUrlFromBlob(file);
                                      final reader = html.FileReader();
                                      reader.readAsDataUrl(file);
                                      reader.onLoadEnd.listen((_) {
                                        final dataUrl = reader.result as String?;
                                        setModalState(() {
                                          selectedDocName = file.name;
                                          selectedDocUrl = dataUrl ?? blobUrl;
                                          _uploadedDocUrls[file.name] = selectedDocUrl!;
                                        });
                                      });
                                    }
                                  });
                                },
                                icon: const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF4F46E5)),
                                label: const Text('Browse File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFC7D2FE)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF16A34A), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedDocName!,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'File Attached • Ready for Notice',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove Attachment',
                                icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 20),
                                onPressed: () {
                                  setModalState(() {
                                    selectedDocName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),

                  // 7. Bottom Action Bar (Cancel, Save as Draft, Publish Now)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || categoryCtrl.text.trim().isEmpty) {
                            HodToast.show(
                              context,
                              message: 'Please enter Notice Title and Category!',
                              isError: true,
                            );
                            return;
                          }
                          await _saveNoticeDoc(
                            count: count,
                            title: titleCtrl.text.trim(),
                            category: categoryCtrl.text.trim(),
                            audience: selectedAudience,
                            priority: priority,
                            status: 'DRAFT',
                            description: descriptionCtrl.text.trim(),
                            documentName: selectedDocName,
                            documentUrl: selectedDocUrl,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            HodToast.show(
                              context,
                              message: 'Saved notice as Draft!',
                              isSuccess: true,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Save as Draft',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty || categoryCtrl.text.trim().isEmpty) {
                            HodToast.show(
                              context,
                              message: 'Please enter Notice Title and Category!',
                              isError: true,
                            );
                            return;
                          }
                          await _saveNoticeDoc(
                            count: count,
                            title: titleCtrl.text.trim(),
                            category: categoryCtrl.text.trim(),
                            audience: selectedAudience,
                            priority: priority,
                            status: 'PUBLISHED',
                            description: descriptionCtrl.text.trim(),
                            documentName: selectedDocName,
                            documentUrl: selectedDocUrl,
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            HodToast.show(
                              context,
                              message: 'Notice "${titleCtrl.text.trim()}" published!',
                              isSuccess: true,
                            );
                          }
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Publish Now',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Audience Radio Option Widget
  Widget _buildAudienceRadioOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Disabled Radio Option Widget
  Widget _buildDisabledRadioOption(String title, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 18,
            color: const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to save notice document to Firestore
  Future<void> _saveNoticeDoc({
    required int count,
    required String title,
    required String category,
    required String audience,
    required String priority,
    required String status,
    String? description,
    String? documentName,
    String? documentUrl,
  }) async {
    final newId = 'NB-2026-${(count + 1).toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}-Aug-${now.year}';

    final data = <String, dynamic>{
      'displayId': newId,
      'title': title,
      'category': category,
      'priority': priority,
      'audience': audience,
      'postedBy': '${ProfileService.get()['name'] ?? 'Dr. K. Ravichandran'} (HOD)',
      'date': dateStr,
      'status': status,
    };

    if (description != null && description.isNotEmpty) {
      data['description'] = description;
    }
    if (documentName != null && documentName.isNotEmpty) {
      data['documentName'] = documentName;
      data['attachment_name'] = documentName;
    }
    if (documentUrl != null && documentUrl.isNotEmpty) {
      data['documentUrl'] = documentUrl;
      data['attachment_url'] = documentUrl;
      if (documentName != null) {
        _uploadedDocUrls[documentName] = documentUrl;
      }
    }

    await _fs.addDoc(_fs.notifications, data);
  }
}
