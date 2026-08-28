import 'package:flutter/material.dart';
import '../services/admin_supabase_service.dart';
import '../widgets/app_responsive.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String _triggerSearchQuery = '';

  // Local state initialized with defaults and synced with Supabase
  List<Map<String, dynamic>> _triggers = [
    {
      'id': '1',
      'name': 'Daily Absence Alert',
      'channel': 'SMS + In-App',
      'template':
          'Dear Parent, your ward {student_name} is marked ABSENT on {date}.',
      'status': 'ACTIVE',
      'target': 'Parents & Students',
    },
    {
      'id': '2',
      'name': 'Semester Fee Due Reminder',
      'channel': 'Email + SMS',
      'template':
          'Important: Term fee balance due before {due_date}. Please pay via student portal.',
      'status': 'ACTIVE',
      'target': 'Students & Parents',
    },
    {
      'id': '3',
      'name': 'Exam Hall Ticket Published',
      'channel': 'In-App + Email',
      'template':
          'Hall Ticket for {exam_name} is published. Download your signed admit card now.',
      'status': 'ACTIVE',
      'target': 'All Students',
    },
    {
      'id': '4',
      'name': 'Emergency Medical Blood Request',
      'channel': 'SMS + Push',
      'template':
          'Urgent: Blood group {blood_group} required at Campus Clinic. Contact Medical Officer.',
      'status': 'ACTIVE',
      'target': 'All Campus Users',
    },
  ];

  List<Map<String, dynamic>> _deliveryLogs = [
    {
      'id': 'LOG-901',
      'title': 'End Semester Exam Time Table Notice',
      'target': 'B.E. CSE & IT Students',
      'channel': 'Email + In-App',
      'recipients': '1,420',
      'status': 'DELIVERED',
      'timestamp': 'Today, 10:30 AM',
    },
    {
      'id': 'LOG-900',
      'title': 'Monthly Attendance Summary Alert',
      'target': 'Parents of Absentee Students',
      'channel': 'SMS',
      'recipients': '380',
      'status': 'DELIVERED',
      'timestamp': 'Yesterday, 04:15 PM',
    },
    {
      'id': 'LOG-899',
      'title': 'Campus Placement Drive Registration',
      'target': 'Final Year Students',
      'channel': 'Email + SMS',
      'recipients': '850',
      'status': 'DELIVERED',
      'timestamp': '10 Aug 2026, 09:00 AM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dbTriggers = await AdminSupabaseService.fetchNotificationTriggers();
      final dbLogs = await AdminSupabaseService.fetchNotificationLogs();
      if (mounted) {
        setState(() {
          if (dbTriggers.isNotEmpty) {
            _triggers = dbTriggers;
          }
          if (dbLogs.isNotEmpty) {
            _deliveryLogs = dbLogs;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTriggers =>
      _triggerSearchQuery.isEmpty
      ? _triggers
      : _triggers
            .where(
              (t) =>
                  (t['name'] ?? '').toString().toLowerCase().contains(
                    _triggerSearchQuery.toLowerCase(),
                  ) ||
                  (t['template'] ?? '').toString().toLowerCase().contains(
                    _triggerSearchQuery.toLowerCase(),
                  ),
            )
            .toList();

  // ── MODAL 1: SEND BROADCAST ALERT ─────────────────────────────────────────
  void _showSendBroadcastModal() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    var targetGroup = 'All Students & Parents';
    var sendSms = true;
    var sendEmail = true;
    var sendInApp = true;
    var isUrgent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Color(0xFF0052CC), size: 24),
              SizedBox(width: 10),
              Text(
                'Dispatch Broadcast Alert',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: targetGroup,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Target Recipient Group',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items:
                        [
                              'All Students & Parents',
                              'All Faculty & Staff',
                              'Specific Department (CSE / IT / ECE)',
                              'Hostel Residents',
                              'Parents Only',
                            ]
                            .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                    onChanged: (v) => ss(() => targetGroup = v!),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Delivery Channels',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilterChip(
                        label: const Text('SMS Message'),
                        selected: sendSms,
                        selectedColor: const Color(0xFFDCFCE7),
                        checkmarkColor: const Color(0xFF166534),
                        onSelected: (v) => ss(() => sendSms = v),
                      ),
                      FilterChip(
                        label: const Text('Email Notice'),
                        selected: sendEmail,
                        selectedColor: const Color(0xFFDBEAFE),
                        checkmarkColor: const Color(0xFF1E40AF),
                        onSelected: (v) => ss(() => sendEmail = v),
                      ),
                      FilterChip(
                        label: const Text('In-App Push'),
                        selected: sendInApp,
                        selectedColor: const Color(0xFFF3E8FF),
                        checkmarkColor: const Color(0xFF6B21A8),
                        onSelected: (v) => ss(() => sendInApp = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Alert Subject / Headline',
                      hintText: 'e.g. Campus Holiday Declaration Notice',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: messageCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Broadcast Content Message',
                      hintText: 'Enter full text notice to be delivered...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUrgent
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mark as Emergency / Priority Alert',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isUrgent,
                          activeThumbColor: const Color(0xFFDC2626),
                          onChanged: (v) => ss(() => isUrgent = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isUrgent
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF0052CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final msg = messageCtrl.text.trim();
                if (title.isEmpty || msg.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter headline and broadcast message content.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final channels = [
                  if (sendSms) 'SMS',
                  if (sendEmail) 'Email',
                  if (sendInApp) 'In-App',
                ].join(' + ');

                final logEntry = {
                  'id':
                      'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  'title': title,
                  'target': targetGroup,
                  'channel': channels.isEmpty ? 'In-App' : channels,
                  'recipients': isUrgent ? '2,840' : '1,250',
                  'status': 'DELIVERED',
                  'timestamp': 'Just Now',
                };

                await AdminSupabaseService.addNotificationLog(logEntry);

                setState(() {
                  _deliveryLogs.insert(0, logEntry);
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Broadcast alert "$title" dispatched successfully to $targetGroup!',
                      ),
                      backgroundColor: const Color(0xFF16A34A),
                    ),
                  );
                }
              },
              label: const Text(
                'Dispatch Broadcast Alert',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL 2: CREATE EVENT TRIGGER ─────────────────────────────────────────
  void _showAddTriggerModal({Map<String, dynamic>? existingTrigger}) {
    final nameCtrl = TextEditingController(
      text: existingTrigger?['name'] ?? '',
    );
    final templateCtrl = TextEditingController(
      text: existingTrigger?['template'] ?? '',
    );
    String channel = existingTrigger?['channel'] ?? 'SMS + In-App';
    String target = existingTrigger?['target'] ?? 'Students & Parents';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Color(0xFF9333EA)),
              const SizedBox(width: 10),
              Text(
                existingTrigger != null
                    ? 'Edit Notification Trigger'
                    : 'Create Automated Event Trigger',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Trigger Event Name',
                    hintText: 'e.g. Gate Pass Exit Alert',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: channel,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Channel',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            [
                                  'SMS + In-App',
                                  'Email + SMS',
                                  'In-App + Email',
                                  'SMS Only',
                                  'Email Only',
                                ]
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => ss(() => channel = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: target,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Target Audience',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            [
                                  'Parents & Students',
                                  'Students & Faculty',
                                  'All Students',
                                  'Faculty Only',
                                  'All Campus Users',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => ss(() => target = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: templateCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Template Content Preview',
                    hintText:
                        'Dear {student_name}, your {event_name} is confirmed...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052CC),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final tmpl = templateCtrl.text.trim();
                if (name.isEmpty || tmpl.isEmpty) return;

                Navigator.pop(ctx);

                final data = {
                  'name': name,
                  'channel': channel,
                  'target': target,
                  'template': tmpl,
                  'status': 'ACTIVE',
                };

                if (existingTrigger != null && existingTrigger['id'] != null) {
                  await AdminSupabaseService.updateNotificationTrigger(
                    existingTrigger['id'],
                    data,
                  );
                } else {
                  await AdminSupabaseService.addNotificationTrigger(data);
                }

                _loadData();
              },
              child: Text(
                existingTrigger != null ? 'Update Trigger' : 'Create Trigger',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── MODAL 3: CONFIGURE GATEWAYS ───────────────────────────────────────────
  void _showGatewayConfigModal() {
    final smtpHostCtrl = TextEditingController(text: 'smtp.ksrce.ac.in');
    final smtpPortCtrl = TextEditingController(text: '587');
    final senderEmailCtrl = TextEditingController(
      text: 'notifications@cams.ksrce.ac.in',
    );
    final smsApiKeyCtrl = TextEditingController(
      text: 'tw_live_99210940129031209312391029312',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.settings_input_component_rounded,
              color: Color(0xFF0052CC),
            ),
            SizedBox(width: 10),
            Text(
              'Configure SMS & SMTP Gateway Credentials',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: smtpHostCtrl,
                decoration: InputDecoration(
                  labelText: 'SMTP Server Host',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: smtpPortCtrl,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: senderEmailCtrl,
                      decoration: InputDecoration(
                        labelText: 'Sender Email Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: smsApiKeyCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'SMS Gateway API Token / Key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0052CC),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'SMS & SMTP Gateway settings updated successfully.',
                  ),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            child: const Text('Save Credentials'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP HEADER ────────────────────────────────────────────────────
          AppResponsive.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configure automated broadcast triggers, SMTP mail gateways, SMS API credentials, and delivery logs',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showSendBroadcastModal,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Send Broadcast Alert'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052CC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Notification Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure automated broadcast triggers, SMTP mail gateways, SMS API credentials, and delivery logs',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _showSendBroadcastModal,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Broadcast Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 20),

          // ── KPI SUMMARY CARDS ──────────────────────────────────────────────
          ResponsiveGrid(
            mainAxisExtent: 110,
            children: [
              _buildStatCard(
                'SMS Delivery Rate',
                '99.4%',
                Icons.sms_rounded,
                const Color(0xFF16A34A),
              ),
              _buildStatCard(
                'Email Delivery Rate',
                '98.8%',
                Icons.email_rounded,
                const Color(0xFF0052CC),
              ),
              _buildStatCard(
                'Active Triggers',
                '${_triggers.where((t) => t['status'] == 'ACTIVE').length} Event Triggers',
                Icons.notifications_active_rounded,
                const Color(0xFF9333EA),
              ),
              _buildStatCard(
                'SMS Credits Left',
                '45,200 SMS',
                Icons.numbers_rounded,
                const Color(0xFFD97706),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── TAB BAR ─────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFF0052CC),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0052CC),
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Notification Triggers & Templates'),
                Tab(text: 'SMS & Email Gateway Setup'),
                Tab(text: 'Outbound Delivery Logs'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── TAB VIEWS ───────────────────────────────────────────────────────
          SizedBox(
            height: 520,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTriggersTab(),
                _buildGatewaysTab(),
                _buildDeliveryLogsTab(),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // ── TAB 1: NOTIFICATION TRIGGERS & TEMPLATES ─────────────────────────────
  Widget _buildTriggersTab() {
    final triggers = _filteredTriggers;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
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
                    'Automated Event Triggers & In-App Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'System-wide rules that trigger automatic notifications upon ERP actions',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddTriggerModal,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Trigger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _triggerSearchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search triggers or template text...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Trigger Event Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Channel',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Target Audience',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Template Content Preview',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: triggers.map((t) {
                          final isActive = t['status'] == 'ACTIVE';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  t['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t['channel'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF0052CC),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  t['target'] ?? 'Students & Parents',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 280,
                                  child: Text(
                                    t['template'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t['status'] ?? 'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isActive
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: Color(0xFF0052CC),
                                      ),
                                      onPressed: () => _showAddTriggerModal(
                                        existingTrigger: t,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        isActive
                                            ? Icons.pause_circle_outline_rounded
                                            : Icons.play_circle_outline_rounded,
                                        size: 18,
                                        color: isActive
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFF16A34A),
                                      ),
                                      onPressed: () async {
                                        final newStatus = isActive
                                            ? 'PAUSED'
                                            : 'ACTIVE';
                                        if (t['id'] != null) {
                                          await AdminSupabaseService.updateNotificationTrigger(
                                            t['id'],
                                            {'status': newStatus},
                                          );
                                        }
                                        setState(() {
                                          t['status'] = newStatus;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: SMS & EMAIL GATEWAY SETUP ───────────────────────────────────────
  Widget _buildGatewaysTab() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    padding: const EdgeInsets.all(20),
    child: SingleChildScrollView(
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
                    'Gateway Provider Credentials & Protocols',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage active SMS API gateways, SMTP mail servers, and push notification tokens',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showGatewayConfigModal,
                icon: const Icon(Icons.settings_rounded, size: 16),
                label: const Text('Configure Gateway Credentials'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Provider Cards
          Row(
            children: [
              Expanded(
                child: _buildGatewayCard(
                  title: 'Twilio SMS Gateway',
                  host: 'api.textlocal.in / api.twilio.com',
                  status: 'CONNECTED',
                  statusColor: const Color(0xFF16A34A),
                  icon: Icons.sms_rounded,
                  detail: '14,250 SMS Sent Today • 45,200 Credits Left',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGatewayCard(
                  title: 'Institutional SMTP Mail Server',
                  host: 'smtp.ksrce.ac.in : 587 (TLS)',
                  status: 'CONNECTED',
                  statusColor: const Color(0xFF16A34A),
                  icon: Icons.mark_email_read_rounded,
                  detail: '3,890 Emails Sent Today • DKIM & SPF Verified',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildGatewayCard(
                  title: 'Firebase Cloud Messaging (FCM)',
                  host: 'fcm.googleapis.com (V1 API)',
                  status: 'ACTIVE',
                  statusColor: const Color(0xFF0052CC),
                  icon: Icons.notifications_active_rounded,
                  detail: 'Real-time Mobile & Web Push Delivery Active',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGatewayCard(
                  title: 'WhatsApp Business API Gateway',
                  host: 'graph.facebook.com/v18.0',
                  status: 'STANDBY',
                  statusColor: const Color(0xFFD97706),
                  icon: Icons.chat_rounded,
                  detail: 'Ready for Instant Student Circular Dispatch',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildGatewayCard({
    required String title,
    required String host,
    required String status,
    required Color statusColor,
    required IconData icon,
    required String detail,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0052CC), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          host,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
        ),
      ],
    ),
  );

  // ── TAB 3: OUTBOUND DELIVERY LOGS ─────────────────────────────────────────
  Widget _buildDeliveryLogsTab() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outbound Notification Delivery Logs',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Real-time audit trail of all manual broadcasts and automated event dispatches',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 28,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Log ID',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Notice Headline / Subject',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Target Audience',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Channel',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Recipients',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Dispatch Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _deliveryLogs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          log['id'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          log['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(
                        Text(
                          log['target'] ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log['channel'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0052CC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          '${log['recipients']} Users',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          log['timestamp'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log['status'] ?? 'DELIVERED',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF166534),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
