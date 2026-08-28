import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_card.dart';
import '../services/faculty_service.dart';
class WorkloadScreen extends ConsumerStatefulWidget {
  const WorkloadScreen({super.key});

  @override
  ConsumerState<WorkloadScreen> createState() => _WorkloadScreenState();
}

class _WorkloadScreenState extends ConsumerState<WorkloadScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final result = await FacultyService.fetchFaculty();
      if (result.isNotEmpty) {
        setState(() {
          _data = result.map((e) => <String, dynamic>{
            'name': e['name']?.toString() ?? e['faculty_name']?.toString() ?? '',
            'dept': e['department_code']?.toString() ?? e['department']?.toString() ?? '',
            'hoursPerWeek': e['hours_per_week'] ?? 16,
            'subjectsAssigned': e['subjects_assigned'] ?? 3,
            'labsAssigned': e['labs_assigned'] ?? 1,
            'loadStatus': e['load_status']?.toString() ?? 'Optimal',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Faculty Workload & Allocation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Faculty Workload & Allocation', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Teaching Hours Allocation Summary', style: AppTypography.h3),
                    AppSpacing.gapLg,
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.5),
                        1: FlexColumnWidth(),
                        2: FlexColumnWidth(),
                        3: FlexColumnWidth(),
                        4: FlexColumnWidth(),
                      },
                      children: [
                        const TableRow(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          children: [
                            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Faculty Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Dept', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Hours / Wk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Load Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                        ),
                        ..._data.map((item) => TableRow(
                            children: [
                              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(item['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(item['dept'] as String, style: const TextStyle(fontSize: 12))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('${item['hoursPerWeek']} hrs', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                              Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('${item['subjectsAssigned']} Courses', style: const TextStyle(fontSize: 12))),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  item['loadStatus'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item['loadStatus'] == 'Heavy' ? Colors.red : const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
