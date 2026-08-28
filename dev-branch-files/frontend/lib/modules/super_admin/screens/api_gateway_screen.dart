import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../admin/app/theme/app_colors.dart';
import '../../admin/app/theme/app_spacing.dart';
import '../../admin/widgets/app_card.dart';
import '../../admin/shared/services/supabase_service.dart';

class ApiGatewayScreen extends ConsumerStatefulWidget {
  const ApiGatewayScreen({super.key});

  @override
  ConsumerState<ApiGatewayScreen> createState() => _ApiGatewayScreenState();
}

class _ApiGatewayScreenState extends ConsumerState<ApiGatewayScreen> {
  List<Map<String, dynamic>> _systemSettings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final settings = await SupabaseService.instance.fetchTable(
        'system_settings',
      );
      if (mounted)
        setState(() {
          _systemSettings = settings;
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
              _buildGatewayGrid(),
              AppSpacing.gapLg,
              _buildEndpointRegistry(),
              AppSpacing.gapLg,
              _buildWebhookConfig(),
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
              Icons.alt_route_rounded,
              color: Color(0xFF8B5CF6),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API & Communication Gateway',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'REST Endpoints • SMS • Email • Notification Engine • Webhooks',
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
                  ? 'Supabase Live'
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

  Widget _buildGatewayGrid() {
    final isWide = MediaQuery.of(context).size.width > 900;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isWide ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _gatewayCard(
          'REST API',
          'Operational',
          '12 endpoints active',
          Icons.api_rounded,
          const Color(0xFF0052CC),
          true,
        ),
        _gatewayCard(
          'SMS Gateway',
          'Active',
          '2FA & Alerts running',
          Icons.sms_rounded,
          const Color(0xFF16A34A),
          true,
        ),
        _gatewayCard(
          'Email Service',
          'Operational',
          'SMTP connected',
          Icons.email_rounded,
          const Color(0xFF8B5CF6),
          true,
        ),
        _gatewayCard(
          'Push Notifications',
          'Active',
          'WebSocket live',
          Icons.notifications_active_rounded,
          const Color(0xFFFFB800),
          true,
        ),
      ],
    );
  }

  Widget _gatewayCard(
    String title,
    String status,
    String sub,
    IconData icon,
    Color color,
    bool isUp,
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
              Icon(icon, size: 20, color: color),
            ],
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isUp
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isUp
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointRegistry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'API Endpoint Registry',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '${_systemSettings.length} settings loaded',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            children: [
              _endpointRow(
                'GET',
                '/api/v1/students',
                'Fetch all students',
                true,
              ),
              _endpointRow(
                'POST',
                '/api/v1/students',
                'Create new student',
                true,
              ),
              _endpointRow(
                'GET',
                '/api/v1/faculty',
                'Fetch faculty list',
                true,
              ),
              _endpointRow(
                'PUT',
                '/api/v1/users/:id',
                'Update user profile',
                true,
              ),
              _endpointRow(
                'DELETE',
                '/api/v1/users/:id',
                'Remove user account',
                true,
              ),
              _endpointRow(
                'POST',
                '/api/v1/auth/login',
                'Authenticate user',
                true,
              ),
              _endpointRow(
                'GET',
                '/api/v1/attendance',
                'Get attendance records',
                true,
              ),
              _endpointRow(
                'POST',
                '/api/v1/notifications/send',
                'Send push notification',
                true,
              ),
              _endpointRow(
                'GET',
                '/api/v1/reports/dashboard',
                'Dashboard analytics',
                true,
              ),
              _endpointRow(
                'POST',
                '/api/v1/backup/trigger',
                'Trigger system backup',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _endpointRow(String method, String path, String desc, bool active) {
    final Color methodColor;
    switch (method) {
      case 'GET':
        methodColor = const Color(0xFF16A34A);
        break;
      case 'POST':
        methodColor = const Color(0xFF0052CC);
        break;
      case 'PUT':
        methodColor = const Color(0xFFFFB800);
        break;
      case 'DELETE':
        methodColor = const Color(0xFFDC2626);
        break;
      default:
        methodColor = const Color(0xFF64748B);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: methodColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              method,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: methodColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              path,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              desc,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: active ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  Widget _buildWebhookConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Webhook Configuration',
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
              _webhookRow(
                'Fee Payment Callback',
                'https://api.ksrce.ac.in/webhooks/fee-paid',
                'Active',
                const Color(0xFF16A34A),
              ),
              _webhookRow(
                'Student Registration',
                'https://api.ksrce.ac.in/webhooks/student-reg',
                'Active',
                const Color(0xFF16A34A),
              ),
              _webhookRow(
                'Exam Result Published',
                'https://api.ksrce.ac.in/webhooks/results',
                'Inactive',
                const Color(0xFF94A3B8),
              ),
              _webhookRow(
                'SMS Delivery Report',
                'https://api.ksrce.ac.in/webhooks/sms-status',
                'Active',
                const Color(0xFF16A34A),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _webhookRow(
    String title,
    String url,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
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
          const SizedBox(width: 8),
          Icon(Icons.edit_outlined, size: 16, color: const Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
