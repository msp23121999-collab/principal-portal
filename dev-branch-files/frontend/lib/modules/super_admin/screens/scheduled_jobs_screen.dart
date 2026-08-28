import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/app/theme/app_colors.dart';
import '../../admin/app/theme/app_spacing.dart';
import '../../admin/widgets/app_card.dart';
import '../../admin/shared/services/supabase_service.dart';

class ScheduledJobsScreen extends ConsumerStatefulWidget {
  const ScheduledJobsScreen({super.key});

  @override
  ConsumerState<ScheduledJobsScreen> createState() =>
      _ScheduledJobsScreenState();
}

class _ScheduledJobsScreenState extends ConsumerState<ScheduledJobsScreen> {
  List<Map<String, dynamic>> _auditLogs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final logs = await SupabaseService.instance.fetchTable('audit_logs');
      if (mounted)
        setState(() {
          _auditLogs = logs;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              AppSpacing.gapLg,
              _buildActiveJobs(),
              AppSpacing.gapLg,
              _buildJobLogs(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00102B), Color(0xFF001B44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFA78BFA),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled Jobs & Automation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cron Tasks • Batch Processing • Automation Rules',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: SupabaseService.instance.isInitialized
                  ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                  : const Color(0xFFFFB800).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: SupabaseService.instance.isInitialized
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFFFB800),
              ),
            ),
            child: Text(
              SupabaseService.instance.isInitialized
                  ? '${_auditLogs.length} Logs'
                  : 'Fallback Mode',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: SupabaseService.instance.isInitialized
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFFFB800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveJobs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Scheduled Jobs',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              _jobRow(
                'Daily Database Backup',
                'Every day at 02:00 AM',
                'Last: Today 02:00',
                'Success',
                const Color(0xFF16A34A),
              ),
              _jobRow(
                'Stale Session Cleanup',
                'Every 6 hours',
                'Last: 06:00 AM',
                'Success',
                const Color(0xFF16A34A),
              ),
              _jobRow(
                'Attendance Auto-Mark',
                'Every day at 09:30 AM',
                'Last: Today 09:30',
                'Success',
                const Color(0xFF16A34A),
              ),
              _jobRow(
                'Fee Reminder Dispatch',
                'Every Mon & Wed 10:00 AM',
                'Last: Mon 10:00',
                'Success',
                const Color(0xFF16A34A),
              ),
              _jobRow(
                'Exam Registration Reminder',
                'Daily at 08:00 AM (Aug-Sep)',
                'Last: Today 08:00',
                'Success',
                const Color(0xFF16A34A),
              ),
              _jobRow(
                'System Health Report',
                'Every Friday 11:00 PM',
                'Last: Fri 11:00',
                'Success',
                const Color(0xFF16A34A),
              ),
              _jobRow(
                'Data Sync to Analytics',
                'Every hour',
                'Last: 10:00 AM',
                'Running',
                const Color(0xFF0052CC),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _jobRow(
    String name,
    String schedule,
    String lastRun,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.schedule_rounded, size: 18, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  schedule,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              lastRun,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobLogs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Job Logs from Supabase',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${_auditLogs.length} logs',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _auditLogs.isEmpty
              ? Column(
                  children: [
                    _logItem(
                      '10:00 AM',
                      'Data Sync to Analytics',
                      '1,240 records synced · Duration: 12s',
                      const Color(0xFF0052CC),
                    ),
                    _logItem(
                      '09:30 AM',
                      'Attendance Auto-Mark',
                      '3,890 students marked present · Duration: 8s',
                      const Color(0xFF16A34A),
                    ),
                    _logItem(
                      '08:00 AM',
                      'Exam Registration Reminder',
                      '245 emails sent · Duration: 15s',
                      const Color(0xFF16A34A),
                    ),
                    _logItem(
                      '06:00 AM',
                      'Stale Session Cleanup',
                      '42 stale sessions removed · Duration: 3s',
                      const Color(0xFF16A34A),
                    ),
                    _logItem(
                      '02:00 AM',
                      'Daily Database Backup',
                      'Size: 1.2 GB · Tables: 12 · Duration: 45s',
                      const Color(0xFF16A34A),
                    ),
                  ],
                )
              : Column(
                  children: _auditLogs
                      .take(10)
                      .map(
                        (l) => _logItem(
                          l['timestamp']?.toString().substring(11, 16) ??
                              '--:--',
                          l['description']?.toString() ?? 'Job',
                          'Operator: ${l['operator_name'] ?? 'System'}',
                          const Color(0xFF0052CC),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _logItem(String time, String job, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              time,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
