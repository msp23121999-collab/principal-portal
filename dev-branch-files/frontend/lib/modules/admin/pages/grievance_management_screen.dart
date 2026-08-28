import 'package:flutter/material.dart';
import '../services/campus_services_backend.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';

class GrievanceManagementScreen extends StatefulWidget {
  const GrievanceManagementScreen({super.key});

  @override
  State<GrievanceManagementScreen> createState() =>
      _GrievanceManagementScreenState();
}

class _GrievanceManagementScreenState
    extends State<GrievanceManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _grievances = [];

  @override
  void initState() {
    super.initState();
    _loadGrievances();
  }

  Future<void> _loadGrievances() async {
    final data = await CampusServicesBackend.instance.getGrievances();
    if (mounted) {
      setState(() {
        _grievances = data;
        _isLoading = false;
      });
    }
  }

  void _showSubmitGrievanceModal() {
    final formKey = GlobalKey<FormState>();
    final byCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    final assignedCtrl = TextEditingController(text: 'HOD-CSE');
    String category = 'Academic';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Submit New Grievance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: byCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Submitted By (Name & Reg No)',
                        hintText: 'e.g. S. Priya (23CSE045)',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ['Academic', 'Hostel', 'Transport', 'Infrastructure', 'Finance']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setModalState(() => category = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: detailsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Complaint Details',
                        hintText: 'Describe your issue in detail...',
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: assignedCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Assign To',
                        hintText: 'Department Officer / Warden',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final gid = 'GRV-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}';
                              await CampusServicesBackend.instance.createGrievance({
                                'grievance_id': gid,
                                'submitted_by': byCtrl.text,
                                'category': category,
                                'details': detailsCtrl.text,
                                'submission_date': DateTime.now().toIso8601String(),
                                'status': 'Open',
                                'assigned_to': assignedCtrl.text,
                              });
                              if (context.mounted) Navigator.of(context).pop();
                              _loadGrievances();
                            }
                          },
                          child: const Text('Submit Complaint'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                      'Grievance Redressal & Redressal Cell',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Student, faculty & staff complaint resolution tracking (public.grievances)',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'Submit Grievance',
                  icon: Icons.report_problem_rounded,
                  onPressed: _showSubmitGrievanceModal,
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
                        'Active Complaints & Ticket Logs',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadGrievances,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_grievances.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No grievances found in database. Click "Submit Grievance" to add one.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Table(
                      border: TableBorder.symmetric(
                        inside: const BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      children: [
                        TableRow(
                          decoration:
                              const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _buildHeader('GRIEVANCE ID'),
                            _buildHeader('SUBMITTED BY'),
                            _buildHeader('CATEGORY'),
                            _buildHeader('DETAILS'),
                            _buildHeader('ASSIGNED TO'),
                            _buildHeader('STATUS'),
                          ],
                        ),
                        ..._grievances.map(
                          (g) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  g['grievance_id'] ?? g['id'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(g['submitted_by'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(g['category'] ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  g['details'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(g['assigned_to'] ?? 'Unassigned'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: AppStatusBadge(
                                  status: g['status'] ?? 'Open',
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
