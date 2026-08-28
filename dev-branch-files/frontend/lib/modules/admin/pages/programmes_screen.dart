import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';
import '../services/programme_subject_service.dart';

class ProgrammesScreen extends ConsumerStatefulWidget {
  const ProgrammesScreen({super.key});

  @override
  ConsumerState<ProgrammesScreen> createState() => _ProgrammesScreenState();
}

class _ProgrammesScreenState extends ConsumerState<ProgrammesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await ProgrammeSubjectService.fetchProgrammes();
      if (result.isNotEmpty) {
        setState(() {
          _data = result.map((e) => <String, dynamic>{
            'id': e['id']?.toString(),
            'code': e['code']?.toString() ?? '',
            'name': e['name']?.toString() ?? '',
            'degree': e['degree']?.toString() ?? 'UG',
            'years': e['duration_years'] ?? e['duration'] ?? e['years'] ?? 4,
            'intake': e['intake_seats'] ?? e['intake'] ?? 60,
            'dept': e['department']?.toString() ?? e['department_code']?.toString() ?? e['dept']?.toString() ?? '',
            'status': e['status']?.toString() ?? 'Active',
          }).toList();
          _loading = false;
        });
      } else {
        setState(() { _data = []; _loading = false; });
      }
    } catch (_) {
      setState(() { _data = []; _loading = false; });
    }
  }

  // Valid dropdown options
  static const List<String> _degreeOptions = ['UG', 'PG', 'Ph.D.'];
  static const List<String> _deptOptions = ['CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL'];

  void _showAddProgrammeSheet([Map<String, dynamic>? editItem]) {
    final nameCtrl = TextEditingController(text: editItem != null ? editItem['name'] : '');
    final codeCtrl = TextEditingController(text: editItem != null ? editItem['code'] : '');
    final intakeCtrl = TextEditingController(text: editItem != null ? '${editItem['intake']}' : '60');

    // Validate values against dropdown lists — fall back to first item if not found
    final rawDegree = editItem != null ? (editItem['degree'] ?? '') : 'UG';
    final rawDept = editItem != null ? (editItem['dept'] ?? '') : 'CSE';
    String degreeVal = _degreeOptions.contains(rawDegree) ? rawDegree : _degreeOptions.first;
    String deptVal = _deptOptions.contains(rawDept) ? rawDept : _deptOptions.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editItem != null ? 'Edit Academic Programme' : 'Add New Academic Programme',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Programme Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: codeCtrl,
                          decoration: const InputDecoration(labelText: 'Programme Code', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: intakeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Intake Capacity', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: degreeVal,
                          decoration: const InputDecoration(labelText: 'Degree Type', border: OutlineInputBorder()),
                          items: _degreeOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setSheetState(() => degreeVal = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: deptVal,
                          decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                          items: _deptOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) => setSheetState(() => deptVal = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (nameCtrl.text.isNotEmpty && codeCtrl.text.isNotEmpty) {
                        final payload = {
                          'code': codeCtrl.text.trim(),
                          'name': nameCtrl.text.trim(),
                          'duration': degreeVal == 'UG' ? '4 Years' : '2 Years',
                          'status': 'Active',
                        };

                        if (editItem != null && editItem['id'] != null) {
                          await ProgrammeSubjectService.updateProgramme(
                            editItem['id'].toString(),
                            payload,
                          );
                        } else {
                          await ProgrammeSubjectService.createProgramme(payload);
                        }

                        if (mounted) {
                          Navigator.pop(context);
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(editItem != null ? 'Programme updated successfully!' : 'Programme added successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(editItem != null ? 'Update Programme' : 'Save Programme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Academic Programmes & Degrees', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filtered = _data.where((p) {
      final q = _searchQuery.toLowerCase();
      return (p['name'] as String).toLowerCase().contains(q) || (p['code'] as String).toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Academic Programmes & Degrees', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search programme by name or code...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddProgrammeSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Programme'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 110,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        return AppCard(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      item['code'] as String,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item['name'] as String,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  AppStatusBadge(status: item['status'] as String),
                                ],
                              ),
                              const Divider(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['degree']} • ${item['years']} Years Duration',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'Dept: ${item['dept']}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      'Intake: ${item['intake']} Seats',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                        onPressed: () => _showAddProgrammeSheet(item),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                        onPressed: () => setState(() => _data.removeAt(idx)),
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
      ),
    );
  }
}
