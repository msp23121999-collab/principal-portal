import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'main_layout.dart';

class CommonHomeScreen extends StatelessWidget {
  const CommonHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'KSRCE ERP & Student Portal',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose your access mode and continue instantly or sign in with credentials.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      _RoleCard(
                        title: 'Student',
                        subtitle:
                            'Open the student portal with a quick demo login or your own credentials.',
                        icon: Icons.school_outlined,
                        accentColor: const Color(0xFF38BDF8),
                        onDefaultLogin: () =>
                            _openPortal(context, 'student', isDefault: true),
                        onCredentialLogin: () =>
                            _showLoginDialog(context, 'student'),
                      ),
                      _RoleCard(
                        title: 'Faculty',
                        subtitle:
                            'Access the ERP dashboard and academic tools with a quick login or your credentials.',
                        icon: Icons.person_rounded,
                        accentColor: const Color(0xFF34D399),
                        onDefaultLogin: () =>
                            _openPortal(context, 'faculty', isDefault: true),
                        onCredentialLogin: () =>
                            _showLoginDialog(context, 'faculty'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPortal(
    BuildContext context,
    String role, {
    required bool isDefault,
  }) async {
    final appState = AppStateProvider.of(context);
    appState.setActiveRole(role);
    await appState.fetchAllData();

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainLayout(role: role)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDefault
                ? 'Signed in as $role (Connected to Supabase DB).'
                : 'Signed in as $role.',
          ),
        ),
      );
    }
  }

  Future<void> _showLoginDialog(BuildContext context, String role) async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final expectedUsername = role == 'faculty' ? 'faculty' : 'student';
    final expectedPassword = role == 'faculty'
        ? const String.fromEnvironment('FACULTY_DEMO_PASSWORD')
        : const String.fromEnvironment('STUDENT_DEMO_PASSWORD');

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text('Sign in as ${role.toUpperCase()}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter username'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter password'
                      : null,
                ),
                const SizedBox(height: 12),
                if (expectedPassword.isNotEmpty)
                  Text(
                    'Demo credentials enabled for this build.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final enteredUsername = usernameController.text
                      .trim()
                      .toLowerCase();
                  final enteredPassword = passwordController.text.trim();
                  if (enteredUsername == expectedUsername &&
                      enteredPassword == expectedPassword) {
                    Navigator.of(dialogContext).pop();
                    _openPortal(context, role, isDefault: false);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid username or password.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onDefaultLogin,
    required this.onCredentialLogin,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onDefaultLogin;
  final VoidCallback onCredentialLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDefaultLogin,
                  icon: const Icon(Icons.login_outlined),
                  label: const Text('Default Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCredentialLogin,
              icon: const Icon(Icons.lock_open_outlined),
              label: const Text('Login with Credentials'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
