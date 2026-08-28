import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Standard Faculty Loading Widget using hexagonDots animation in Blue Theme.
/// Robust layout implementation safe inside Columns, Stacks, and Flex views.
class FacultyLoadingWidget extends StatelessWidget {
  final double size;
  final String? message;
  final Color color;
  final bool showMessage;
  final Color? backgroundColor;

  const FacultyLoadingWidget({
    super.key,
    this.size = 60,
    this.message,
    this.color = const Color(0xFF2563EB),
    this.showMessage = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 350),
      color: backgroundColor ?? Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Center(
        child: LoadingAnimationWidget.hexagonDots(
          color: color,
          size: size,
        ),
      ),
    );
  }
}

/// Scaffold wrapper for full-page loading
class FacultyPageLoadingScaffold extends StatelessWidget {
  final String? message;
  const FacultyPageLoadingScaffold({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FacultyLoadingWidget(
        size: 60,
        message: message,
        showMessage: false,
      ),
    );
  }
}
