import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../services/download_service.dart';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  String _selectedFilter = 'All';
  String? _downloadingAssignmentId;

  @override
  Widget build(BuildContext context) {
    final assignments = MockData.mockAssignments;
    final pendingCount = assignments.where((a) => a.status == 'Pending').length;
    final submittedCount = assignments.where((a) => a.status == 'Submitted').length;
    final overdueCount = assignments.where((a) => a.status == 'Overdue').length;

    final filteredList = assignments.where((a) {
      if (_selectedFilter == 'All') return true;
      return a.status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Assignments & Coursework'),
            const SizedBox(height: 12),

            // ── KPI Cards Grid ──────────────────────────────────────────
            Row(
              children: [
                Expanded(child: KPICard(title: 'Total Given', value: '${assignments.length}', icon: Icons.assignment_rounded, color: AppTheme.primaryColor)),
                const SizedBox(width: 12),
                Expanded(child: KPICard(title: 'Pending', value: '$pendingCount', icon: Icons.pending_actions_rounded, color: AppTheme.warningColor)),
                const SizedBox(width: 12),
                Expanded(child: KPICard(title: 'Submitted', value: '$submittedCount', icon: Icons.task_alt_rounded, color: AppTheme.successColor)),
                const SizedBox(width: 12),
                Expanded(child: KPICard(title: 'Overdue', value: '$overdueCount', icon: Icons.error_outline_rounded, color: AppTheme.errorColor)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Filter Pills ─────────────────────────────────────────────
            Row(
              children: ['All', 'Pending', 'Submitted', 'Overdue'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppTheme.accentColor.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.accentColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) => setState(() => _selectedFilter = filter),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ── Assignments List ─────────────────────────────────────────
            filteredList.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No assignments found',
                    description: 'There are no assignments matching the selected status filter.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final assignment = filteredList[index];
                      final isOverdue = assignment.status == 'Overdue';

                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? AppTheme.errorColor.withValues(alpha: 0.1)
                                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.assignment_rounded,
                                color: isOverdue ? AppTheme.errorColor : AppTheme.primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        assignment.subject,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                                      ),
                                      StatusBadge(status: assignment.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    assignment.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.event_rounded, size: 14, color: AppTheme.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Due Date: ${assignment.dueDate.day}/${assignment.dueDate.month}/${assignment.dueDate.year}',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: _downloadingAssignmentId == assignment.id
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.file_download_outlined, color: AppTheme.primaryColor),
                                onPressed: assignment.attachmentUrl != null && assignment.attachmentUrl!.isNotEmpty && _downloadingAssignmentId != assignment.id
                                    ? () => _downloadAssignment(assignment)
                                    : null,
                                tooltip: assignment.attachmentUrl != null && assignment.attachmentUrl!.isNotEmpty ? 'Download assignment' : 'No attachment',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAssignment(dynamic assignment) async {
    if (assignment.attachmentUrl == null || assignment.attachmentUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment attachment is not available.')),
      );
      return;
    }

    setState(() => _downloadingAssignmentId = assignment.id);

    try {
      final fileName = '${assignment.subject.replaceAll(' ', '_')}_${assignment.title.replaceAll(' ', '_').substring(0, 20)}.pdf';
      final sanitized = DownloadService.sanitizeFilename(fileName);
      final success = await DownloadService.downloadFromUrl(assignment.attachmentUrl!, sanitized);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started: $sanitized')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed. Please try again.')),
          );
        }
        setState(() => _downloadingAssignmentId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download assignment. Please try again.')),
        );
        setState(() => _downloadingAssignmentId = null);
      }
    }
  }
}

