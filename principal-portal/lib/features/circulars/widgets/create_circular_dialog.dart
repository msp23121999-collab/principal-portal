import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../models/circular.dart';

/// What the compose form produced.
class CircularDraft {
  const CircularDraft({
    required this.title,
    required this.body,
    required this.category,
    required this.audience,
  });

  final String title;
  final String body;
  final CircularCategory category;
  final CircularAudience audience;
}

/// Compose form for a new notice. Saves as a draft — publishing stays a
/// separate, deliberate action on the card itself.
class CreateCircularDialog extends StatefulWidget {
  const CreateCircularDialog({super.key});

  static Future<CircularDraft?> show(BuildContext context) {
    return showDialog<CircularDraft>(
      context: context,
      builder: (_) => const CreateCircularDialog(),
    );
  }

  @override
  State<CreateCircularDialog> createState() => _CreateCircularDialogState();
}

class _CreateCircularDialogState extends State<CreateCircularDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  CircularCategory _category = CircularCategory.administrative;
  CircularAudience _audience = CircularAudience.everyone;

  @override
  void initState() {
    super.initState();
    // Keeps the save button's enabled state in step with the title field.
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Create Notice',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The reference is assigned when the row is written, so it is
              // not previewed here — showing a number the database might not
              // agree with would be worse than showing none.
              Text(
                'A reference will be assigned when this is saved.',
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
                  FilterDropdown<CircularCategory>(
                    label: 'Category',
                    value: _category,
                    items: CircularCategory.values,
                    itemLabel: (value) => value.label,
                    width: 230,
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  ),
                  FilterDropdown<CircularAudience>(
                    label: 'Audience',
                    value: _audience,
                    items: CircularAudience.values,
                    itemLabel: (value) => value.label,
                    width: 240,
                    onChanged: (value) {
                      if (value != null) setState(() => _audience = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _body,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Notice text',
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
        PrimaryButton(
          label: 'Save as Draft',
          onPressed: _canSave
              ? () => Navigator.of(context).pop(
                  CircularDraft(
                    title: _title.text.trim(),
                    body: _body.text.trim().isEmpty
                        ? 'No notice text entered yet.'
                        : _body.text.trim(),
                    category: _category,
                    audience: _audience,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
