import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class MeetingsBosScreen extends StatelessWidget {
  const MeetingsBosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtain the app-level DeanAppState from the InheritedWidget.
    final appState = DeanAppStateProvider.of(context);

    // Wrap in ListenableBuilder so this widget rebuilds whenever
    // appState.notifyListeners() fires — regardless of whether the
    // InheritedWidget ancestor itself was recreated.
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final meetings = appState.meetingsData;
        print('[DEAN UI DEBUG] MeetingsBosScreen build — '
            'hasLoaded=${appState.hasLoaded} '
            'isLoading=${appState.isLoading} '
            'meetings count=${meetings.length}');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BentoCard(
                title: 'Board of Studies (BoS) & Academic Council Meetings Archive',
                actionText: 'Schedule Meeting',
                onAction: () => _showAddMeetingDialog(context, appState),
                child: _buildTableBody(context, appState, meetings),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableBody(
    BuildContext context,
    DeanAppState appState,
    List<Map<String, dynamic>> meetings,
  ) {
    // Loading state
    if (appState.isLoading && !appState.hasLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading meetings from Supabase...', style: TextStyle(color: DeanTheme.textMuted)),
            ],
          ),
        ),
      );
    }

    // Error state (only shown when there are zero rows AND an error exists)
    if (appState.lastError != null && meetings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Text(
            'Unable to load meetings from Supabase: ${appState.lastError}',
            style: const TextStyle(fontSize: 13, color: DeanTheme.dangerRose),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Empty state (Supabase returned 0 rows — no error)
    if (meetings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Center(
          child: Text(
            'No meeting records available in Supabase database.',
            style: TextStyle(fontSize: 14, color: DeanTheme.textMuted),
          ),
        ),
      );
    }

    print('[DEAN UI DEBUG] MeetingsBosScreen rendering ${meetings.length} row(s)');

    // Data state — render ALL rows, no filter applied
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Ref No & Title', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Board / Council', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Date & Venue', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('External Experts / Attendees', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Agenda / Approved Schemes', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status & Action', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: meetings.map((m) => _buildMeetingRow(context, m)).toList(),
      ),
    );
  }

  void _downloadMomFile(BuildContext context, Map<String, dynamic> meeting) {
    final title = _str(meeting, ['title', 'display_id', 'meeting_id'], 'Meeting');
    final board = _str(meeting, ['category', 'meeting_type', 'board', 'department'], 'Institution');
    final date  = _str(meeting, ['scheduled_at', 'date'], '');
    final venue = _str(meeting, ['venue'], 'Conference Hall');
    final experts = _str(meeting, ['attendees', 'external_experts'], 'Internal Faculty Panel');
    final approved = _str(meeting, ['agenda', 'approved_scheme'], 'Academic Review');
    final fileName = meeting['minutes_file']?.toString() ??
        '${meeting['meeting_id'] ?? meeting['display_id'] ?? 'MoM'}.pdf';

    final pdfText = [
      'Minutes of Meeting',
      'Title: $title',
      'Board/Council: $board',
      'Date: $date',
      'Venue: $venue',
      'Experts Attended: $experts',
      'Approved Schemes: $approved',
      '',
      'This is an official meeting minutes document generated for the Dean portal.',
    ].join('\n');

    final bytes = utf8.encode(pdfText);
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading $fileName...'),
        backgroundColor: DeanTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddMeetingDialog(BuildContext context, DeanAppState appState) {
    final titleController = TextEditingController();
    final venueController = TextEditingController();
    final deptController = TextEditingController(text: 'Computer Science and Engineering');
    final attendeesController = TextEditingController();
    final agendaController = TextEditingController();
    String category = 'BOS';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text('Schedule Board / Academic Meeting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Meeting Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Meeting Category', border: OutlineInputBorder()),
                  items: ['BOS', 'ACADEMIC_COUNCIL', 'EXECUTIVE', 'GOVERNING_BODY']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) category = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptController,
                  decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: attendeesController,
                  decoration: const InputDecoration(labelText: 'External Experts / Attendees', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: agendaController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Agenda Summary', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meeting title is required.')),
                  );
                  return;
                }

                final payload = <String, dynamic>{
                  'display_id': 'MTG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  'title': title,
                  'category': category,
                  'meeting_type': category,
                  'scheduled_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                  'venue': venueController.text.trim().isNotEmpty
                      ? venueController.text.trim()
                      : 'Conference Hall A',
                  'department': deptController.text.trim(),
                  'attendees': attendeesController.text.trim(),
                  'agenda': agendaController.text.trim(),
                  'status': 'SCHEDULED',
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                };

                print('[DEAN TRACE] INSERT dean.dean_meetings payload: $payload');
                final result = await DeanSupabaseService.instance.createMeeting(payload);
                print('[DEAN TRACE] INSERT dean.dean_meetings result: $result');

                if (result != null) {
                  // Refetch from Supabase → updates meetingsData → notifies
                  // ListenableBuilder → UI rebuilds with the new row.
                  await appState.fetchAllData();
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Meeting scheduled and saved to Supabase!'),
                        backgroundColor: DeanTheme.successGreen,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to save meeting to Supabase. Check console for details.'),
                        backgroundColor: DeanTheme.dangerRose,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DeanTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save to Supabase'),
            ),
          ],
        );
      },
    );
  }

  DataRow _buildMeetingRow(BuildContext context, Map<String, dynamic> meeting) {
    // Null-safe helpers — display "—" for any null/empty field.
    final refNo  = _str(meeting, ['display_id', 'id'], '—');
    final title  = _str(meeting, ['title'], '—');
    final board  = _str(meeting, ['category', 'meeting_type', 'board', 'department'], '—');
    final date   = _str(meeting, ['scheduled_at', 'date'], '—').split('T').first;
    final venue  = _str(meeting, ['venue'], '—');
    final experts = _str(meeting, ['attendees', 'external_experts'], '—');
    final agenda = _str(meeting, ['agenda', 'approved_scheme'], '—');
    final status = _str(meeting, ['status'], 'SCHEDULED');

    final statusColor = (status == 'COMPLETED' || status == 'Minutes Published')
        ? DeanTheme.successGreen
        : DeanTheme.primaryBlue;

    return DataRow(
      cells: [
        DataCell(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(refNo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: statusColor)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(fontSize: 11)),
          ],
        )),
        DataCell(Text(board, style: const TextStyle(fontSize: 11))),
        DataCell(Text('$date\n$venue', style: const TextStyle(fontSize: 11))),
        DataCell(Text(experts, style: const TextStyle(fontSize: 11))),
        DataCell(Text(agenda, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        DataCell(
          OutlinedButton.icon(
            onPressed: () => _downloadMomFile(context, meeting),
            icon: const Icon(Icons.download, size: 12),
            label: Text('Download MoM', style: TextStyle(fontSize: 10, color: DeanTheme.primaryBlue)),
          ),
        ),
      ],
    );
  }

  /// Returns the first non-null, non-empty string value from [keys] in [map].
  /// Falls back to [fallback] if none is found.
  String _str(Map<String, dynamic> map, List<String> keys, String fallback) {
    for (final key in keys) {
      final val = map[key];
      if (val != null && val.toString().isNotEmpty) return val.toString();
    }
    return fallback;
  }
}
