import 'package:flutter/material.dart';

class ModulePreloader extends StatefulWidget {

  const ModulePreloader({
    super.key,
    required this.moduleName,
    required this.moduleSubtitle,
    required this.icon,
    required this.accentColor,
    required this.badge,
    required this.child,
  });
  final String moduleName;
  final String moduleSubtitle;
  final IconData icon;
  final Color accentColor;
  final String badge;
  final Widget child;

  @override
  State<ModulePreloader> createState() => _ModulePreloaderState();
}

class _ModulePreloaderState extends State<ModulePreloader> {
  @override
  Widget build(BuildContext context) => widget.child;
}
