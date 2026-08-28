import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/inputs/filter_chip_group.dart';
import '../models/circular.dart';
import '../providers/circulars_providers.dart';
import 'circular_card.dart';

/// The notices in one lifecycle state, with a category filter above them.
/// Which actions each card offers depends on the state it is in.
class CircularListTab extends ConsumerWidget {
  const CircularListTab({super.key, required this.status});

  final CircularStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final circulars = ref.watch(circularsByStatusProvider(status));
    final category = ref.watch(circularCategoryFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilterChipGroup<CircularCategory>(
          value: category,
          items: CircularCategory.values,
          itemLabel: (value) => value.label,
          onChanged: (value) =>
              ref.read(circularCategoryFilterProvider.notifier).state = value,
        ),
        const SizedBox(height: 20),
        if (circulars.isEmpty)
          EmptyState(
            message: category == null
                ? 'There are no ${status.label.toLowerCase()} notices.'
                : 'No ${status.label.toLowerCase()} notices in this category.',
          )
        else
          for (final circular in circulars)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CircularCard(
                circular: circular,
                // Notices read from the HOD and Student portals are shown but
                // not actionable — they belong to those portals.
                onTogglePin:
                    status == CircularStatus.published &&
                        canEditCircular(circular)
                    ? () => _act(
                        context,
                        ref,
                        (a) => a.setPinned(circular.id, !circular.isPinned),
                        circular.isPinned
                            ? '${circular.reference} unpinned.'
                            : '${circular.reference} pinned.',
                      )
                    : null,
                onPublish:
                    status == CircularStatus.draft && canEditCircular(circular)
                    ? () => _act(
                        context,
                        ref,
                        (a) => a.publish(circular.id),
                        '${circular.reference} published to '
                        '${circular.audience.label.toLowerCase()}.',
                      )
                    : null,
                onArchive:
                    status != CircularStatus.archived &&
                        canEditCircular(circular)
                    ? () => _act(
                        context,
                        ref,
                        (a) => a.archive(circular.id),
                        '${circular.reference} archived.',
                      )
                    : null,
              ),
            ),
      ],
    );
  }

  /// Runs a circular action and reports the outcome.
  ///
  /// These write to the database now, so a failure has to be visible — a
  /// silent one would look exactly like a success.
  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(CircularActions) action,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(circularActionsProvider));
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update the circular: $error')),
      );
    }
  }
}
