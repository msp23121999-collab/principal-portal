import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/filters/portal_filter_providers.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../../circulars/providers/circulars_providers.dart';
import '../data/notice_delivery.dart';
import '../data/notice_publisher.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';

class CreateNoticeDialog extends ConsumerStatefulWidget {
  const CreateNoticeDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const CreateNoticeDialog(),
    );
  }

  @override
  ConsumerState<CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends ConsumerState<CreateNoticeDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();

  NotificationCategory _category = NotificationCategory.announcement;
  NoticeAudience _audience = NoticeAudience.everyone;
  NoticePriority _priority = NoticePriority.normal;

  String? _department;
  String? _batch;
  DateTime? _expiresAt;

  /// The audiences the portal can actually deliver to.
  ///
  /// Read from [NoticeAudienceDelivery] rather than from
  /// `NoticeAudience.values`, so the dialog cannot offer a group the recipient
  /// feeds have no column to narrow by. Programme and Year were offered here
  /// and reached nobody — see the note on [NoticeAudienceDelivery].
  static final List<NoticeAudience> _audiences =
      NoticeAudienceDelivery.selectable;

  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty && !_isPublishing;

  /// Whether a department choice changes who receives this notice.
  ///
  /// Only the Faculty Portal feed carries a department, so the control appears
  /// exactly where it has an effect rather than on every narrowed audience.
  bool get _narrowsByDepartment =>
      _audience == NoticeAudience.department ||
      _audience == NoticeAudience.batch;

  Future<void> _submit(bool asDraft) async {
    setState(() => _isPublishing = true);

    final draft = NoticeDraft(
      title: _title.text.trim(),
      body: _body.text.trim().isEmpty
          ? 'No notice text entered.'
          : _body.text.trim(),
      category: _category,
      audience: _audience,
      priority: _priority,
      // Department narrows the Faculty Portal feed, batch narrows both feeds.
      // Programme and year of study are not collected: no recipient feed has a
      // column for either, so a value here could only ever be recorded and
      // never acted on.
      department: _narrowsByDepartment ? _department : null,
      batch: _audience == NoticeAudience.batch ? _batch : null,
      expiresAt: _expiresAt,
    );

    try {
      final outcome = await ref
          .read(noticePublisherProvider)
          .publish(draft, asDraft: asDraft);

      // Publishing writes to principal.circulars, faculty.notifications and
      // student.student_notifications. Nothing invalidated the providers that
      // read them, so the row reached the database and the screens kept showing
      // the previous list — the Principal saw "Notice published successfully"
      // followed by a noticeboard that did not contain it, until they navigated
      // away and back. Every other mutation in the portal invalidates; this one
      // was missed.
      ref.invalidate(circularsSourcedProvider);
      ref.invalidate(notificationsSourcedProvider);

      if (mounted) {
        Navigator.of(context).pop();
        // The message comes from the outcome, not from "we got here without
        // throwing". Publishing reaches three schemas that cannot share a
        // transaction, so a notice can land on the noticeboard and still miss
        // a recipient feed — that used to be reported as
        // "Notice published successfully".
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(outcome.message),
            backgroundColor: outcome.isPartial
                ? Theme.of(context).colorScheme.error
                : null,
            duration: outcome.isPartial
                ? const Duration(seconds: 8)
                : const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to publish notice: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The department and batch lists come from the shared filter providers, so
    // the values offered here are the ones the database actually holds rather
    // than a second hand-kept list. Years of study are no longer read: no
    // recipient feed can narrow by year, so the control was removed.
    final departments = ref.watch(filterDepartmentsProvider);
    final batches = ref.watch(filterBatchesProvider);

    return AlertDialog(
      title: Text(
        'Create Notice',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Official institutional notice.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Subject of the notice',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  FilterDropdown<NotificationCategory>(
                    label: 'Type',
                    value: _category,
                    items: NotificationCategory.values,
                    itemLabel: (v) => v.label,
                    width: 200,
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                  ),
                  FilterDropdown<NoticePriority>(
                    label: 'Priority',
                    value: _priority,
                    items: NoticePriority.values,
                    itemLabel: (v) => v.label,
                    width: 150,
                    onChanged: (v) {
                      if (v != null) setState(() => _priority = v);
                    },
                  ),
                  FilterDropdown<NoticeAudience>(
                    label: 'Audience',
                    value: _audience,
                    items: _audiences,
                    itemLabel: (v) => v.label,
                    width: 200,
                    onChanged: (v) {
                      if (v != null) setState(() => _audience = v);
                    },
                  ),
                ],
              ),

              // Who this actually reaches, stated before it is sent.
              //
              // The Principal picks an audience; what the recipient portals can
              // narrow by is a different question, and the two do not always
              // agree. A department notice reaches that department's staff and
              // no students, because the Student Portal feed has no department
              // column. Saying so here is the difference between a limitation
              // and a surprise.
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppIcons.info, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Will be sent to: ${_audience.deliverySummary}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),

              if (_narrowsByDepartment ||
                  _audience == NoticeAudience.batch) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    if (_narrowsByDepartment)
                      FilterDropdown<String>(
                        label: 'Department',
                        value:
                            _department ??
                            (departments.isNotEmpty
                                ? departments.first.code
                                : ''),
                        items: departments.map((d) => d.code).toList(),
                        itemLabel: (v) => v,
                        width: 150,
                        onChanged: (v) => setState(() => _department = v),
                      ),
                    if (_audience == NoticeAudience.batch)
                      FilterDropdown<String>(
                        label: 'Batch',
                        value:
                            _batch ?? (batches.isNotEmpty ? batches.first : ''),
                        items: batches,
                        itemLabel: (v) => v,
                        width: 150,
                        onChanged: (v) => setState(() => _batch = v),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiresAt == null
                          ? 'No Expiry Date (Notice stays forever)'
                          : 'Expires on: ${_expiresAt!.toLocal().toString().split(' ')[0]}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  SecondaryButton(
                    label: _expiresAt == null ? 'Set Expiry' : 'Clear Expiry',
                    onPressed: () async {
                      if (_expiresAt != null) {
                        setState(() => _expiresAt = null);
                      } else {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(
                            const Duration(days: 7),
                          ),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) setState(() => _expiresAt = date);
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _body,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notice Content',
                  hintText: 'Full text as it will appear to recipients',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.sm),
        SecondaryButton(
          label: 'Save Draft',
          onPressed: _canSave ? () => _submit(true) : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        PrimaryButton(
          label: _isPublishing ? 'Publishing...' : 'Publish',
          onPressed: _canSave ? () => _submit(false) : null,
        ),
      ],
    );
  }
}
