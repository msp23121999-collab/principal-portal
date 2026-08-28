import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_status_badge.dart';
import '../widgets/app_text_field.dart';
import '../erp_repository.dart';
import '../utils/file_downloader.dart';
import '../services/regulation_service.dart';

class RegulationsScreen extends ConsumerStatefulWidget {
  const RegulationsScreen({super.key});

  @override
  ConsumerState<RegulationsScreen> createState() => _RegulationsScreenState();
}

class _RegulationsScreenState extends ConsumerState<RegulationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Form Fields
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _schemeController = TextEditingController();
  final _criteriaController = TextEditingController();
  final _creditsController = TextEditingController(text: '160');
  String _status = 'Active';

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    _schemeController.dispose();
    _criteriaController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _showAddRegulationSheet() {
    _codeController.clear();
    _schemeController.clear();
    _criteriaController.clear();
    _creditsController.text = '160';
    _status = 'Active';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusLg)),
      ),
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
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
                          Text('Create Regulation Schema', style: AppTypography.h2),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      AppSpacing.gapMd,
                      AppTextField(
                        label: 'Regulation Code',
                        hintText: 'REG-2026-NEP',
                        controller: _codeController,
                        validator: (val) => val == null || val.isEmpty ? 'Code is required' : null,
                      ),
                      AppSpacing.gapMd,
                      AppTextField(
                        label: 'Scheme & Framework Title',
                        hintText: 'National Education Policy Framework',
                        controller: _schemeController,
                        validator: (val) => val == null || val.isEmpty ? 'Scheme is required' : null,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Total Credits Req.',
                              hintText: '164',
                              controller: _creditsController,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: AppTextField(
                              label: 'Passing Threshold Criteria',
                              hintText: '40% Minimum',
                              controller: _criteriaController,
                              validator: (val) => val == null || val.isEmpty ? 'Criteria is required' : null,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      Text('Activation Status', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                      AppSpacing.gapXs,
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(),
                        items: ['Active', 'Inactive'].map((status) {
                          return DropdownMenuItem(value: status, child: Text(status));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => _status = val);
                        },
                      ),
                      AppSpacing.gapLg,
                      AppButton(
                        label: 'Initialize Regulation Schema',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final newReg = RegulationModel(
                              id: 'REG${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              code: _codeController.text.toUpperCase(),
                              scheme: _schemeController.text,
                              department: 'ALL',
                              semester: 1,
                              passingCriteria: _criteriaController.text,
                              totalCredits: double.tryParse(_creditsController.text) ?? 3.0,
                              status: _status,
                            );
                            final nav = Navigator.of(context);
                            final messenger = ScaffoldMessenger.of(context);
                            ref.read(regulationsProvider.notifier).addRegulation(newReg);
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Regulation "${newReg.code}" initialized successfully.'),
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
            );
          },
        ),
    );
  }



  void _confirmDelete(RegulationModel reg) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmationDialog(
          title: 'Delete Regulation — ${reg.code}',
          content: 'You are about to permanently delete this regulation schema.\n\nRegulation: ${reg.code}\nScheme: ${reg.scheme}\nTotal Credits: ${reg.totalCredits} | Passing Criteria: ${reg.passingCriteria}',
          confirmLabel: 'Yes, Delete',
          cancelLabel: 'No, Cancel',
          type: ConfirmationType.delete,
          verifyText: reg.code,
          verifyHint: 'Type "${reg.code}" to confirm deletion:',
          onConfirm: () {
            ref.read(regulationsProvider.notifier).deleteRegulation(reg.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Regulation schema has been permanently deleted.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regs = ref.watch(regulationsProvider);

    final filteredRegs = regs.where((r) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return r.code.toLowerCase().contains(q) ||
          r.scheme.toLowerCase().contains(q) ||
          r.department.toLowerCase().contains(q) ||
          r.passingCriteria.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Academic Regulations & Schemes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh Regulations',
            onPressed: () => ref.read(regulationsProvider.notifier).loadRegulations(),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0052CC)),
            tooltip: 'Export Regulations CSV',
            onPressed: () async {
              final todayStr = DateTime.now().toIso8601String().split('T')[0];
              final messenger = ScaffoldMessenger.of(context);
              final liveRegs = await RegulationService.fetchRegulations();
              final buffer = StringBuffer();
              buffer.writeln('Regulation Year,Course Code,Course Name,Department,Semester,Credits,Type,Status');
              if (liveRegs.isEmpty) {
                for (final r in filteredRegs) {
                  buffer.writeln('${r.code},"${r.scheme}",${r.department},${r.semester},${r.totalCredits},"${r.passingCriteria}",${r.status}');
                }
              } else {
                for (final r in liveRegs) {
                  final regYr = r['regulation_year']?.toString() ?? 'R2024';
                  final crsCode = r['course_code']?.toString() ?? '';
                  final name = r['course_name']?.toString() ?? 'Course';
                  final dept = r['department']?.toString() ?? 'CSE';
                  final sem = r['semester']?.toString() ?? '1';
                  final cred = r['credits']?.toString() ?? '3.0';
                  final type = r['course_type']?.toString() ?? 'Theory';
                  buffer.writeln('$regYr,$crsCode,"$name",$dept,$sem,$cred,"$type",Active');
                }
              }
              FileDownloader.downloadCSV(buffer.toString(), 'academic_regulations_$todayStr.csv');
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Academic Regulations exported to CSV!'), backgroundColor: Color(0xFF16A34A)),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search regulations by code or scheme (e.g. REG-2023)...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Regulation Cards
            Expanded(
              child: filteredRegs.isEmpty
                  ? AppEmptyState(
                      title: _searchQuery.isNotEmpty ? 'No Matching Regulations' : 'No Regulations Found',
                      description: _searchQuery.isNotEmpty
                          ? 'No regulations found matching "$_searchQuery".'
                          : 'No academic regulation records were returned from master database.',
                      icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.gavel_rounded,
                      actionLabel: _searchQuery.isNotEmpty ? 'Reset Search' : 'Refresh Database',
                      onActionPressed: () {
                        if (_searchQuery.isNotEmpty) {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        } else {
                          ref.read(regulationsProvider.notifier).loadRegulations();
                        }
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 135,
                          ),
                          itemCount: filteredRegs.length,
                          itemBuilder: (context, idx) {
                            final reg = filteredRegs[idx];
                            final deptInfo = reg.department != 'ALL' ? '${reg.department} • Sem ${reg.semester}' : 'Autonomous';

                            return AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryLight,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              reg.code,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(deptInfo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                          ),
                                        ],
                                      ),
                                      AppStatusBadge(status: reg.status),
                                    ],
                                  ),
                                  Text(
                                    reg.scheme,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Divider(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          _ChipDetail(icon: Icons.credit_score_rounded, label: '${reg.totalCredits} Credits'),
                                          const SizedBox(width: 12),
                                          _ChipDetail(icon: Icons.verified_rounded, label: reg.passingCriteria),
                                        ],
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                        onPressed: () => _confirmDelete(reg),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
        onPressed: _showAddRegulationSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Regulation'),
      ),
    );
  }
}

class _ChipDetail extends StatelessWidget {
  const _ChipDetail({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
}
