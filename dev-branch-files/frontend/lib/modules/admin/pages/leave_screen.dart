import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';
class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  final List<Map<String, dynamic>> _fallbackData = [
    {'applicant': 'Dr. Suresh Kumar', 'role': 'Faculty', 'type': 'Casual Leave', 'duration': '2 Days (26 - 27 Jul)', 'reason': 'Personal Work', 'status': 'Pending'},
    {'applicant': 'Aravind Swamy', 'role': 'Student', 'type': 'On-Duty (OD)', 'duration': '1 Day (28 Jul)', 'reason': 'Inter-College Symposium', 'status': 'Approved'},
    {'applicant': 'Bhavana Devi', 'role': 'Student', 'type': 'Medical Leave', 'duration': '3 Days (24 - 26 Jul)', 'reason': 'Fever', 'status': 'Approved'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = <Map<String, dynamic>>[];
      if (result.isNotEmpty) {
        setState(() {
          _data = result.map((e) => {
            'applicant': e['employee_name'] ?? e['applicant'] ?? '',
            'role': e['role'] ?? 'Faculty',
            'type': e['leave_type'] ?? e['type'] ?? '',
            'duration': e['duration'] ?? '${e['from_date']} - ${e['to_date']}',
            'reason': e['reason'] ?? '',
            'status': e['status'] ?? 'Pending',
          }).toList();
          _loading = false;
        });
      } else {
        setState(() { _data = List.from(_fallbackData); _loading = false; });
      }
    } catch (_) {
      setState(() { _data = List.from(_fallbackData); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Leave & OD Requests Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leave & OD Requests Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  const Text('Leave Applications Registry', style: AppTypography.h2),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Apply Leave'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052CC),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapLg,

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _data.length,
                itemBuilder: (context, idx) {
                  final item = _data[idx];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 550;
                          return Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              SizedBox(
                                width: isWide ? (constraints.maxWidth - 200) : constraints.maxWidth,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                                      child: const Icon(Icons.time_to_leave_rounded, color: Color(0xFF0052CC), size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(item['applicant'] as String, style: AppTypography.h3),
                                              AppStatusBadge(status: item['status'] as String),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${item['role']} • Type: ${item['type']} • Duration: ${item['duration']} • Reason: ${item['reason']}',
                                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton(onPressed: () {}, child: const Text('Approve')),
                                  const SizedBox(width: 8),
                                  OutlinedButton(onPressed: () {}, child: const Text('Reject')),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
