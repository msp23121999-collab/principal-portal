import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// Standard Student Loading Widget using hexagonDots animation in Blue Theme
class StudentLoadingWidget extends StatelessWidget {
  final double size;
  final String? message;
  final Color color;
  final bool showMessage;

  const StudentLoadingWidget({
    super.key,
    this.size = 60,
    this.message,
    this.color = const Color(0xFF2563EB),
    this.showMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.hexagonDots(
            color: color,
            size: size,
          ),
          if (showMessage && message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Scaffold wrapper for full-page student loading
class StudentPageLoadingScaffold extends StatelessWidget {
  final String? message;
  const StudentPageLoadingScaffold({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StudentLoadingWidget(size: 60, message: message, showMessage: false),
    );
  }
}
