// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../services/local_storage_base.dart';

/// Faculty Settings View (Faculty Portal — Index 20)
///
/// Personal Faculty Account Settings ONLY.
///
/// Sections:
///   1. Account: Profile information & Email/Username display (from repo.profile)
///   2. Change Password: Current, New, and Confirm password form
///   3. Notifications: Toggle preferences for email, leave status, assignment, and timetable alerts
///   4. Security: 2FA & Session security settings
///
/// Excluded: No system-wide ERP, Academic Year, Department, Regulation, Timetable, or Theme configuration.
class FacultySettingsView extends StatefulWidget {
  const FacultySettingsView({super.key});

  @override
  State<FacultySettingsView> createState() => _FacultySettingsViewState();
}

class _FacultySettingsViewState extends State<FacultySettingsView> {
  final repo = ErpRepository();

  // Notification Toggles
  bool _emailNotifs = true;
  bool _leaveAlerts = true;
  bool _assignmentNotifs = true;
  bool _timetableAlerts = true;

  // Security Toggles
  bool _twoFactorAuth = false;

  // Change Password Controllers
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final map = LocalStorageBase.readMap('facultySettings');
    if (map.isNotEmpty) {
      setState(() {
        _emailNotifs = map['emailNotifs'] as bool? ?? true;
        _leaveAlerts = map['leaveAlerts'] as bool? ?? true;
        _assignmentNotifs = map['assignmentNotifs'] as bool? ?? true;
        _timetableAlerts = map['timetableAlerts'] as bool? ?? true;
        _twoFactorAuth = map['twoFactorAuth'] as bool? ?? false;
      });
    }
  }

  void _saveSettings() {
    final settingsMap = {
      'emailNotifs': _emailNotifs,
      'leaveAlerts': _leaveAlerts,
      'assignmentNotifs': _assignmentNotifs,
      'timetableAlerts': _timetableAlerts,
      'twoFactorAuth': _twoFactorAuth,
    };
    LocalStorageBase.writeMap('facultySettings', settingsMap);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account settings saved successfully.'),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _accountInfoCard(),
            const SizedBox(height: 20),
            _changePasswordCard(),
            const SizedBox(height: 20),
            _notificationSettingsCard(),
            const SizedBox(height: 20),
            _securityCard(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final yearBadge = _badge('Academic Year ${repo.selectedAcademicYear}');

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              yearBadge,
            ],
          );
        }

        return Row(
          children: [
            Text(
              'Settings',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            yearBadge,
          ],
        );
      },
    );
  }

  Widget _heroBanner() {
    final facultyName = repo.profile['name'] ?? 'Mr. P. Kalaiyarasan';
    final email = repo.profile['email'] ?? 'kalaiyarasan@ksrce.ac.in';

    final saveButton = ElevatedButton.icon(
      onPressed: _saveSettings,
      icon: const Icon(Icons.save_outlined, size: 16),
      label: Text(
        'Save Preferences',
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: const Border(
              left: BorderSide(color: Color(0xFF2563EB), width: 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.manage_accounts_outlined,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PERSONAL ACCOUNT SETTINGS',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Faculty Profile, Security & Preferences',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Logged in as $facultyName ($email)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: saveButton),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_outlined,
                        color: Color(0xFF2563EB),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERSONAL ACCOUNT SETTINGS',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Faculty Profile, Security & Preferences',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Logged in as $facultyName ($email)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    saveButton,
                  ],
                ),
        );
      },
    );
  }

  // ── 1. Account Information Card ──────────────────────────────────────────

  Widget _accountInfoCard() {
    final facultyName = repo.profile['name'] ?? 'Mr. P. Kalaiyarasan';
    final facultyId = repo.profile['facultyId'] ?? 'FAC73124';
    final dept = repo.profile['department'] ?? 'Computer Science & Engineering';
    final designation = repo.profile['designation'] ?? 'Assistant Professor';
    final email = repo.profile['email'] ?? 'kalaiyarasan@ksrce.ac.in';
    final phone = repo.profile['phone'] ?? '+91 98765 43210';

    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Faculty Account Profile',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  facultyName.isNotEmpty ? facultyName[0].toUpperCase() : 'F',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      facultyName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '$designation | Faculty ID: $facultyId',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFE2E8F0)),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              final isTablet =
                  constraints.maxWidth >= 600 && constraints.maxWidth < 900;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoField('Department', dept),
                    const SizedBox(height: 12),
                    _infoField('Email / Username', email),
                    const SizedBox(height: 12),
                    _infoField('Contact Phone', phone),
                  ],
                );
              }

              if (isTablet) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: _infoField('Department', dept)),
                        const SizedBox(width: 16),
                        Expanded(child: _infoField('Email / Username', email)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoField('Contact Phone', phone),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _infoField('Department', dept)),
                  const SizedBox(width: 16),
                  Expanded(child: _infoField('Email / Username', email)),
                  const SizedBox(width: 16),
                  Expanded(child: _infoField('Contact Phone', phone)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 2. Change Password Card ──────────────────────────────────────────────

  Widget _changePasswordCard() {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Change Password',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth > 500 ? 480 : double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _formLabel('Current Password *'),
                    const SizedBox(height: 6),
                    _pwdField(_currentPwdCtrl, 'Enter current password'),
                    const SizedBox(height: 12),
                    _formLabel('New Password *'),
                    const SizedBox(height: 6),
                    _pwdField(
                      _newPwdCtrl,
                      'Enter new password (min 6 characters)',
                    ),
                    const SizedBox(height: 12),
                    _formLabel('Confirm New Password *'),
                    const SizedBox(height: 6),
                    _pwdField(_confirmPwdCtrl, 'Re-enter new password'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: constraints.maxWidth < 450
                          ? double.infinity
                          : null,
                      child: ElevatedButton(
                        onPressed: _updatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Update Password',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _updatePassword() {
    final cur = _currentPwdCtrl.text.trim();
    final newP = _newPwdCtrl.text.trim();
    final conf = _confirmPwdCtrl.text.trim();

    if (cur.isEmpty || newP.isEmpty || conf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all password fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newP.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (newP != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _currentPwdCtrl.clear();
    _newPwdCtrl.clear();
    _confirmPwdCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password changed successfully.'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
  }

  // ── 3. Notification Preferences Card ────────────────────────────────────

  Widget _notificationSettingsCard() {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Notification Preferences',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _switchTile(
            title: 'Email Summary Notifications',
            subtitle:
                'Receive email alerts for daily portal announcements and pending tasks.',
            value: _emailNotifs,
            onChanged: (v) => setState(() => _emailNotifs = v),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _switchTile(
            title: 'Leave & OD Status Alerts',
            subtitle:
                'Get notified when your leave applications are approved or updated.',
            value: _leaveAlerts,
            onChanged: (v) => setState(() => _leaveAlerts = v),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _switchTile(
            title: 'Assignment Submissions Alerts',
            subtitle:
                'Receive notifications when students submit online assignments.',
            value: _assignmentNotifs,
            onChanged: (v) => setState(() => _assignmentNotifs = v),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _switchTile(
            title: 'Timetable & Slot Change Alerts',
            subtitle:
                'Receive alerts if any period slot or hall allocation is modified.',
            value: _timetableAlerts,
            onChanged: (v) => setState(() => _timetableAlerts = v),
          ),
        ],
      ),
    );
  }

  // ── 4. Security Settings Card ─────────────────────────────────────────────

  Widget _securityCard() {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Security & Authentication',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _switchTile(
            title: 'Two-Factor Authentication (2FA)',
            subtitle:
                'Require OTP verification during login for enhanced faculty account security.',
            value: _twoFactorAuth,
            onChanged: (v) => setState(() => _twoFactorAuth = v),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Login Session',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Currently logged in via Web Browser (Active Session).',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Active & Secured',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED UI HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _bc(String t, {bool active = false}) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 12,
      color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
    ),
  );

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF2563EB),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _infoField(String label, String val) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
      ),
      const SizedBox(height: 2),
      Text(
        val,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF334155),
        ),
      ),
    ],
  );

  Widget _formLabel(String t) => Text(
    t,
    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
  );

  Widget _pwdField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      obscureText: true,
      style: GoogleFonts.inter(fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 12,
          color: const Color(0xFF94A3B8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFF2563EB),
          onChanged: onChanged,
        ),
      ],
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
