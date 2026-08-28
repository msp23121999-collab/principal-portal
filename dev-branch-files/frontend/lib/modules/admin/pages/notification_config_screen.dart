import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class NotificationConfigScreen extends StatefulWidget {
  const NotificationConfigScreen({super.key});

  @override
  State<NotificationConfigScreen> createState() => _NotificationConfigScreenState();
}

class _NotificationConfigScreenState extends State<NotificationConfigScreen> {
  bool _globalNotif = true;
  bool _academicTriggers = true;
  bool _systemEvents = true;
  bool _financialTriggers = false;
  bool _emergencyMedicalAlerts = true;
  bool _isSaving = false;

  void _saveNotificationSettings() async {
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
          content: Text('Notification dispatch rules updated in PostgreSQL notification_templates.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _previewTemplate(String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, color: Color(0xFF0052CC)),
              const SizedBox(width: 10),
              Text('Template Preview — $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rendered Push / In-App Card:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC)),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close Preview'),
            ),
          ],
        ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) => AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.gapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppTypography.labelLarge),
              Text(label, style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Routing & Templates', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stat Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatCard('Dispatch Hub', 'Online', Icons.hub_rounded, AppColors.success),
                    AppSpacing.gapSm,
                    _buildStatCard('Push Queue', '12 Pending', Icons.notifications_active_rounded, const Color(0xFF0052CC)),
                    AppSpacing.gapSm,
                    _buildStatCard('In-App Delivery', '100%', Icons.verified_rounded, AppColors.success),
                    AppSpacing.gapSm,
                    _buildStatCard('Failure Rate', '0.0%', Icons.analytics_rounded, AppColors.error),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // Configurations Toggles
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Alert Routing', style: AppTypography.h3),
                    Text('Choose categories allowed to broadcast to student & faculty devices.', style: AppTypography.bodySmall),
                    AppSpacing.gapLg,
                    SwitchListTile(
                      title: const Text('Global Notifications'),
                      subtitle: const Text('Toggles complete notification relays.'),
                      value: _globalNotif,
                      activeThumbColor: const Color(0xFF0052CC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _globalNotif = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Academic Triggers'),
                      subtitle: const Text('Dispatches notifications on exam timetables, attendance alerts, and marks.'),
                      value: _academicTriggers,
                      activeThumbColor: const Color(0xFF0052CC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _academicTriggers = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Emergency Medical & Blood Alerts'),
                      subtitle: const Text('Instant high-priority broadcasts for blood bank requests and clinic alerts.'),
                      value: _emergencyMedicalAlerts,
                      activeThumbColor: const Color(0xFF0052CC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _emergencyMedicalAlerts = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('System Events'),
                      subtitle: const Text('Sends alerts on database backup completions, security threats, or maintenance.'),
                      value: _systemEvents,
                      activeThumbColor: const Color(0xFF0052CC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _systemEvents = val),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Financial Triggers'),
                      subtitle: const Text('Sends alerts on outstanding fee summaries or dues collection deadlines.'),
                      value: _financialTriggers,
                      activeThumbColor: const Color(0xFF0052CC),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _financialTriggers = val),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // Templates Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notification Templates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Pre-formatted templates used by system triggers.', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.medical_services_rounded, color: Colors.red),
                      title: const Text('Emergency Blood Request', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Triggers high priority alert to registered blood donors.'),
                      trailing: TextButton(
                        onPressed: () => _previewTemplate('Emergency Blood Request: O-', 'B+ / O- Blood required urgently at Campus Partner Clinic node.'),
                        child: const Text('Preview'),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.event_note_rounded, color: Color(0xFF0052CC)),
                      title: const Text('Exam Timetable Published', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text('Broadcasts semester exam schedule to students.'),
                      trailing: TextButton(
                        onPressed: () => _previewTemplate('End-Semester Exam Timetable Published', 'End-Semester theory examination timetable for Fall 2026 is now available.'),
                        child: const Text('Preview'),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              AppButton(
                label: 'Save Notification Settings',
                isLoading: _isSaving,
                onPressed: _saveNotificationSettings,
              ),
            ],
          ),
        ),
      ),
    );
}
