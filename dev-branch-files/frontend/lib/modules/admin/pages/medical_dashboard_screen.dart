import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';
import '../widgets/app_text_field.dart';
import '../erp_repository.dart';
class MedicalDashboardScreen extends ConsumerStatefulWidget {
  const MedicalDashboardScreen({super.key});

  @override
  ConsumerState<MedicalDashboardScreen> createState() => _MedicalDashboardScreenState();
}

class _MedicalDashboardScreenState extends ConsumerState<MedicalDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form Fields
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showAddAlertSheet() {
    _titleController.clear();
    _descController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusLg)),
      ),
      builder: (context) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Post Emergency Blood Request', style: AppTypography.h2),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  AppSpacing.gapMd,
                  AppTextField(
                    label: 'Emergency Alert Title',
                    hintText: 'Urgent B+ Blood Required',
                    controller: _titleController,
                    validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
                  ),
                  AppSpacing.gapMd,
                  AppTextField(
                    label: 'Description / Requirement Details',
                    hintText: 'B+ blood needed urgently at Campus Partner Clinic node.',
                    controller: _descController,
                    validator: (val) => val == null || val.isEmpty ? 'Description is required' : null,
                  ),
                  AppSpacing.gapLg,
                  AppButton(
                    label: 'Broadcast Emergency Alert',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newAlert = MedicalAlertModel(
                          id: 'MED${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                          title: _titleController.text,
                          description: _descController.text,
                          date: '2026-07-19',
                          status: 'Active',
                        );
                        ref.read(medicalAlertsProvider.notifier).addAlert(newAlert);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Alert "${newAlert.title}" broadcasted to all registered donors.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) => AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.gapSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: AppTypography.labelLarge),
              Text(label, style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );

  @override
  Widget build(BuildContext context) {
    final alerts = ref.watch(medicalAlertsProvider);

    final activeCount = alerts.where((a) => a.status == 'Active').length + 8;
    final completedCount = alerts.where((a) => a.status == 'Completed').length + 48;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Campus Medical & Emergency Donor Network', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0052CC),
          indicatorColor: const Color(0xFF0052CC),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Emergency Requests'),
            Tab(text: 'Blood Donor Inventory'),
            Tab(text: 'Medical Certificates'),
            Tab(text: 'Partner Clinics'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Emergency Requests List Tab
            Column(
              children: [
                // Metrics
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatCard('Active Alerts', '$activeCount', Icons.emergency_rounded, AppColors.error),
                        AppSpacing.gapSm,
                        _buildStatCard('Resolved Alerts', '$completedCount', Icons.task_alt_rounded, AppColors.success),
                        AppSpacing.gapSm,
                        _buildStatCard('Registered Donors', '412', Icons.volunteer_activism_rounded, const Color(0xFF0052CC)),
                        AppSpacing.gapSm,
                        _buildStatCard('Medical Leaves Pending', '14', Icons.medical_services_rounded, AppColors.warning),
                      ],
                    ),
                  ),
                ),

                // Alerts list
                Expanded(
                  child: alerts.isEmpty
                      ? const Center(child: Text('No active emergency blood requests.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: alerts.length,
                          itemBuilder: (context, idx) {
                            final alert = alerts[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.emergency_rounded, color: Colors.red, size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  alert.title,
                                                  style: AppTypography.labelLarge.copyWith(fontSize: 15, color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        AppSpacing.gapSm,
                                        AppStatusBadge(status: alert.status),
                                      ],
                                    ),
                                    AppSpacing.gapSm,
                                    Text(alert.description, style: AppTypography.bodyMedium),
                                    AppSpacing.gapSm,
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        Text('Broadcasted: ${alert.date}', style: AppTypography.bodySmall),
                                        if (alert.status == 'Active')
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            ),
                                            onPressed: () {
                                              ref.read(medicalAlertsProvider.notifier).deleteAlert(alert.id);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Emergency alert marked as resolved.')),
                                              );
                                            },
                                            child: const Text('Resolve Alert', style: TextStyle(fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // Blood Donor Inventory Grid Tab
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 3 : 2);
                return GridView.count(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: const [
                    _BloodGroupCard(group: 'O+', count: '142 Donors', status: 'High'),
                    _BloodGroupCard(group: 'A+', count: '98 Donors', status: 'Available'),
                    _BloodGroupCard(group: 'B+', count: '110 Donors', status: 'Available'),
                    _BloodGroupCard(group: 'AB+', count: '34 Donors', status: 'Limited'),
                    _BloodGroupCard(group: 'O-', count: '12 Donors', status: 'Urgent'),
                    _BloodGroupCard(group: 'A-', count: '8 Donors', status: 'Urgent'),
                    _BloodGroupCard(group: 'B-', count: '6 Donors', status: 'Urgent'),
                    _BloodGroupCard(group: 'AB-', count: '2 Donors', status: 'Critical'),
                  ],
                );
              },
            ),

            // Medical Certificates Queue Tab
            ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                _CertTile(student: 'Rohan Verma (22CS001)', reason: 'Fever & Dengue Recovery', days: '3 Days Medical Leave', date: '2026-07-20', status: 'Pending Review'),
                _CertTile(student: 'Priya Nair (22IT012)', reason: 'Sports Injury / Fracture', days: '7 Days Medical Leave', date: '2026-07-18', status: 'Approved'),
                _CertTile(student: 'Divya Krishnan (24IT001)', reason: 'Viral Infection', days: '2 Days Medical Leave', date: '2026-07-15', status: 'Approved'),
              ],
            ),

            // Partner Clinics Tab
            ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                _ClinicCard(name: 'KSR Campus Health Center', doc: 'Dr. R. Saravanan (MBBS)', phone: '+91 98421 11223', beds: '10 ICU Beds Available'),
                _ClinicCard(name: 'City General Hospital Partner', doc: 'Dr. M. Deepa (MD)', phone: '+91 94432 55667', beds: '25 Ambulance Fleet Nodes'),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
        onPressed: _showAddAlertSheet,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Post Blood Request'),
      ),
    );
  }
}

class _BloodGroupCard extends StatelessWidget {

  const _BloodGroupCard({required this.group, required this.count, required this.status});
  final String group;
  final String count;
  final String status;

  @override
  Widget build(BuildContext context) {
    var bg = const Color(0xFFEFF6FF);
    var statusColor = const Color(0xFF0052CC);
    if (status == 'Urgent' || status == 'Critical') {
      bg = const Color(0xFFFEE2E2);
      statusColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text(group, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: statusColor)),
          ),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _CertTile extends StatelessWidget {

  const _CertTile({
    required this.student,
    required this.reason,
    required this.days,
    required this.date,
    required this.status,
  });
  final String student;
  final String reason;
  final String days;
  final String date;
  final String status;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.file_present_rounded, color: Color(0xFF0052CC), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('$reason  •  $days', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('Applied: $date', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            AppStatusBadge(status: status),
          ],
        ),
      ),
    );
}

class _ClinicCard extends StatelessWidget {

  const _ClinicCard({
    required this.name,
    required this.doc,
    required this.phone,
    required this.beds,
  });
  final String name;
  final String doc;
  final String phone;
  final String beds;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF16A34A), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('In-Charge: $doc', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text('Phone: $phone  •  $beds', style: const TextStyle(fontSize: 11.5, color: Color(0xFF0052CC), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}
