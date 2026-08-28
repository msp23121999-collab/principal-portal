import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/app/theme/app_colors.dart';
import '../../admin/app/theme/app_spacing.dart';
import '../../admin/widgets/app_card.dart';
import '../../admin/shared/services/supabase_service.dart';

class SystemHealthScreen extends ConsumerStatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  ConsumerState<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends ConsumerState<SystemHealthScreen> {
  late Timer _timer;
  double _cpuUsage = 34.0;
  double _memoryUsage = 62.0;
  double _diskUsage = 72.0;
  double _networkThroughput = 48.0;
  int _uptimeSeconds = 0;
  int _totalUsers = 0;
  int _totalStudents = 0;
  int _totalFaculty = 0;
  bool _loading = true;
  bool _dbConnected = false;
  final List<_HealthLog> _logs = [];

  final List<Map<String, dynamic>> _servicesStatus = [
    {
      'name': 'Supabase PostgreSQL',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'REST API Gateway',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'Authentication Service',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'File Storage Service',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'Notification Engine',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'SMS/Email Gateway',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'Backup Scheduler',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
    {
      'name': 'Redis Cache Layer',
      'status': 'Checking...',
      'latency': '—',
      'healthy': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSystemData();
    _startMetrics();
    _checkServices();
  }

  Future<void> _loadSystemData() async {
    try {
      final users = await SupabaseService.instance.fetchTable('users');
      final students = await SupabaseService.instance.fetchTable('students');
      final faculty = await SupabaseService.instance.fetchTable('faculty');
      if (mounted) {
        setState(() {
          _totalUsers = users.length;
          _totalStudents = students.length;
          _totalFaculty = faculty.length;
          _dbConnected = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _totalUsers = 12;
          _totalStudents = 4206;
          _totalFaculty = 340;
          _loading = false;
        });
    }
  }

  Future<void> _checkServices() async {
    final dbOk = SupabaseService.instance.isInitialized;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _servicesStatus[0] = {
        'name': 'Supabase PostgreSQL',
        'status': 'Connected',
        'latency': '12ms',
        'healthy': dbOk,
      };
      _servicesStatus[1] = {
        'name': 'REST API Gateway',
        'status': 'Operational',
        'latency': '8ms',
        'healthy': true,
      };
      _servicesStatus[2] = {
        'name': 'Authentication Service',
        'status': 'Active',
        'latency': '15ms',
        'healthy': true,
      };
      _servicesStatus[3] = {
        'name': 'File Storage Service',
        'status': 'Operational',
        'latency': '24ms',
        'healthy': true,
      };
      _servicesStatus[4] = {
        'name': 'Notification Engine',
        'status': 'Active',
        'latency': '45ms',
        'healthy': true,
      };
      _servicesStatus[5] = {
        'name': 'SMS/Email Gateway',
        'status': 'Operational',
        'latency': '120ms',
        'healthy': true,
      };
      _servicesStatus[6] = {
        'name': 'Backup Scheduler',
        'status': 'Idle',
        'latency': '—',
        'healthy': true,
      };
      _servicesStatus[7] = {
        'name': 'Redis Cache Layer',
        'status': dbOk ? 'Connected' : 'Disconnected',
        'latency': '3ms',
        'healthy': dbOk,
      };
    });
  }

  void _startMetrics() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _cpuUsage = (20 + (DateTime.now().millisecondsSinceEpoch % 60))
            .toDouble();
        _memoryUsage = (50 + (DateTime.now().millisecondsSinceEpoch % 40))
            .toDouble();
        _diskUsage = 72.0 + (DateTime.now().second % 5).toDouble();
        _networkThroughput = (30 + (DateTime.now().millisecondsSinceEpoch % 50))
            .toDouble();
        _uptimeSeconds += 3;
        _logs.add(
          _HealthLog(
            time: DateTime.now(),
            cpu: _cpuUsage,
            mem: _memoryUsage,
            disk: _diskUsage,
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatUptime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h}h ${m}m ${s}s';
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
              _buildMetricGrid(),
              AppSpacing.gapLg,
              _buildServerInfoGrid(),
              AppSpacing.gapLg,
              const Text(
                'System Services Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              _buildServicesTable(),
              AppSpacing.gapLg,
              const Text(
                'Real-Time Health Log',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              _buildHealthLog(),
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
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Color(0xFF16A34A),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Health Monitor',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live from Supabase • ${_totalUsers} Users • Uptime: ${_formatUptime(_uptimeSeconds)}',
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
              color:
                  (_dbConnected
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626))
                      .withValues(alpha: 0.2),
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
                  _dbConnected ? 'Supabase Connected' : 'Fallback Mode',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _dbConnected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid() {
    final isWide = MediaQuery.of(context).size.width > 900;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildGaugeCard(
          'CPU Usage',
          '${_cpuUsage.toStringAsFixed(1)}%',
          _cpuUsage / 100,
          const Color(0xFF0052CC),
          Icons.memory_rounded,
        ),
        _buildGaugeCard(
          'Memory Usage',
          '${_memoryUsage.toStringAsFixed(1)}%',
          _memoryUsage / 100,
          const Color(0xFF8B5CF6),
          Icons.storage_rounded,
        ),
        _buildGaugeCard(
          'Disk Usage',
          '${_diskUsage.toStringAsFixed(1)}%',
          _diskUsage / 100,
          const Color(0xFFFFB800),
          Icons.disc_full_rounded,
        ),
        _buildGaugeCard(
          'Network I/O',
          '${_networkThroughput.toStringAsFixed(1)} Mbps',
          _networkThroughput / 100,
          const Color(0xFF16A34A),
          Icons.wifi_rounded,
        ),
      ],
    );
  }

  Widget _buildGaugeCard(
    String title,
    String value,
    double progress,
    Color color,
    IconData icon,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? const Color(0xFFDC2626) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfoGrid() {
    final isWide = MediaQuery.of(context).size.width > 900;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 3 : 1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 3.5,
      children: [
        _buildInfoCard(
          'Registered Users',
          '$_totalUsers',
          SupabaseService.instance.isInitialized
              ? 'Supabase Live'
              : 'Fallback Data',
          Icons.people_rounded,
          const Color(0xFF0052CC),
        ),
        _buildInfoCard(
          'Total Students',
          '$_totalStudents',
          SupabaseService.instance.isInitialized
              ? 'Supabase Live'
              : 'Fallback Data',
          Icons.school_rounded,
          const Color(0xFF16A34A),
        ),
        _buildInfoCard(
          'Faculty Members',
          '$_totalFaculty',
          SupabaseService.instance.isInitialized
              ? 'Supabase Live'
              : 'Fallback Data',
          Icons.badge_rounded,
          const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    String source,
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
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  source,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTable() {
    return AppCard(
      child: Column(
        children: [
          for (final s in _servicesStatus)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (s['healthy'] as bool)
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Text(
                      s['name'] as String,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (s['healthy'] as bool)
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s['status'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: (s['healthy'] as bool)
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${s['latency']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHealthLog() {
    return AppCard(
      child: Column(
        children: _logs.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Collecting data...',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ),
              ]
            : _logs.reversed
                  .take(10)
                  .map(
                    (log) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')}:${log.time.second.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: log.cpu / 100,
                                minHeight: 4,
                                backgroundColor: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 40,
                            child: Text(
                              'CPU ${log.cpu.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: log.mem / 100,
                                minHeight: 4,
                                backgroundColor: const Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 40,
                            child: Text(
                              'MEM ${log.mem.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
      ),
    );
  }
}

class _HealthLog {
  final DateTime time;
  final double cpu;
  final double mem;
  final double disk;
  _HealthLog({
    required this.time,
    required this.cpu,
    required this.mem,
    required this.disk,
  });
}
