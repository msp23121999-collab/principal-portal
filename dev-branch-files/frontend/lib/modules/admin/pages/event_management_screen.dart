import 'package:flutter/material.dart';
import '../services/campus_services_backend.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final data = await CampusServicesBackend.instance.getEvents();
    if (mounted) {
      setState(() {
        _events = data;
        _isLoading = false;
      });
    }
  }

  void _showCreateEventModal() {
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Academic Symposium');
    final venueCtrl = TextEditingController(text: 'KSRCE Main Auditorium');
    final orgCtrl = TextEditingController(text: 'CSE & IT Departments');
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 7)).toIso8601String().split('T')[0]);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New Campus Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Event Title *', hintText: 'e.g. National Conference on AI 2026', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: catCtrl,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: venueCtrl,
                decoration: const InputDecoration(labelText: 'Venue', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: orgCtrl,
                decoration: const InputDecoration(labelText: 'Organizer Department / Club', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await CampusServicesBackend.instance.addEvent({
                'title': titleCtrl.text.trim(),
                'name': titleCtrl.text.trim(),
                'category': catCtrl.text.trim(),
                'date': dateCtrl.text.trim(),
                'meeting_date': dateCtrl.text.trim(),
                'event_date': dateCtrl.text.trim(),
                'venue': venueCtrl.text.trim(),
                'location': venueCtrl.text.trim(),
                'organizer': orgCtrl.text.trim(),
                'status': 'Approved',
                'description': 'Campus event created via admin portal',
              });
              _loadEvents();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Campus event created successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Create Event'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Event & Seminar Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Conferences, technical fests, venue bookings & guest lecture schedules',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'Create New Event',
                  icon: Icons.event_rounded,
                  onPressed: () => _showCreateEventModal(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Scheduled Events & Symposia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadEvents,
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Refresh Events',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                  else if (_events.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No events created yet. Click "Create New Event" to add one.', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    Table(
                      border: TableBorder.symmetric(
                        inside: const BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _buildHeader('EVENT TITLE'),
                            _buildHeader('CATEGORY'),
                            _buildHeader('DATE'),
                            _buildHeader('VENUE'),
                            _buildHeader('ORGANIZER'),
                            _buildHeader('STATUS'),
                          ],
                        ),
                        ..._events.map(
                          (e) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  e['title'] ?? e['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(e['category'] ?? 'Symposium'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(e['date'] ?? e['meeting_date'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(e['venue'] ?? e['location'] ?? 'Auditorium'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(e['organizer'] ?? 'Admin'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: AppStatusBadge(
                                  status: e['status'] ?? 'Approved',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
