import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import 'breadcrumb.dart';

/// Standard page header: title + breadcrumb trail on the left, trailing
/// action buttons on the right. Every feature screen starts with one of
/// these directly under the TopBar.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.breadcrumbSegments,
    this.actions = const [],
    this.subtitle,
  });

  final String title;
  final List<String>? breadcrumbSegments;
  final List<Widget> actions;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (breadcrumbSegments != null) ...[
                Breadcrumb(segments: breadcrumbSegments!),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (actions.isNotEmpty) Wrap(spacing: AppSpacing.sm, children: actions),
      ],
    );
  }
}
