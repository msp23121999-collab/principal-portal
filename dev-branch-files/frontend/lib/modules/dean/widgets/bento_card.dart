import 'package:flutter/material.dart';
import '../theme.dart';

class BentoCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? headerWidget;
  final Widget child;
  final bool fillHeight;

  const BentoCard({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.headerWidget,
    required this.child,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DeanTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeanTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DeanTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (headerWidget != null)
                headerWidget!
              else if (actionText != null && actionText!.isNotEmpty)
                InkWell(
                  onTap: onAction,
                  child: Text(
                    actionText!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DeanTheme.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (fillHeight) Expanded(child: child) else child,
        ],
      ),
    );
  }
}
