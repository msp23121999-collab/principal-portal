import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/file_downloader.dart';

class BackupItem {
  // Completed / Failed

  const BackupItem({
    required this.id,
    required this.date,
    required this.size,
    required this.type,
    required this.status,
  });
  final String id;
  final String date;
  final String size;
  final String type; // Automatic / Manual
  final String status;
}

final List<BackupItem> _initialBackups = [
  const BackupItem(
    id: 'BKP-128',
    date: 'Aug 09, 2026 — 02:00 AM',
    size: '4.8 GB',
    type: 'Automatic',
    status: 'Completed',
  ),
  const BackupItem(
    id: 'BKP-127',
    date: 'Aug 08, 2026 — 02:00 AM',
    size: '4.7 GB',
    type: 'Automatic',
    status: 'Completed',
  ),
  const BackupItem(
    id: 'BKP-126',
    date: 'Aug 07, 2026 — 03:15 PM',
    size: '4.7 GB',
    type: 'Manual',
    status: 'Completed',
  ),
  const BackupItem(
    id: 'BKP-125',
    date: 'Aug 06, 2026 — 02:00 AM',
    size: '4.6 GB',
    type: 'Automatic',
    status: 'Completed',
  ),
  const BackupItem(
    id: 'BKP-124',
    date: 'Aug 05, 2026 — 02:00 AM',
    size: '4.6 GB',
    type: 'Automatic',
    status: 'Completed',
  ),
];

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  late List<BackupItem> _backups;
  bool _autoBackupEnabled = true;
  String _backupFrequency = 'Daily';
  String _retentionPeriod = '90 days';
  String? _selectedRestoreBackupId = 'BKP-128';

  @override
  void initState() {
    super.initState();
    _backups = List.from(_initialBackups);
  }

  void _triggerManualBackup() {
    final newId = 'BKP-${129 + (_backups.length - 5)}';
    final nowStr = 'Aug 09, 2026 — ${TimeOfDay.now().format(context)}';
    final newItem = BackupItem(
      id: newId,
      date: nowStr,
      size: '4.8 GB',
      type: 'Manual',
      status: 'Completed',
    );

    setState(() {
      _backups.insert(0, newItem);
      _selectedRestoreBackupId = newId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Manual Backup "$newId" created successfully!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRestoreDialog(BackupItem item) {
    final confirmCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFDC2626),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Confirm Workspace Restore (${item.id})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Text(
                'CRITICAL WARNING: Restoring a backup will overwrite existing database records created after the selected backup date. This action cannot be undone.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Selected Backup: ${item.id} (${item.date})',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              decoration: InputDecoration(
                labelText: 'Type "${item.id}" to confirm:',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Execute Restore'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (confirmCtrl.text.trim() == item.id) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Workspace restored to snapshot "${item.id}" successfully.',
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Confirmation ID mismatch. Restore aborted.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Responsive LayoutBuilder to prevent overflow)
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 850;
              return Flex(
                direction: isNarrow ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: isNarrow ? 0 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Backup & Restore Console',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protect your organization\'s data with automated backups and restore snapshots.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isNarrow) const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _triggerManualBackup,
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text('Create Backup Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Large Backup Status Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFF16A34A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Backup Protection Active',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your latest backup was completed successfully. Automated daily cloud sync active.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Last Backup: August 09, 2026 — 02:00 AM',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Backup Size: 4.8 GB',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Next Scheduled: August 10, 2026 — 02:00 AM',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0052CC),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Statistics Summary Cards (Single Row 4 Cards Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isMedium =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 900;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        'Total Backups',
                        '${_backups.length + 123}',
                        Icons.storage_rounded,
                        const Color(0xFF0052CC),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatTile(
                        'Successful Backups',
                        '126',
                        Icons.check_circle_rounded,
                        const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatTile(
                        'Failed Backups',
                        '2',
                        Icons.error_rounded,
                        const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildStatTile(
                        'Storage Used',
                        '184 GB',
                        Icons.cloud_done_rounded,
                        const Color(0xFF9333EA),
                      ),
                    ),
                  ],
                );
              } else if (isMedium) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            'Total Backups',
                            '${_backups.length + 123}',
                            Icons.storage_rounded,
                            const Color(0xFF0052CC),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatTile(
                            'Successful Backups',
                            '126',
                            Icons.check_circle_rounded,
                            const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatTile(
                            'Failed Backups',
                            '2',
                            Icons.error_rounded,
                            const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatTile(
                            'Storage Used',
                            '184 GB',
                            Icons.cloud_done_rounded,
                            const Color(0xFF9333EA),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStatTile(
                      'Total Backups',
                      '${_backups.length + 123}',
                      Icons.storage_rounded,
                      const Color(0xFF0052CC),
                    ),
                    const SizedBox(height: 10),
                    _buildStatTile(
                      'Successful Backups',
                      '126',
                      Icons.check_circle_rounded,
                      const Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 10),
                    _buildStatTile(
                      'Failed Backups',
                      '2',
                      Icons.error_rounded,
                      const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 10),
                    _buildStatTile(
                      'Storage Used',
                      '184 GB',
                      Icons.cloud_done_rounded,
                      const Color(0xFF9333EA),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Backup Settings & Configuration Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automatic Backup Configuration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                SwitchListTile(
                  title: const Text(
                    'Automatic Scheduled Backups',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Automatically create backups according to your selected schedule',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  value: _autoBackupEnabled,
                  activeColor: const Color(0xFF0052CC),
                  onChanged: (val) => setState(() => _autoBackupEnabled = val),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _backupFrequency,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Backup Frequency',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items:
                            ['Every hour', 'Every 6 hours', 'Daily', 'Weekly']
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _backupFrequency = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _retentionPeriod,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Retention Period (Keep Backups For)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: ['7 days', '30 days', '90 days', '1 year']
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _retentionPeriod = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backup History Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Backup Snapshots History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Backup ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date & Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Size',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: _backups.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              item.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0052CC),
                              ),
                            ),
                          ),
                          DataCell(Text(item.date)),
                          DataCell(Text(item.size)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: item.type == 'Automatic'
                                    ? const Color(0xFFEFF6FF)
                                    : const Color(0xFFF3E8FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item.type,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item.type == 'Automatic'
                                      ? const Color(0xFF0052CC)
                                      : const Color(0xFF9333EA),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.status,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Download Backup',
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    size: 18,
                                    color: Color(0xFF0284C7),
                                  ),
                                  onPressed: () {
                                    final content = jsonEncode({
                                      'backupId': item.id,
                                      'timestamp': item.date,
                                      'size': item.size,
                                    });
                                    FileDownloader.downloadFile(
                                      utf8.encode(content),
                                      '${item.id}.zip',
                                    );
                                  },
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.restore_rounded,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Restore',
                                    style: TextStyle(fontSize: 11),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    foregroundColor: const Color(0xFFDC2626),
                                  ),
                                  onPressed: () => _showRestoreDialog(item),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dedicated Restore Panel & Wizard
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Restore Workspace Wizard',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select a backup snapshot to restore your workspace database to a previous point in time.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Important: Restoring a backup may overwrite data created after the selected backup. Make sure you understand the impact before continuing.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRestoreBackupId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Step 1: Select Backup Snapshot',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: _backups
                            .map(
                              (b) => DropdownMenuItem(
                                value: b.id,
                                child: Text('${b.id} — ${b.date} (${b.size})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedRestoreBackupId = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.restore_page_rounded, size: 18),
                      label: const Text('Execute Restore Wizard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final selected = _backups.firstWhere(
                          (b) => b.id == _selectedRestoreBackupId,
                          orElse: () => _backups.first,
                        );
                        _showRestoreDialog(selected);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildStatTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
