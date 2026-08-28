import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../export_dialog_helper.dart';

class NotificationsModuleView extends StatefulWidget {
  const NotificationsModuleView({super.key});

  @override
  State<NotificationsModuleView> createState() => _NotificationsModuleViewState();
}

class _NotificationsModuleViewState extends State<NotificationsModuleView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final _fs = FirestoreService.instance;

  String _selectedFilter = 'All Notifications';
  String _selectedAudience = 'All Faculty & Students';

  final List<String> _audiences = [
    'All Faculty & Students',
    'Faculty Only',
    'Students Only',
    'Department Staff',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Fallback initial data matching exact screenshot UI if Firestore is empty
  List<Map<String, dynamic>> get _fallbackNotifications => [
        {
          'id': 'mock-1',
          'displayId': 'NOTIF-2026-004',
          'title': 'hg',
          'category': 'jhj',
          'priority': 'MEDIUM',
          'audience': 'hjlh',
          'status': 'PUBLISHED',
        },
        {
          'id': 'mock-2',
          'displayId': 'NOTIF-2026-005',
          'title': 'Freshers Day',
          'category': 'Cele',
          'priority': 'HIGH',
          'audience': 'All Factuality and Students',
          'status': 'PUBLISHED',
        },
        {
          'id': 'mock-3',
          'displayId': 'NOTIF-2026-006',
          'title': 'mee',
          'category': 'stf',
          'priority': 'LOW',
          'audience': 'dfghui',
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
          allItems = List<Map<String, dynamic>>.from(_fallbackNotifications);
        }

        final query = _searchCtrl.text.toLowerCase().trim();
        final filteredBySearch = allItems.where((d) {
          final title = (d['title'] ?? '').toString().toLowerCase();
          final category = (d['category'] ?? '').toString().toLowerCase();
          final displayId = (d['displayId'] ?? '').toString().toLowerCase();
          final audience = (d['audience'] ?? '').toString().toLowerCase();
          return title.contains(query) ||
              category.contains(query) ||
              displayId.contains(query) ||
              audience.contains(query);
        }).toList();

        final filtered = filteredBySearch.where((d) {
          final status = (d['status'] ?? '').toString().toUpperCase();
          final priority = (d['priority'] ?? '').toString().toUpperCase();
          if (_selectedFilter == 'Live Published') {
            return status == 'PUBLISHED';
          } else if (_selectedFilter == 'Urgent Alerts') {
            return priority == 'HIGH';
          }
          return true; // All Notifications
        }).toList();

        final totalNotifs = allItems.length;
        final livePublishedCount = allItems.where((d) => (d['status'] ?? '').toString().toUpperCase() == 'PUBLISHED').length;
        final urgentAlertsCount = allItems.where((d) => (d['priority'] ?? '').toString().toUpperCase() == 'HIGH').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Page Header Title & Academic Year Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text(
                            'Dashboard > ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: const Text(
                      'Academic Year 2025-26',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Department Communications & Broadcasts Hero Banner Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
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
                            Icons.notifications_active_rounded,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Department Communications & Broadcasts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Broadcast circulars, exam alerts, meeting notices, and urgent department announcements to faculty & students.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Printing Notifications Report...')),
                            );
                          },
                          icon: const Icon(Icons.print_rounded, size: 16, color: Color(0xFFD97706)),
                          label: const Text(
                            'Print',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEB),
                            side: const BorderSide(color: Color(0xFFFDE68A)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        HodExportDialog.buildExportButton(
                          context,
                          onPressed: () => HodExportDialog.show(
                            context,
                            title: 'Export Notifications Data',
                            subtitle: 'Select export format for Notifications records:',
                            moduleName: 'Notifications',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Filter Options & Audience Select Strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Radio Options
                    Row(
                      children: [
                        _buildFilterOption('All Notifications'),
                        const SizedBox(width: 12),
                        _buildFilterOption('Live Published'),
                        const SizedBox(width: 12),
                        _buildFilterOption('Urgent Alerts'),
                      ],
                    ),

                    // Right Side: Audience Select Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAudience,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          items: _audiences.map((String audience) {
                            return DropdownMenuItem<String>(
                              value: audience,
                              child: Text(audience),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedAudience = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Main Announcement Register Card
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
                      // Header with Cell Tower / Broadcast Icon & Search Box
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.sensors_rounded,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Announcement Register',
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
                                hintText: 'Search title...',
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
                                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3 High Density Metric Summary Cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final availableWidth = constraints.maxWidth;
                          final crossAxisCount = (availableWidth / 260).floor().clamp(1, 3);
                          final double itemHeight = 112.0;
                          final double spacing = 16.0;
                          final double itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
                          final double aspectRatio = itemWidth / itemHeight;

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: aspectRatio,
                            children: [
                              _buildMetricCard(
                                title: 'TOTAL NOTIFS',
                                value: '$totalNotifs',
                                subtitle: 'All broadcasts',
                                icon: Icons.notifications_none_rounded,
                                bgColor: const Color(0xFFEFF6FF),
                                borderColor: const Color(0xFFDBEAFE),
                                accentColor: const Color(0xFF2563EB),
                                textColor: const Color(0xFF1E40AF),
                              ),
                              _buildMetricCard(
                                title: 'LIVE PUBLISHED',
                                value: '$livePublishedCount',
                                subtitle: 'Visible on portal',
                                icon: Icons.check_circle_outline_rounded,
                                bgColor: const Color(0xFFF0FDF4),
                                borderColor: const Color(0xFFDCFCE7),
                                accentColor: const Color(0xFF16A34A),
                                textColor: const Color(0xFF15803D),
                              ),
                              _buildMetricCard(
                                title: 'URGENT ALERTS',
                                value: '$urgentAlertsCount',
                                subtitle: 'High priority alerts',
                                icon: Icons.warning_amber_rounded,
                                bgColor: const Color(0xFFFEF2F2),
                                borderColor: const Color(0xFFFECACA),
                                accentColor: const Color(0xFFDC2626),
                                textColor: const Color(0xFF991B1B),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // High Density Data Table (Full Width Layout)
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
                                      'Title & ID',
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
                                      'Status',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                                rows: filtered.map((d) {
                                  final priority = (d['priority'] ?? 'MEDIUM').toString().toUpperCase();
                                  final status = (d['status'] ?? 'PUBLISHED').toString().toUpperCase();

                                  return DataRow(cells: [
                                    // Title & ID Column
                                    DataCell(
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            d['title'] ?? 'Notification Title',
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

                                    // Priority Pill
                                    DataCell(_buildPriorityBadge(priority)),

                                    // Audience
                                    DataCell(
                                      Text(
                                        d['audience'] ?? 'All Faculty & Students',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                      ),
                                    ),

                                    // Status Badge (Green PUBLISHED)
                                    DataCell(_buildStatusBadge(status)),
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

  // Interactive Radio Filter Pill Widget
  Widget _buildFilterOption(String title) {
    final isSelected = _selectedFilter == title;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metric Summary Card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.check_circle_rounded,
            size: 14,
            color: Color(0xFF16A34A),
          ),
          SizedBox(width: 4),
          Text(
            'PUBLISHED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}
