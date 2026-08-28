import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/approvals_refresh_provider.dart';

/// Header action that refetches the Approvals queues.
///
/// Web and desktop have no pull gesture, so the page needs a control that can
/// be clicked. Built as its own outlined button rather than a [SecondaryButton]
/// so the icon slot can hold a spinner while the fetch is in flight — the
/// Principal acts on this page and needs to know whether what they are looking
/// at is current.
class ApprovalsRefreshButton extends ConsumerWidget {
  const ApprovalsRefreshButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRefreshing = ref.watch(approvalsRefreshProvider);

    return OutlinedButton(
      // Disabled while running. The controller already dedupes, so this is
      // about telling the Principal the click landed rather than about
      // preventing a second request.
      onPressed: isRefreshing
          ? null
          : () => ref.read(approvalsRefreshProvider.notifier).run(),
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: isRefreshing
                ? const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  )
                : const Icon(Icons.refresh, size: 16, color: Color(0xFF0F172A)),
          ),
          const SizedBox(width: 8),
          Text(
            isRefreshing ? 'Refreshing…' : 'Refresh',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}
