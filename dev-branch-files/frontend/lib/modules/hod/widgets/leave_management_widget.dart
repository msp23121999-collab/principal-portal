import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../theme.dart';

class LeaveManagementWidget extends StatefulWidget {
  final List<LeaveRequestItem> leaveRequests;

  const LeaveManagementWidget({
    super.key,
    required this.leaveRequests,
  });

  @override
  State<LeaveManagementWidget> createState() => _LeaveManagementWidgetState();
}

class _LeaveManagementWidgetState extends State<LeaveManagementWidget> {
  @override
  Widget build(BuildContext context) {
    final pendingList = widget.leaveRequests.where((r) => r.status == 'Pending').toList();
    final approvedList = widget.leaveRequests.where((r) => r.status == 'Approved').toList();

    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow) ...[
            const Row(
              children: [
                Icon(
                  Icons.event_note_rounded,
                  color: AppTheme.accentOrange,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Faculty Leave Approvals',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCountChip('${pendingList.length} Pending', AppTheme.accentOrange, AppTheme.badgeOrangeBg),
                const SizedBox(width: 6),
                _buildCountChip('${approvedList.length} Approved', AppTheme.accentGreen, AppTheme.badgeGreenBg),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_note_rounded,
                        color: AppTheme.accentOrange,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Faculty Leave Approvals Management',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    _buildCountChip('${pendingList.length} Pending', AppTheme.accentOrange, AppTheme.badgeOrangeBg),
                    const SizedBox(width: 6),
                    _buildCountChip('${approvedList.length} Approved', AppTheme.accentGreen, AppTheme.badgeGreenBg),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          if (pendingList.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'No pending faculty leave applications to review.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingList.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = pendingList[index];
                return _buildLeaveCard(item);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequestItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                child: Text(
                  item.facultyName[0],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.facultyName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    Text(
                      '${item.designation} • ${item.leaveType} (${item.daysCount} Day)',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                item.dates,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.accentBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Reason: ${item.reason}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    item.status = 'Rejected';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Rejected leave for ${item.facultyName}')),
                  );
                },
                icon: const Icon(Icons.close, size: 14, color: AppTheme.accentRose),
                label: const Text('Reject', style: TextStyle(fontSize: 12, color: AppTheme.accentRose)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    item.status = 'Approved';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Approved leave request for ${item.facultyName}')),
                  );
                },
                icon: const Icon(Icons.check, size: 14, color: Colors.white),
                label: const Text('Approve', style: TextStyle(fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
