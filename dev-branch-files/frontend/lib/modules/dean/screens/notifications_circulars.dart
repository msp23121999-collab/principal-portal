import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';
import '../services/supabase_service.dart';

class NotificationsCircularsScreen extends StatefulWidget {
  const NotificationsCircularsScreen({super.key});

  @override
  State<NotificationsCircularsScreen> createState() => _NotificationsCircularsScreenState();
}

class _NotificationsCircularsScreenState extends State<NotificationsCircularsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _selectedPriority = 'High Priority';
  String _selectedRecipient = 'All HODs & Faculty';
  String? _validationError;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _broadcastCircular() {
    setState(() {
      _validationError = null;
    });

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      setState(() {
        _validationError = 'Please fill in both the circular title and body content.';
      });
      return;
    }

    final alphaRegex = RegExp(r'[a-zA-Z]');
    if (!alphaRegex.hasMatch(title) || !alphaRegex.hasMatch(body)) {
      setState(() {
        _validationError = 'Circular title and body content must contain valid descriptive text (cannot consist solely of numbers or special characters).';
      });
      return;
    }

    String roleToSend = 'all';
    final recipientLower = _selectedRecipient.toLowerCase();
    if (recipientLower.contains('hods only') || recipientLower.contains('all hod')) {
      roleToSend = 'HOD';
    } else if (recipientLower.contains('faculty') || recipientLower.contains('hods & faculty')) {
      roleToSend = 'faculty,hod';
    } else {
      roleToSend = 'all';
    }

    final appState = DeanAppStateProvider.of(context);

    DeanSupabaseService.instance.insertNotification(
      title: title,
      description: body,
      role: roleToSend,
      priority: _selectedPriority.toUpperCase().contains('URGENT') ? 'HIGH' : 'MEDIUM',
      source: 'Dean Office',
      type: 'CIRCULAR',
    ).then((res) {
      appState.fetchAllData();
    });

    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _selectedPriority = 'High Priority';
      _selectedRecipient = 'All HODs & Faculty';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Circular broadcasted successfully to $_selectedRecipient (role: $roleToSend)!'),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notice Composer Form
          BentoCard(
            title: 'Compose Official Dean Office Circular',
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Circular Title',
                            hintText: 'e.g. Schedule for Board of Studies Meetings AY 2024-25',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          decoration: const InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder()),
                          items: ['Normal Priority', 'High Priority', 'Urgent Broadcast']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPriority = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedRecipient,
                          decoration: const InputDecoration(labelText: 'Target Recipients', border: OutlineInputBorder()),
                          items: ['All HODs & Faculty', 'All Faculty Members', 'All HODs Only', 'College Wide']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRecipient = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Circular Body Content',
                      hintText: 'Enter details of the circular...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_validationError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _broadcastCircular,
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Broadcast Circular Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DeanTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Broadcasted Circulars History Table
          BentoCard(
            title: 'Broadcasted Circulars History & Read Receipts',
            child: Builder(builder: (context) {
              final appState = DeanAppStateProvider.of(context);
              final circularsHistory = appState.deanNotificationsData;

              if (circularsHistory.isEmpty) {
                return Container(
                  height: 140,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mark_email_unread_outlined, size: 32, color: DeanTheme.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'No circulars broadcasted yet in Supabase (dean.dean_notifications). Compose a new circular above.',
                        style: TextStyle(fontSize: 12, color: DeanTheme.textMuted),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 34,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 36,
                  columns: const [
                    DataColumn(label: Text('Ref No & Title', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Date Broadcasted', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Recipients', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Read Receipt Rate', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: circularsHistory.map((item) {
                    final displayId = (item['display_id'] ?? item['id'] ?? 'DN').toString();
                    final title = (item['title'] ?? 'Circular').toString();
                    final priority = (item['priority'] ?? 'MEDIUM').toString();
                    final date = (item['created_at'] != null) ? item['created_at'].toString().split('T').first : '—';
                    final role = (item['role'] ?? 'all').toString();
                    final readCount = item['read_count'] ?? 0;
                    final totalCount = item['total_count'] ?? 1;
                    final rateStr = '${((readCount / (totalCount > 0 ? totalCount : 1)) * 100).toStringAsFixed(1)}%';

                    Color priorityColor = DeanTheme.primaryBlue;
                    if (priority.toUpperCase() == 'HIGH' || priority.toUpperCase() == 'URGENT') {
                      priorityColor = DeanTheme.dangerRose;
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text('$displayId ($title)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                        DataCell(Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(priority, style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        )),
                        DataCell(Text(date, style: const TextStyle(fontSize: 11))),
                        DataCell(Text(role, style: const TextStyle(fontSize: 11))),
                        DataCell(Text(rateStr, style: const TextStyle(color: DeanTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 11))),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
