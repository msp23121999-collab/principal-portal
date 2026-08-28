import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/app/theme/app_colors.dart';
import '../../admin/app/theme/app_spacing.dart';
import '../../admin/widgets/app_card.dart';
import '../../admin/shared/services/supabase_service.dart';

class CommunicationGatewayScreen extends ConsumerStatefulWidget {
  const CommunicationGatewayScreen({super.key});

  @override
  ConsumerState<CommunicationGatewayScreen> createState() =>
      _CommunicationGatewayScreenState();
}

class _CommunicationGatewayScreenState
    extends ConsumerState<CommunicationGatewayScreen> {
  List<Map<String, dynamic>> _notificationConfigs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final configs = await SupabaseService.instance.fetchTable(
        'notification_config',
      );
      if (mounted)
        setState(() {
          _notificationConfigs = configs;
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
              _buildChannelGrid(),
              AppSpacing.gapLg,
              _buildTemplates(),
              AppSpacing.gapLg,
              _buildAnalytics(),
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
              color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFF06B6D4),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Communication Gateway',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'SMS • Email • Push Notifications • Templates • Analytics',
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
                  ? '${_notificationConfigs.length} Configs'
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

  Widget _buildChannelGrid() {
    final isWide = MediaQuery.of(context).size.width > 900;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 3 : 1,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _channelCard(
          'SMS Gateway',
          'Active',
          '12,480 sent today',
          Icons.sms_rounded,
          const Color(0xFF16A34A),
          0.68,
        ),
        _channelCard(
          'Email Service',
          'Operational',
          '8,230 delivered today',
          Icons.email_rounded,
          const Color(0xFF0052CC),
          0.92,
        ),
        _channelCard(
          'Push Notifications',
          'Active',
          '4,150 pushed today',
          Icons.notifications_active_rounded,
          const Color(0xFF8B5CF6),
          0.74,
        ),
      ],
    );
  }

  Widget _channelCard(
    String title,
    String status,
    String detail,
    IconData icon,
    Color color,
    double progress,
  ) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Communication Templates',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
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
              : Column(
                  children: [
                    if (_notificationConfigs.isEmpty) ...[
                      _templateRow(
                        'Welcome Email',
                        'Onboarding',
                        'Email',
                        true,
                      ),
                      _templateRow('Fee Reminder', 'Finance', 'SMS', true),
                      _templateRow(
                        'Exam Notification',
                        'Academics',
                        'Email',
                        true,
                      ),
                      _templateRow('Attendance Alert', 'Faculty', 'SMS', true),
                      _templateRow(
                        'Result Published',
                        'Academics',
                        'Push',
                        true,
                      ),
                      _templateRow('Password Reset', 'Auth', 'Email', true),
                      _templateRow(
                        'Event Invitation',
                        'Admin',
                        'Email + Push',
                        true,
                      ),
                    ] else
                      ..._notificationConfigs.map(
                        (c) => _templateRow(
                          c['title']?.toString() ?? 'Template',
                          c['category']?.toString() ?? 'General',
                          c['channel']?.toString() ?? 'Email',
                          c['status']?.toString() == 'Active',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _templateRow(
    String name,
    String category,
    String channel,
    bool active,
  ) {
    final Color channelColor = channel == 'SMS'
        ? const Color(0xFF16A34A)
        : (channel == 'Email'
              ? const Color(0xFF0052CC)
              : const Color(0xFF8B5CF6));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
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
                  category,
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
              color: channelColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              channel,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
                color: channelColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 16,
            color: active ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Analytics (Last 7 Days)',
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
              _analyticsBar('Monday', 840, 960),
              _analyticsBar('Tuesday', 920, 1010),
              _analyticsBar('Wednesday', 780, 890),
              _analyticsBar('Thursday', 1010, 1150),
              _analyticsBar('Friday', 1230, 1340),
              _analyticsBar('Saturday', 340, 420),
              _analyticsBar('Sunday', 120, 180),
            ],
          ),
        ),
      ],
    );
  }

  Widget _analyticsBar(String day, int sms, int email) {
    final maxVal = 1400.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        height: 14,
                        width: (sms / maxVal) * 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        height: 14,
                        width: (email / maxVal) * 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sms SMS',
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$email Email',
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF0052CC),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
