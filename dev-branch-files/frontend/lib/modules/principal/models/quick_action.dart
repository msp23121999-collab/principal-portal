import 'package:flutter/material.dart';

/// A single tappable quick-action tile on the Dashboard, navigating to
/// another module via its route path.
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}
