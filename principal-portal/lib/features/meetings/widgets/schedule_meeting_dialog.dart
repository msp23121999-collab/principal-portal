import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/buttons/secondary_button.dart';
import '../../../core/widgets/inputs/app_date_picker.dart';
import '../../../core/widgets/inputs/filter_dropdown.dart';
import '../models/meeting.dart';

/// What the schedule form produced.
class MeetingDraft {
  const MeetingDraft({
    required this.title,
    required this.type,
    required this.date,
    required this.venue,
    required this.durationMinutes,
    required this.agenda,
  });

  final String title;
  final MeetingType type;
  final DateTime date;
  final String venue;
  final int durationMinutes;
  final List<String> agenda;
}

/// Schedule form for a new meeting: title, forum, date, venue, duration,
/// and agenda points entered one per line.
class ScheduleMeetingDialog extends StatefulWidget {
  const ScheduleMeetingDialog({super.key, required this.initialDate});

  final DateTime initialDate;

  static Future<MeetingDraft?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) {
    return showDialog<MeetingDraft>(
      context: context,
      builder: (_) => ScheduleMeetingDialog(initialDate: initialDate),
    );
  }

  @override
  State<ScheduleMeetingDialog> createState() => _ScheduleMeetingDialogState();
}

class _ScheduleMeetingDialogState extends State<ScheduleMeetingDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _venue = TextEditingController();
  final TextEditingController _agenda = TextEditingController();

  late DateTime _date = widget.initialDate;
  MeetingType _type = MeetingType.departmental;
  int _duration = 60;

  static const List<int> _durations = [30, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    // Keeps the save button's enabled state in step with the title field.
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _venue.dispose();
    _agenda.dispose();
    super.dispose();
  }

  bool get _canSave => _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Schedule Meeting',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Subject of the meeting',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilterDropdown<MeetingType>(
                    label: 'Forum',
                    value: _type,
                    items: MeetingType.values,
                    itemLabel: (value) => value.label,
                    width: 250,
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                  AppDatePicker(
                    label: 'Date',
                    value: _date,
                    width: 210,
                    onChanged: (value) => setState(() => _date = value),
                  ),
                  FilterDropdown<int>(
                    label: 'Duration',
                    value: _duration,
                    items: _durations,
                    itemLabel: (value) => '$value min',
                    width: 190,
                    onChanged: (value) {
                      if (value != null) setState(() => _duration = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _venue,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                  hintText: 'Where the meeting will be held',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _agenda,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Agenda',
                  hintText: 'One agenda point per line',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Scheduled for ${DateFormatter.fullDate(_date)}',
                style: Theme.of(context).textTheme.labelSmall,
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
        PrimaryButton(label: 'Schedule', onPressed: _canSave ? _submit : null),
      ],
    );
  }

  void _submit() {
    final agendaPoints = _agenda.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      MeetingDraft(
        title: _title.text.trim(),
        type: _type,
        date: _date,
        venue: _venue.text.trim().isEmpty
            ? "Principal's Chamber"
            : _venue.text.trim(),
        durationMinutes: _duration,
        agenda: agendaPoints.isEmpty
            ? const ['Agenda to be circulated.']
            : agendaPoints,
      ),
    );
  }
}
