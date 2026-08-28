import 'package:flutter/material.dart';
import '../services/campus_services_backend.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';

class PlacementManagementScreen extends StatefulWidget {
  const PlacementManagementScreen({super.key});

  @override
  State<PlacementManagementScreen> createState() =>
      _PlacementManagementScreenState();
}

class _PlacementManagementScreenState
    extends State<PlacementManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _drives = [];

  @override
  void initState() {
    super.initState();
    _loadDrives();
  }

  Future<void> _loadDrives() async {
    final data = await CampusServicesBackend.instance.getPlacementDrives();
    if (mounted) {
      setState(() {
        _drives = data;
        _isLoading = false;
      });
    }
  }

  void _showAddDriveModal() {
    final compCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Software Development Engineer');
    final ctcCtrl = TextEditingController(text: '₹ 8.5 LPA');
    final deptCtrl = TextEditingController(text: 'CSE, IT, ECE');
    final dateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T')[0]);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Placement Drive Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: compCtrl,
                decoration: const InputDecoration(labelText: 'Company Name *', hintText: 'e.g. Zoho Corporation', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(labelText: 'Job Role', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctcCtrl,
                      decoration: const InputDecoration(labelText: 'Package CTC', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: deptCtrl,
                      decoration: const InputDecoration(labelText: 'Eligible Departments', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(labelText: 'Drive Date (YYYY-MM-DD)', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white),
            onPressed: () async {
              if (compCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await CampusServicesBackend.instance.addPlacementDrive({
                'title': 'Placement Drive — ${compCtrl.text.trim()}',
                'company_name': compCtrl.text.trim(),
                'role': roleCtrl.text.trim(),
                'package': ctcCtrl.text.trim(),
                'eligible_depts': deptCtrl.text.trim(),
                'drive_date': dateCtrl.text.trim(),
                'status': 'Scheduled',
                'category': 'Placement',
                'target_audience': 'Final Year Students',
                'published_at': DateTime.now().toIso8601String(),
              });
              _loadDrives();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Placement drive announcement posted successfully!'), backgroundColor: AppColors.success),
                );
              }
            },
            child: const Text('Post Announcement'),
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
                      'Training & Placement Cell',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Campus recruitment drives, student offer tracking & corporate outreach',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'New Drive Announcement',
                  icon: Icons.work_rounded,
                  onPressed: () => _showAddDriveModal(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Students Placed',
                    '842',
                    Icons.verified_user_rounded,
                    const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Highest Package Offered',
                    '₹ 24.5 LPA',
                    Icons.payments_rounded,
                    const Color(0xFF0052CC),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Visiting Companies 2026',
                    '86 Companies',
                    Icons.business_center_rounded,
                    const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Recruitment Drives',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Table(
                      border: TableBorder.symmetric(
                        inside: const BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                          ),
                          children: [
                            _buildTableHeader('COMPANY NAME'),
                            _buildTableHeader('ROLE'),
                            _buildTableHeader('PACKAGE CTC'),
                            _buildTableHeader('ELIGIBILITY'),
                            _buildTableHeader('DRIVE DATE'),
                            _buildTableHeader('STATUS'),
                          ],
                        ),
                        ..._drives.map(
                          (d) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  d['company_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(d['role'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  d['package'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(d['eligible_depts'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(d['drive_date'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: AppStatusBadge(
                                  status: d['status'] ?? 'Scheduled',
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
