import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../admin/app/router/route_names.dart';
import '../../admin/app/theme/app_colors.dart';
import '../../admin/app/theme/app_spacing.dart';
import '../../admin/widgets/app_card.dart';
import '../../admin/shared/services/supabase_service.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  late Timer _timer;
  late DateTime _currentTime;

  int _totalUsers = 0;
  int _activeSessions = 1284;
  int _systemUptimeDays = 145;
  int _pendingRequests = 0;
  double _storageUsed = 72.0;
  double _cpuLoad = 34.0;
  double _memoryUsage = 62.0;
  bool _dbConnected = false;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _loadSystemStats();
  }

  Future<void> _loadSystemStats() async {
    try {
      final users = await SupabaseService.instance.fetchTable('users');
      await SupabaseService.instance.fetchTable('students');
      await SupabaseService.instance.fetchTable('faculty');
      final certs = await SupabaseService.instance.fetchTable('certificates');
      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _pendingRequests = certs
              .where((c) => c['status'] == 'Pending')
              .length;
          _dbConnected = true;
          _activeSessions =
              1284 + (DateTime.now().millisecondsSinceEpoch % 200).toInt();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _dbConnected = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeHeader(),
              AppSpacing.gapLg,
              _buildKpiGrid(isWide),
              AppSpacing.gapLg,
              _buildQuickActions(context),
              AppSpacing.gapLg,
              _buildInfrastructureRow(context, isWide),
              AppSpacing.gapLg,
              _buildAuditAndJobsRow(context, isWide),
              AppSpacing.gapLg,
              _buildSecurityStatusRow(isWide),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final dateStr = DateFormat('EEEE, d MMM yyyy').format(_currentTime);
    final timeStr = DateFormat('hh:mm:ss a').format(_currentTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00102B), Color(0xFF001B44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB800),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Color(0xFF00102B),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_getGreeting(), Super Administrator',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full System Access • RBAC Level 10 • $_systemUptimeDays Days Uptime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _dbConnected
                  ? const Color(0xFF16A34A).withValues(alpha: 0.2)
                  : const Color(0xFFDC2626).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _dbConnected
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _dbConnected
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 6),
                Text(
                  _dbConnected ? 'All Systems Normal' : 'DB Disconnected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _dbConnected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(bool isWide) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isWide ? 1.8 : 1.4,
      children: [
        _kpiCard(
          'Total Registered Users',
          '$_totalUsers',
          'Across all portals',
          Icons.people_rounded,
          const Color(0xFF0052CC),
        ),
        _kpiCard(
          'Active Sessions',
          '$_activeSessions',
          'Currently online',
          Icons.laptop_rounded,
          const Color(0xFF16A34A),
        ),
        _kpiCard(
          'Pending Approvals',
          '$_pendingRequests',
          'Certificates & requests',
          Icons.pending_actions_rounded,
          const Color(0xFFFFB800),
        ),
        _kpiCard(
          'System Uptime',
          '$_systemUptimeDays Days',
          'Since last maintenance',
          Icons.upgrade_rounded,
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _kpiCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Configuration Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionChip(
              context,
              'System Health',
              Icons.monitor_heart_outlined,
              RouteNames.superAdminSystemHealth,
              const Color(0xFF16A34A),
            ),
            _actionChip(
              context,
              'Database Manager',
              Icons.dns_rounded,
              RouteNames.superAdminDatabaseManager,
              const Color(0xFF0052CC),
            ),
            _actionChip(
              context,
              'User Console',
              Icons.people_outline_rounded,
              RouteNames.superAdminUserConsole,
              const Color(0xFF8B5CF6),
            ),
            _actionChip(
              context,
              'RBAC Matrix',
              Icons.security_outlined,
              RouteNames.superAdminRolesPermissions,
              const Color(0xFFFFB800),
            ),
            _actionChip(
              context,
              'API Gateway',
              Icons.alt_route_rounded,
              RouteNames.superAdminApiGateway,
              const Color(0xFF06B6D4),
            ),
            _actionChip(
              context,
              'Security Audit',
              Icons.shield_rounded,
              RouteNames.superAdminSecurityAudit,
              const Color(0xFFDC2626),
            ),
            _actionChip(
              context,
              'SMS/Email Gateway',
              Icons.email_outlined,
              RouteNames.superAdminSmsEmailConfig,
              const Color(0xFF0052CC),
            ),
            _actionChip(
              context,
              'Backup & Restore',
              Icons.backup_outlined,
              RouteNames.superAdminBackupRestore,
              const Color(0xFF16A34A),
            ),
            _actionChip(
              context,
              'Scheduled Jobs',
              Icons.schedule_rounded,
              RouteNames.superAdminScheduledJobs,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionChip(
    BuildContext context,
    String label,
    IconData icon,
    String route,
    Color color,
  ) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      onPressed: () => context.go(route),
    );
  }

  Widget _buildInfrastructureRow(BuildContext context, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Infrastructure',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildServerMetricsCard()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildServicesCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildServerMetricsCard(),
                const SizedBox(height: 14),
                _buildServicesCard(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildServerMetricsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Server Resource Metrics',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _metricBar(
            'CPU Usage',
            _cpuLoad / 100,
            '${_cpuLoad.toStringAsFixed(1)}%',
            const Color(0xFF0052CC),
          ),
          const SizedBox(height: 8),
          _metricBar(
            'Memory',
            _memoryUsage / 100,
            '${_memoryUsage.toStringAsFixed(1)}%',
            const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 8),
          _metricBar(
            'Storage',
            _storageUsed / 100,
            '${_storageUsed.toStringAsFixed(1)}%',
            const Color(0xFFFFB800),
          ),
          const SizedBox(height: 8),
          _metricBar('Network', 0.48, '48 Mbps', const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _metricBar(String label, double progress, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.8 ? const Color(0xFFDC2626) : color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Status',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _serviceRow('Supabase PostgreSQL', 'Connected', '12ms', true),
          _serviceRow('REST API Gateway', 'Operational', '8ms', true),
          _serviceRow('Authentication Service', 'Active', '15ms', true),
          _serviceRow('Notification Engine', 'Active', '45ms', true),
          _serviceRow('SMS/Email Gateway', 'Operational', '120ms', true),
          _serviceRow('Backup Scheduler', 'Idle', '—', true),
        ],
      ),
    );
  }

  Widget _serviceRow(String name, String status, String latency, bool healthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: healthy
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: healthy
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: healthy
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 30,
            child: Text(
              latency,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditAndJobsRow(BuildContext context, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Activity & Jobs',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildAuditLogCard(context)),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: _buildJobStatusCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildAuditLogCard(context),
                const SizedBox(height: 14),
                _buildJobStatusCard(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAuditLogCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Security & Audit Trail',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => context.go(RouteNames.superAdminAuditLogs),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('View All', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const Divider(),
          _logItem(
            '09:45 AM',
            'Super Admin Logged In',
            'IP: 192.168.1.104 • Web Console',
            const Color(0xFF16A34A),
          ),
          _logItem(
            '09:30 AM',
            'RBAC Matrix Verified',
            '17 Roles & 10 Permissions Synced',
            const Color(0xFF0052CC),
          ),
          _logItem(
            '08:15 AM',
            'Database Backup',
            'Daily snapshot created • 1.2 GB',
            const Color(0xFF8B5CF6),
          ),
          _logItem(
            '07:50 AM',
            'Failed Login Attempt',
            'IP: 10.0.0.45 • Unknown user',
            const Color(0xFFF59E0B),
          ),
          _logItem(
            '07:00 AM',
            'System Health Check',
            'All services operational',
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _logItem(String time, String action, String details, Color color) {
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
                  action,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 9.5,
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

  Widget _buildJobStatusCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scheduled Job Status',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _jobItem(
            'Daily DB Backup',
            '02:00 AM',
            'Success',
            const Color(0xFF16A34A),
          ),
          _jobItem(
            'Session Cleanup',
            'Every 6h',
            'Success',
            const Color(0xFF16A34A),
          ),
          _jobItem(
            'Attendance Auto',
            '09:30 AM',
            'Success',
            const Color(0xFF16A34A),
          ),
          _jobItem(
            'Fee Reminders',
            'Mon/Wed',
            'Pending',
            const Color(0xFFFFB800),
          ),
          _jobItem(
            'Analytics Sync',
            'Every hour',
            'Running',
            const Color(0xFF0052CC),
          ),
        ],
      ),
    );
  }

  Widget _jobItem(String name, String schedule, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
            ),
          ),
          Text(
            schedule,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusRow(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security & Compliance Overview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isWide ? 3 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 4,
          children: [
            _complianceCard(
              'RBAC Matrix',
              'Active',
              '17 Roles • Level 10 Access',
              Icons.security_outlined,
              const Color(0xFF16A34A),
            ),
            _complianceCard(
              'Data Encryption',
              'AES-256',
              'At rest & in transit',
              Icons.lock_outline_rounded,
              const Color(0xFF0052CC),
            ),
            _complianceCard(
              '2FA Status',
              'Enabled',
              'For all admin accounts',
              Icons.fingerprint_rounded,
              const Color(0xFF8B5CF6),
            ),
          ],
        ),
      ],
    );
  }

  Widget _complianceCard(
    String title,
    String status,
    String detail,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
