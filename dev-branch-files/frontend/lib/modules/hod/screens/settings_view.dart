import 'package:flutter/material.dart';
import '../theme.dart';
import '../responsive.dart';
import '../../faculty/services/profile_service.dart';

class SettingsModuleView extends StatefulWidget {
  const SettingsModuleView({super.key});

  @override
  State<SettingsModuleView> createState() => _SettingsModuleViewState();
}

class _SettingsModuleViewState extends State<SettingsModuleView> {
  int _activeTab = 0;

  // Department config controllers
  final _deptNameCtrl = TextEditingController(text: 'Department of Computer Science & Engineering (CSE)');
  final _deptCodeCtrl = TextEditingController(text: 'DEP-CSE-001');
  final _academicYearCtrl = TextEditingController(text: '2025-2026');
  final _attendanceThreshCtrl = TextEditingController(text: '75.0');
  final _minCgpaCtrl = TextEditingController(text: '5.0');

  // Notification prefs
  bool _emailNotifs = true;
  bool _smsNotifs = true;
  bool _pushNotifs = true;
  bool _leaveEmailAlert = true;
  bool _attendanceAlert = true;

  // Security
  bool _2faEnabled = true;
  bool _sessionTimeout = true;

  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_deptNameCtrl, _deptCodeCtrl, _academicYearCtrl, _attendanceThreshCtrl, _minCgpaCtrl]) {
      c.addListener(() => setState(() => _hasUnsavedChanges = true));
    }
  }

  @override
  void dispose() {
    _deptNameCtrl.dispose();
    _deptCodeCtrl.dispose();
    _academicYearCtrl.dispose();
    _attendanceThreshCtrl.dispose();
    _minCgpaCtrl.dispose();
    super.dispose();
  }

  void _saveAllChanges() {
    setState(() => _hasUnsavedChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All settings saved successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentGreen,
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSectionHeader(
            title: 'Department & System Settings Portal',
            breadcrumb: 'Settings > HOD Profile, Security, Department Rules & Digital Signature',
            academicYear: 'Academic Year 2025 - 2026',
            actions: [
              if (_hasUnsavedChanges)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Unsaved Changes', style: TextStyle(fontSize: 11, color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                ),
              ElevatedButton.icon(
                onPressed: _saveAllChanges,
                icon: const Icon(Icons.save, size: 16, color: Colors.white),
                label: const Text('Save All Changes', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: _hasUnsavedChanges ? AppTheme.accentOrange : AppTheme.accentGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Cards
          Row(
            children: [
              Expanded(child: _buildKpiCard('Profile Completion', '95%', 'Verified Profile', Icons.account_circle, AppTheme.accentBlue)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard('Security', _2faEnabled ? '2FA Active' : '2FA Disabled', _2faEnabled ? 'High Protection' : 'Vulnerable', Icons.security, _2faEnabled ? AppTheme.accentGreen : AppTheme.accentRose)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard('Active Sessions', '2 Devices', 'Windows & Mobile', Icons.devices, AppTheme.accentPurple)),
              const SizedBox(width: 8),
              Expanded(child: _buildKpiCard('Last Login', 'Today 01:50 PM', 'IP: 192.168.1.42', Icons.history, AppTheme.accentTeal)),
            ],
          ),
          const SizedBox(height: 16),

          // Tab Navigation
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCompactTab(
                  label: 'Department Config',
                  icon: Icons.business,
                  isActive: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                _buildCompactTab(
                  label: 'Account & 2FA',
                  icon: Icons.security,
                  isActive: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),
                _buildCompactTab(
                  label: 'Notification Prefs',
                  icon: Icons.notifications_active,
                  isActive: _activeTab == 2,
                  onTap: () => setState(() => _activeTab = 2),
                ),
                _buildCompactTab(
                  label: 'Digital Signature',
                  icon: Icons.draw,
                  isActive: _activeTab == 3,
                  onTap: () => setState(() => _activeTab = 3),
                ),
                _buildCompactTab(
                  label: 'Activity Log',
                  icon: Icons.history,
                  isActive: _activeTab == 4,
                  onTap: () => setState(() => _activeTab = 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 520,
            child: _buildActiveSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary), maxLines: 1),
          Icon(icon, color: color, size: 16),
        ]),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted), maxLines: 1),
      ]),
    );
  }

  Widget _buildDeptConfigSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Department Configuration & Academic Parameters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              TextField(controller: _deptNameCtrl, decoration: const InputDecoration(labelText: 'Department Name', helperText: 'Official full department name')),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _deptCodeCtrl, decoration: const InputDecoration(labelText: 'Department Code'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _academicYearCtrl, decoration: const InputDecoration(labelText: 'Current Academic Year'))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _attendanceThreshCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Attendance Threshold %', helperText: 'Students below this will receive warnings'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _minCgpaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min CGPA Threshold', helperText: 'Minimum academic standard'))),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAllChanges,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                child: const Text('Save Department Configuration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Security & Two-Factor Authentication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Require OTP during login via Mobile Authenticator'),
              value: _2faEnabled,
              activeThumbColor: AppTheme.accentGreen,
              onChanged: (val) {
                setState(() { _2faEnabled = val; _hasUnsavedChanges = true; });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('2FA ${val ? "ENABLED" : "DISABLED"} - Save to apply changes.')));
              },
            ),
            SwitchListTile(
              title: const Text('Auto Session Timeout (30 mins)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Automatically log out after 30 minutes of inactivity'),
              value: _sessionTimeout,
              activeThumbColor: AppTheme.accentBlue,
              onChanged: (val) => setState(() { _sessionTimeout = val; _hasUnsavedChanges = true; }),
            ),
            const Divider(),
            ListTile(
              title: const Text('Change Account Password', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Last changed: 30 days ago'),
              trailing: ElevatedButton(
                onPressed: () => _openChangePasswordModal(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
                child: const Text('Change Password', style: TextStyle(color: Colors.white)),
              ),
            ),
            ListTile(
              title: const Text('Active Login Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('2 active sessions: Chrome on Windows, Mobile App'),
              trailing: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All other sessions terminated!'))),
                child: const Text('Terminate Other Sessions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifPrefsSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notification Alerts & Communication Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            const Text('General Channels', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            SwitchListTile(
              title: const Text('Email Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Receive all portal alerts via email'),
              value: _emailNotifs,
              activeThumbColor: AppTheme.accentBlue,
              onChanged: (val) => setState(() { _emailNotifs = val; _hasUnsavedChanges = true; }),
            ),
            SwitchListTile(
              title: const Text('SMS Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Receive critical alerts via SMS'),
              value: _smsNotifs,
              activeThumbColor: AppTheme.accentBlue,
              onChanged: (val) => setState(() { _smsNotifs = val; _hasUnsavedChanges = true; }),
            ),
            SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Browser and mobile push notifications'),
              value: _pushNotifs,
              activeThumbColor: AppTheme.accentBlue,
              onChanged: (val) => setState(() { _pushNotifs = val; _hasUnsavedChanges = true; }),
            ),
            const Divider(),
            const Text('Department-Specific Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            SwitchListTile(
              title: const Text('Leave Request Email Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Get email when faculty submits a leave request'),
              value: _leaveEmailAlert,
              activeThumbColor: AppTheme.accentGreen,
              onChanged: (val) => setState(() { _leaveEmailAlert = val; _hasUnsavedChanges = true; }),
            ),
            SwitchListTile(
              title: const Text('Low Attendance Warning Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Alert when student attendance falls below threshold'),
              value: _attendanceAlert,
              activeThumbColor: AppTheme.accentGreen,
              onChanged: (val) => setState(() { _attendanceAlert = val; _hasUnsavedChanges = true; }),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveAllChanges,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
              child: const Text('Save Notification Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('HOD Digital Signature & Department Official Seal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 16),
            const Text('Current Digital Signature:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 10),
            Container(
              width: 200,
              height: 80,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4))),
              child: Center(
                child: Text('${ProfileService.get()['name'] ?? 'Dr. K. Ravichandran'}\n[DIGITAL SIGNATURE]', textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: AppTheme.primaryNavy, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature upload dialog opened! Select a PNG/JPG file.'))),
                icon: const Icon(Icons.upload, size: 16, color: Colors.white),
                label: const Text('Upload New Signature', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature cleared.'))),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear Signature'),
              ),
            ]),
            const SizedBox(height: 20),
            const Divider(),
            const Text('Signature Usage Settings:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('• Automatically applied to all generated PDF reports', style: TextStyle(fontSize: 12)),
            const Text('• Used on NAAC and accreditation audit files', style: TextStyle(fontSize: 12)),
            const Text('• Included on leave approval letters and circulars', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLogSection() {
    final activities = [
      {'icon': Icons.check_circle, 'color': AppTheme.accentGreen, 'title': 'Login Successful', 'desc': 'Logged in from IP 192.168.1.42 (Chrome/Windows)', 'time': 'Today 01:50 PM'},
      {'icon': Icons.edit, 'color': AppTheme.accentBlue, 'title': 'Leave Request Approved', 'desc': 'Approved LV-2026-001 for Prof. P. Ramya', 'time': 'Today 11:20 AM'},
      {'icon': Icons.upload_file, 'color': AppTheme.accentPurple, 'title': 'Document Uploaded', 'desc': 'Uploaded IOT2028_Syllabus_Regulation2022.pdf', 'time': 'Today 10:05 AM'},
      {'icon': Icons.notifications, 'color': AppTheme.accentOrange, 'title': 'Notification Published', 'desc': 'Published Internal Assessment deadline circular', 'time': 'Yesterday 03:15 PM'},
    ];

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Recent System & Security Audit Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading full activity log CSV...'))),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Export Log', style: TextStyle(fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            ...activities.map((a) => ListTile(
              dense: true,
              leading: Icon(a['icon'] as IconData? ?? Icons.info, color: a['color'] as Color? ?? AppTheme.accentBlue, size: 20),
              title: Text((a['title'] as String?) ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text((a['desc'] as String?) ?? '-', style: const TextStyle(fontSize: 11)),
              trailing: Text((a['time'] as String?) ?? '-', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            )),
          ],
        ),
      ),
    );
  }

  void _openChangePasswordModal(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Account Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password *')),
            const SizedBox(height: 10),
            TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password *', helperText: 'Minimum 8 characters with numbers and symbols')),
            const SizedBox(height: 10),
            TextField(controller: confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password *')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (currentCtrl.text.trim().isEmpty || newCtrl.text.trim().isEmpty || confirmCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all password fields!')));
                return;
              }
              if (newCtrl.text.trim() != confirmCtrl.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match!')));
                return;
              }
              if (newCtrl.text.trim().length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 8 characters!')));
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully! Please login again.'), backgroundColor: AppTheme.accentGreen));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentOrange),
            child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_activeTab) {
      case 0:
        return _buildDeptConfigSection();
      case 1:
        return _buildSecuritySection();
      case 2:
        return _buildNotifPrefsSection();
      case 3:
        return _buildSignatureSection();
      case 4:
        return _buildActivityLogSection();
      default:
        return _buildDeptConfigSection();
    }
  }

  Widget _buildCompactTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
