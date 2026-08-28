import 'dart:async';
import 'package:flutter/material.dart';
import 'package:erp_unified/modules/admin/app/theme/app_spacing.dart';
import '../services/supabase_service.dart';

class ModulePreloader extends StatefulWidget {
  final String moduleName;
  final String moduleSubtitle;
  final IconData icon;
  final Color accentColor;
  final String badge;
  final Widget child;

  const ModulePreloader({
    super.key,
    required this.moduleName,
    required this.moduleSubtitle,
    required this.icon,
    required this.accentColor,
    required this.badge,
    required this.child,
  });

  @override
  State<ModulePreloader> createState() => _ModulePreloaderState();
}

class _ModulePreloaderState extends State<ModulePreloader>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String _statusText = 'Initializing Portal...';
  int _statusIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Timer _statusTimer;

  final List<String> _statusMessages = [
    'Connecting to Supabase Database...',
    'Authenticating System Access...',
    'Loading Module Registry...',
    'Syncing Master Data Tables...',
    'Configuring User Permissions...',
    'Establishing Secure Gateway...',
    'Preparing Dashboard Analytics...',
    'Portal Ready — Loading Interface...',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController.repeat(reverse: true);

    _startLoadingSequence();
  }

  Future<void> _startLoadingSequence() async {
    _fadeController.forward();
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted || !_isLoading) return;
      setState(() {
        _statusIndex = (_statusIndex + 1) % _statusMessages.length;
        _statusText = _statusMessages[_statusIndex];
      });
    });

    await SupabaseService.instance.initialize();
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      await _fadeController.reverse();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _statusTimer.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading) return widget.child;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00102B), Color(0xFF001B44), Color(0xFF0F172A)],
        ),
      ),
      child: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + (_pulseController.value * 0.08),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.icon,
                        size: 48,
                        color: const Color(0xFF00102B),
                      ),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Text(
                    widget.moduleName,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.moduleSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8DA4CE),
                    ),
                  ),
                  AppSpacing.gapLg,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      widget.badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  AppSpacing.gapXl,
                  SizedBox(
                    width: 160,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.accentColor,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  AppSpacing.gapMd,
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _statusText,
                      key: ValueKey(_statusIndex),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
