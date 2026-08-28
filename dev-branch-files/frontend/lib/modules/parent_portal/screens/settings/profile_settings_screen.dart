import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _emailNotify = true;
  bool _smsNotify = true;
  bool _feeNotify = true;
  bool _examNotify = true;
  bool _twoFactor = false;

  @override
  Widget build(BuildContext context) {
    final parent = MockData.currentParent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Parent Profile & Account Settings'),
            const SizedBox(height: 16),

            // ── Parent Profile Card ───────────────────────────────────────
            CustomCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, size: 36, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parent.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Relationship: ${parent.relationship}',
                              style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      SecondaryButton(
                        text: 'Edit Profile',
                        icon: Icons.edit_outlined,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile edit mode enabled')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _row('Registered Email ID', parent.email, Icons.email_outlined),
                  _row('Registered Mobile Number', parent.mobile, Icons.phone_android_outlined),
                  _row('Account Status', 'Verified Parent Account', Icons.verified_user_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Notification Preferences ─────────────────────────────────
            const SectionHeader(title: 'Notification & Alert Preferences'),
            CustomCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Instant SMS Alerts for Absenteeism', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Receive an instant SMS if your ward is marked absent for any period.', style: TextStyle(fontSize: 12)),
                    value: _smsNotify,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _smsNotify = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Weekly Academic Progress Digest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Receive weekly summary email reports on marks, attendance, and assignments.', style: TextStyle(fontSize: 12)),
                    value: _emailNotify,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _emailNotify = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Fee Due Date Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Receive reminders 15 days prior to fee installment due dates.', style: TextStyle(fontSize: 12)),
                    value: _feeNotify,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _feeNotify = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Examination & Timetable Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Receive notifications when exam dates and hall tickets are published.', style: TextStyle(fontSize: 12)),
                    value: _examNotify,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _examNotify = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Account Security ─────────────────────────────────────────
            const SectionHeader(title: 'Account Security & Login'),
            CustomCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Require OTP code via mobile SMS on every new login.', style: TextStyle(fontSize: 12)),
                    value: _twoFactor,
                    activeColor: AppTheme.accentColor,
                    onChanged: (val) => setState(() => _twoFactor = val),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: AppTheme.primaryColor),
                    title: const Text('Change Account Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Update your portal login password for enhanced security.', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showChangePasswordModal(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _showChangePasswordModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 20),
              const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Current Password')),
              const SizedBox(height: 12),
              const TextField(obscureText: true, decoration: InputDecoration(labelText: 'New Password')),
              const SizedBox(height: 12),
              const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Confirm New Password')),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Update Password',
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated successfully!')),
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
