import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_status_badge.dart';
import '../widgets/app_text_field.dart';
import '../erp_repository.dart';
import '../utils/file_downloader.dart';
import '../services/department_service.dart';
import '../services/admin_user_service.dart';
class DepartmentListScreen extends ConsumerStatefulWidget {
  const DepartmentListScreen({super.key});

  @override
  ConsumerState<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends ConsumerState<DepartmentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Timer _timer;
  late DateTime _currentTime;

  // Form Fields
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _hodController = TextEditingController();
  final _capacityController = TextEditingController();
  String _status = 'Active';

  Map<String, int> _dbStudentCounts = {};

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _loadStudentCounts();
  }

  Future<void> _loadStudentCounts() async {
    try {
      final liveUsers = await AdminUserService.fetchAllUsers();
      final counts = <String, int>{};

      for (final u in liveUsers) {
        final role = (u['role'] ?? '').toString().trim().toLowerCase();
        if (role == 'student' || role.contains('student')) {
          final dept = (u['department'] ?? '').toString().trim().toUpperCase();
          if (dept.isNotEmpty) {
            counts[dept] = (counts[dept] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          _dbStudentCounts = counts;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _hodController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _showAddDepartmentSheet() {
    _nameController.clear();
    _codeController.clear();
    _hodController.clear();
    _capacityController.clear();
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
                          Text('Add New Department', style: AppTypography.h2),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      AppSpacing.gapMd,
                      AppTextField(
                        label: 'Department Name',
                        hintText: 'Computer Science & Engineering',
                        controller: _nameController,
                        validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Dept Code',
                              hintText: 'CSE',
                              controller: _codeController,
                              validator: (val) => val == null || val.isEmpty ? 'Code is required' : null,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: AppTextField(
                              label: 'Intake Capacity',
                              hintText: '180',
                              controller: _capacityController,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      AppTextField(
                        label: 'Department Head (HOD)',
                        hintText: 'Dr. Suresh Kumar',
                        controller: _hodController,
                        validator: (val) => val == null || val.isEmpty ? 'HOD Name is required' : null,
                      ),
                      AppSpacing.gapMd,
                      Text('Cluster Status', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
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
                        label: 'Save Department Node',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final newDept = DepartmentModel(
                              id: 'DEP${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                              name: _nameController.text,
                              code: _codeController.text.toUpperCase(),
                              hod: _hodController.text.isNotEmpty ? _hodController.text : 'Dr. Head of Dept',
                              intakeCapacity: int.tryParse(_capacityController.text) ?? 60,
                              status: _status,
                            );
                            ref.read(departmentsProvider.notifier).addDepartment(newDept);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Department "${newDept.name}" added successfully.'),
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

  void _showEditDepartmentSheet(DepartmentModel dept) {
    _nameController.text = dept.name;
    _codeController.text = dept.code;
    _hodController.text = dept.hod;
    _capacityController.text = dept.intakeCapacity.toString();
    _status = dept.status;

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
                          Text('Edit Department', style: AppTypography.h2),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      AppSpacing.gapMd,
                      AppTextField(
                        label: 'Department Name',
                        controller: _nameController,
                        validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                      ),
                      AppSpacing.gapMd,
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Dept Code',
                              controller: _codeController,
                              validator: (val) => val == null || val.isEmpty ? 'Code is required' : null,
                            ),
                          ),
                          AppSpacing.gapMd,
                          Expanded(
                            child: AppTextField(
                              label: 'Intake Capacity',
                              controller: _capacityController,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapMd,
                      AppTextField(
                        label: 'Department Head (HOD)',
                        controller: _hodController,
                        validator: (val) => val == null || val.isEmpty ? 'HOD Name is required' : null,
                      ),
                      AppSpacing.gapMd,
                      Text('Cluster Status', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
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
                        label: 'Update Department Node',
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final updatedDept = dept.copyWith(
                              name: _nameController.text,
                              code: _codeController.text.toUpperCase(),
                              hod: _hodController.text,
                              intakeCapacity: int.parse(_capacityController.text),
                              status: _status,
                            );
                            ref.read(departmentsProvider.notifier).updateDepartment(updatedDept);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Department "${updatedDept.name}" updated successfully.'),
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

  void _confirmDelete(DepartmentModel dept) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmationDialog(
          title: 'Delete Department — ${dept.name}',
          content: 'You are about to permanently delete this department.\n\nDepartment: ${dept.name}\nCode: ${dept.code} | HOD: ${dept.hod}\nIntake Capacity: ${dept.intakeCapacity} Students',
          confirmLabel: 'Yes, Delete',
          cancelLabel: 'No, Cancel',
          type: ConfirmationType.delete,
          verifyText: dept.code,
          verifyHint: 'Type "${dept.code}" to confirm deletion:',
          onConfirm: () {
            ref.read(departmentsProvider.notifier).deleteDepartment(dept.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Department "${dept.name}" has been permanently deleted.'),
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
    final depts = ref.watch(departmentsProvider);
    final users = ref.watch(usersProvider);

    int getStudentCount(DepartmentModel dept) {
      final code = dept.code.trim().toUpperCase();
      final name = dept.name.trim().toLowerCase();

      final providerCount = users.where((u) {
        final role = u.role.trim().toLowerCase();
        if (role != 'student' && !role.contains('student')) return false;
        final uDept = u.department.trim().toLowerCase();
        if (uDept.isEmpty) return false;

        return uDept == name || uDept == code.toLowerCase() || uDept.contains(code.toLowerCase()) || name.contains(uDept);
      }).length;

      if (providerCount > 0) return providerCount;

      if (_dbStudentCounts.containsKey(code)) {
        return _dbStudentCounts[code]!;
      }
      for (final entry in _dbStudentCounts.entries) {
        if (entry.key.toLowerCase().contains(code.toLowerCase()) || name.contains(entry.key.toLowerCase())) {
          return entry.value;
        }
      }

      return 0;
    }

    final filteredDepts = depts.where((d) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return d.name.toLowerCase().contains(q) ||
          d.code.toLowerCase().contains(q) ||
          d.hod.toLowerCase().contains(q);
    }).toList();

    final liveTimeStr = DateFormat('d MMM yyyy • hh:mm:ss a').format(_currentTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Academic Departments Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh Departments',
            onPressed: () => ref.read(departmentsProvider.notifier).loadDepartments(),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0052CC)),
            tooltip: 'Export Departments CSV',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final todayStr = DateTime.now().toIso8601String().split('T')[0];
              final liveDepts = await DepartmentService.fetchDepartments();
              final buffer = StringBuffer();
              buffer.writeln('Department Code,Department Name,HOD,Intake Capacity,Status');
              if (liveDepts.isEmpty) {
                for (final d in filteredDepts) {
                  buffer.writeln('${d.code},"${d.name}","${d.hod}",${d.intakeCapacity},${d.status}');
                }
              } else {
                for (final d in liveDepts) {
                  final code = d['code']?.toString() ?? d['dept']?.toString() ?? 'DEPT';
                  final name = d['name']?.toString() ?? d['department_name']?.toString() ?? 'Department';
                  final hod = d['hod_name']?.toString() ?? d['hod']?.toString() ?? 'HOD';
                  final cap = d['program_count']?.toString() ?? d['capacity']?.toString() ?? '60';
                  buffer.writeln('$code,"$name","$hod",$cap,${d['is_active'] == true ? 'Active' : (d['status'] ?? 'Active')}');
                }
              }
              FileDownloader.downloadCSV(buffer.toString(), 'departments_directory_$todayStr.csv');
              messenger.showSnackBar(
                const SnackBar(content: Text('Departments directory exported to CSV!'), backgroundColor: Color(0xFF16A34A)),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Last Updated: $liveTimeStr', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
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
                  hintText: 'Search by department name, HOD, or code...',
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

            // Grid of compact department cards
            Expanded(
              child: filteredDepts.isEmpty
                  ? AppEmptyState(
                      title: _searchQuery.isNotEmpty ? 'No Matching Departments' : 'No Departments Found',
                      description: _searchQuery.isNotEmpty
                          ? 'No academic departments match "$_searchQuery".'
                          : 'No academic department records were returned from the database.',
                      icon: _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.domain_disabled_rounded,
                      actionLabel: _searchQuery.isNotEmpty ? 'Reset Search' : 'Refresh Database',
                      onActionPressed: () {
                        if (_searchQuery.isNotEmpty) {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        } else {
                          ref.read(departmentsProvider.notifier).loadDepartments();
                        }
                      },
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                        return GridView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 142,
                          ),
                          itemCount: filteredDepts.length,
                          itemBuilder: (context, idx) {
                            final dept = filteredDepts[idx];
                            return AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          dept.code,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dept.name,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Registry: ${dept.id}',
                                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AppStatusBadge(status: dept.status),
                                    ],
                                  ),
                                  const Divider(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'HOD: ${dept.hod}',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFBFDBFE)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.school_rounded, size: 12, color: Color(0xFF0052CC)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${getStudentCount(dept)} Students',
                                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0052CC)),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Intake: ${dept.intakeCapacity}',
                                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                            onPressed: () => _showEditDepartmentSheet(dept),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                                            onPressed: () => _confirmDelete(dept),
                                          ),
                                        ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
        onPressed: _showAddDepartmentSheet,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
