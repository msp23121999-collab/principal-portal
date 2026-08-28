import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

class SmsEmailConfigScreen extends StatefulWidget {
  const SmsEmailConfigScreen({super.key});

  @override
  State<SmsEmailConfigScreen> createState() => _SmsEmailConfigScreenState();
}

class _SmsEmailConfigScreenState extends State<SmsEmailConfigScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _smtpHostController = TextEditingController(text: 'smtp.ksrce.ac.in');
  final _smtpPortController = TextEditingController(text: '587');
  final _senderEmailController = TextEditingController(text: 'notifications@cams.ksrce.ac.in');
  final _smsApiKeyController = TextEditingController(text: 'tw_live_99210940129031209312391029312');
  final _testPhoneController = TextEditingController(text: '+91 98765 43210');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _senderEmailController.dispose();
    _smsApiKeyController.dispose();
    _testPhoneController.dispose();
    super.dispose();
  }

  void _showTestMessageDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        var isSending = false;
        return StatefulBuilder(
          builder: (builderCtx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.send_rounded, color: Color(0xFF0052CC)),
                  SizedBox(width: 10),
                  Text('Send Gateway Test Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: isSending
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0052CC)),
                        SizedBox(height: 16),
                        Text('Connecting to Twilio / SMTP gateway server...', style: TextStyle(fontSize: 12)),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppTextField(
                          label: 'Target Test Phone Number / Email',
                          controller: _testPhoneController,
                        ),
                      ],
                    ),
              actions: isSending
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC)),
                        onPressed: () async {
                          setDialogState(() {
                            isSending = true;
                          });

                          await Future.delayed(const Duration(seconds: 2));

                          if (!mounted || !dialogCtx.mounted) return;
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test SMS & Email successfully delivered via gateway.'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Dispatch Test Message'),
                      ),
                    ],
            ),
        );
      },
    );
  }

  void _applyConfiguration() async {
    setState(() {
      _isSaving = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SMTP and SMS Gateway parameters applied & verified.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SMS & Email Gateway Setup', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Send Test', style: TextStyle(fontSize: 12)),
              onPressed: _showTestMessageDialog,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0052CC),
          indicatorColor: const Color(0xFF0052CC),
          tabs: const [
            Tab(text: 'Gateways Setup'),
            Tab(text: 'Message Templates'),
            Tab(text: 'Delivery Rules'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Gateways Tab (SMTP and SMS Credentials Form)
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quota Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Daily Dispatch Quota Usage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('85% Used', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: const LinearProgressIndicator(
                            value: 0.85,
                            minHeight: 8,
                            backgroundColor: Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('8,500 of 10,000 SMS credits used today. Resets at Midnight.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SMTP Email Server Configuration', style: AppTypography.h3),
                        Text('Mail servers for official academic transcript and invoice dispatches.', style: AppTypography.bodySmall),
                        AppSpacing.gapLg,
                        AppTextField(
                          label: 'SMTP Host Server',
                          controller: _smtpHostController,
                        ),
                        AppSpacing.gapMd,
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Port Mapping',
                                controller: _smtpPortController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            AppSpacing.gapMd,
                            Expanded(
                              child: AppTextField(
                                label: 'Sender Email Address',
                                controller: _senderEmailController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SMS Gateway Integration (Twilio / Fast2SMS)', style: AppTypography.h3),
                        Text('SMS API endpoint credentials for OTPs & Emergency alerts.', style: AppTypography.bodySmall),
                        AppSpacing.gapLg,
                        AppTextField(
                          label: 'SMS Provider Gateway Key',
                          controller: _smsApiKeyController,
                          obscureText: true,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  AppButton(
                    label: 'Apply & Verify Gateway Configuration',
                    isLoading: _isSaving,
                    onPressed: _applyConfiguration,
                  ),
                ],
              ),
            ),

            // Templates Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('System Dispatch Templates', style: AppTypography.h3),
                    Text('Automated text formats used by notification triggers.', style: AppTypography.bodySmall),
                    AppSpacing.gapLg,
                    _buildTemplateRow('Emergency Blood Request Alert', 'Emergency {type} blood required urgently at Hospital {name}. Contact: {phone}'),
                    const Divider(),
                    _buildTemplateRow('User Verification OTP', 'Your CAMS security verification code is: {otp}. Valid for 10 minutes.'),
                    const Divider(),
                    _buildTemplateRow('Semester Grade Publish Alert', 'Dear {name}, your Semester {sem} grades have been published on student portal.'),
                  ],
                ),
              ),
            ),

            // Delivery Rules Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Delivery & Retries Policies', style: AppTypography.h3),
                    Text('Failsafe configurations for SMS & Email dispatches.', style: AppTypography.bodySmall),
                    AppSpacing.gapLg,
                    _buildDeliveryRule('Maximum Dispatch Queue Retries', '3 attempts'),
                    const Divider(),
                    _buildDeliveryRule('Failure Relay Fallback', 'Email Node Failover'),
                    const Divider(),
                    _buildDeliveryRule('Rate Limit Interval Buffer', '500 milliseconds'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildTemplateRow(String title, String desc) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(desc, style: AppTypography.bodySmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF0052CC)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template editor open (simulated)')),
              );
            },
          ),
        ],
      ),
    );

  Widget _buildDeliveryRule(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelLarge),
          Text(value, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
}
