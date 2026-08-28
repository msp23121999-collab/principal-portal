import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/buttons/primary_button.dart';

import '../../../core/widgets/layout/tabbed_page.dart';
import '../models/circular.dart';
import '../providers/circulars_providers.dart';
import '../widgets/circular_list_tab.dart';
import '../widgets/create_circular_dialog.dart';

/// Circulars & Announcements — compose, publish, and archive institutional
/// notices, and see how widely each one has been read.
class CircularsScreen extends ConsumerWidget {
  const CircularsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = ref.watch(publishedCircularCountProvider);
    final drafts = ref.watch(draftCircularCountProvider);
    final averageRead = ref.watch(averageReadPercentProvider);

    return TabbedPage(
      title: 'Circulars & Announcements',
      breadcrumbSegments: const ['Communication', 'Circulars'],
      subtitle:
          '$published published, $drafts in draft, '
          '${averageRead.toStringAsFixed(0)}% average readership.',
      actions: [
        PrimaryButton(
          label: 'Create Notice',
          icon: AppIcons.add,
          onPressed: () => _createNotice(context, ref),
        ),
      ],
      tabs: const [
        PageTab(
          label: 'Published',
          content: CircularListTab(status: CircularStatus.published),
        ),
        PageTab(
          label: 'Drafts',
          content: CircularListTab(status: CircularStatus.draft),
        ),
        PageTab(
          label: 'Archived',
          content: CircularListTab(status: CircularStatus.archived),
        ),
      ],
    );
  }

  Future<void> _createNotice(BuildContext context, WidgetRef ref) async {
    // The reference is assigned by the repository when the row is written, so
    // the dialog no longer previews one. Generating it here would guess at a
    // number the database may not agree with.
    final draft = await CreateCircularDialog.show(context);
    if (draft == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(circularActionsProvider)
          .compose(
            title: draft.title,
            body: draft.body,
            category: draft.category,
            audience: draft.audience,
            asDraft: true,
          );

      messenger.showSnackBar(
        SnackBar(content: Text('"${draft.title}" saved to drafts.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not save the circular: $error')),
      );
    }
  }
}
