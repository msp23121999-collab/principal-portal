import 'package:flutter/material.dart';
import '../theme.dart';

class QuickActionsPanel extends StatelessWidget {
  const QuickActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionBtnItem('Add Faculty', Icons.person_add_alt_outlined, AppTheme.accentBlue),
      _ActionBtnItem('Add Student', Icons.group_add_outlined, AppTheme.accentGreen),
      _ActionBtnItem('Assign Mentors', Icons.psychology_outlined, AppTheme.accentPurple),
      _ActionBtnItem('Class Advisors', Icons.assignment_ind_outlined, AppTheme.accentOrange),
      _ActionBtnItem('Allocate Subjects', Icons.auto_stories_outlined, AppTheme.accentTeal),
      _ActionBtnItem('Approve Leaves', Icons.event_available_outlined, AppTheme.accentAmber),
      _ActionBtnItem('Upload Circular', Icons.cloud_upload_outlined, AppTheme.accentIndigo),
      _ActionBtnItem('Create Event', Icons.add_location_alt_outlined, AppTheme.accentRose),
      _ActionBtnItem('Generate Reports', Icons.assessment_outlined, AppTheme.accentBlue),
      _ActionBtnItem('Upload Material', Icons.folder_zip_outlined, AppTheme.accentGreen),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: AppTheme.accentAmber,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'HOD Quick Administrative Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            int crossAxisCount;
            if (availableWidth >= 1200) {
              crossAxisCount = 6;
            } else if (availableWidth >= 900) {
              crossAxisCount = 5;
            } else if (availableWidth >= 720) {
              crossAxisCount = 4;
            } else if (availableWidth >= 540) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 2;
            }

            final double itemHeight = 50.0;
            final double spacing = 10.0;
            final double itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
            final double aspectRatio = itemWidth / itemHeight;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final item = actions[index];
                return InkWell(
                  onTap: () => _triggerQuickAction(context, item.title),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.015),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(item.icon, color: item.color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _triggerQuickAction(BuildContext context, String actionTitle) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.bolt, color: AppTheme.accentAmber),
              const SizedBox(width: 8),
              Text(actionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Launch administrative workflow for "$actionTitle"?'),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Remarks / Notes',
                  hintText: 'Enter details for $actionTitle...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully performed "$actionTitle" action!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              child: const Text('Confirm Action', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _ActionBtnItem {
  final String title;
  final IconData icon;
  final Color color;

  _ActionBtnItem(this.title, this.icon, this.color);
}
