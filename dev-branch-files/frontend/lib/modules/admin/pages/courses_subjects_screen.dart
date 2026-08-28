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
// Department tab model
class _Dept {
  const _Dept(this.code, this.label, this.color);
  final String code;
  final String label;
  final Color color;
}

const List<_Dept> _departments = [
  _Dept('ALL', 'All Departments', Color(0xFF374151)),
  _Dept('CSE', 'Computer Science', Color(0xFF1D4ED8)),
  _Dept('IT', 'Information Technology', Color(0xFF0891B2)),
  _Dept('ECE', 'Electronics & Comm.', Color(0xFF7C3AED)),
  _Dept('AI&DS', 'AI & Data Science', Color(0xFF059669)),
];

class CoursesSubjectsScreen extends ConsumerStatefulWidget {
  const CoursesSubjectsScreen({super.key});

  @override
  ConsumerState<CoursesSubjectsScreen> createState() => _CoursesSubjectsScreenState();
}

class _CoursesSubjectsScreenState extends ConsumerState<CoursesSubjectsScreen> {
  bool _showCourses = true;
  String _selectedDept = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Add Course Form
  final _courseFormKey = GlobalKey<FormState>();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  String _courseDept = 'CSE';

  // Add Subject Form
  final _subjectFormKey = GlobalKey<FormState>();
  final _subjectCodeController = TextEditingController();
  final _subjectNameController = TextEditingController();
  String _subjectType = 'Theory';
  String _subjectDept = 'CSE';
  final _subjectCreditsController = TextEditingController(text: '3');

  @override
  void dispose() {
    _searchController.dispose();
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _subjectCreditsController.dispose();
    super.dispose();
  }

  void _showAddCourseSheet() {
    _courseCodeController.clear();
    _courseNameController.clear();
    _courseDept = _selectedDept == 'ALL' ? 'CSE' : _selectedDept;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusLg)),
      ),
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _courseFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New Course', style: AppTypography.h2),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                    const Divider(),
                    AppSpacing.gapMd,
                    AppTextField(
                      label: 'Course Name',
                      hintText: 'Bachelor of Technology (CSE)',
                      controller: _courseNameController,
                      validator: (val) => val == null || val.isEmpty ? 'Course Name is required' : null,
                    ),
                    AppSpacing.gapMd,
                    Row(children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Course Code',
                          hintText: 'B.E. CSE',
                          controller: _courseCodeController,
                          validator: (val) => val == null || val.isEmpty ? 'Course Code is required' : null,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Department', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                            AppSpacing.gapXs,
                            DropdownButtonFormField<String>(
                              initialValue: _courseDept,
                              decoration: const InputDecoration(),
                              items: ['CSE', 'IT', 'ECE', 'AI&DS'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (val) { if (val != null) setSheetState(() => _courseDept = val); },
                            ),
                          ],
                        ),
                      ),
                    ]),
                    AppSpacing.gapLg,
                    AppButton(
                      label: 'Save Course',
                      onPressed: () {
                        if (_courseFormKey.currentState!.validate()) {
                          final newCourse = CourseModel(
                            id: 'CRS${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            code: _courseCodeController.text.toUpperCase(),
                            name: _courseNameController.text,
                            department: _courseDept,
                            subjectsCount: 0,
                            status: 'Active',
                          );
                          ref.read(coursesProvider.notifier).addCourse(newCourse);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Course "${newCourse.name}" added.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
    );
  }

  void _showAddSubjectSheet() {
    _subjectCodeController.clear();
    _subjectNameController.clear();
    _subjectType = 'Theory';
    _subjectDept = _selectedDept == 'ALL' ? 'CSE' : _selectedDept;
    _subjectCreditsController.text = '3';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusLg)),
      ),
      builder: (context) => StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.lg, right: AppSpacing.lg, top: AppSpacing.lg,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _subjectFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New Subject', style: AppTypography.h2),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                    const Divider(),
                    AppSpacing.gapMd,
                    AppTextField(
                      label: 'Subject Name',
                      hintText: 'Operating Systems',
                      controller: _subjectNameController,
                      validator: (val) => val == null || val.isEmpty ? 'Subject Name is required' : null,
                    ),
                    AppSpacing.gapMd,
                    Row(children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Subject Code',
                          hintText: 'CS-401',
                          controller: _subjectCodeController,
                          validator: (val) => val == null || val.isEmpty ? 'Subject Code is required' : null,
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: AppTextField(
                          label: 'Credits',
                          hintText: '3',
                          controller: _subjectCreditsController,
                          keyboardType: TextInputType.number,
                          validator: (val) => val == null || int.tryParse(val) == null ? 'Enter valid number' : null,
                        ),
                      ),
                    ]),
                    AppSpacing.gapMd,
                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Subject Type', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                            AppSpacing.gapXs,
                            DropdownButtonFormField<String>(
                              initialValue: _subjectType,
                              decoration: const InputDecoration(),
                              items: ['Theory', 'Lab', 'Theory + Lab', 'Elective'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) { if (val != null) setSheetState(() => _subjectType = val); },
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Department', style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
                            AppSpacing.gapXs,
                            DropdownButtonFormField<String>(
                              initialValue: _subjectDept,
                              decoration: const InputDecoration(),
                              items: ['CSE', 'IT', 'ECE', 'AI&DS'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (val) { if (val != null) setSheetState(() => _subjectDept = val); },
                            ),
                          ],
                        ),
                      ),
                    ]),
                    AppSpacing.gapLg,
                    AppButton(
                      label: 'Save Subject',
                      onPressed: () {
                        if (_subjectFormKey.currentState!.validate()) {
                          final newSub = SubjectModel(
                            id: 'SUB${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                            code: _subjectCodeController.text.toUpperCase(),
                            name: _subjectNameController.text,
                            type: _subjectType,
                            credits: int.parse(_subjectCreditsController.text),
                            status: 'Active',
                            department: _subjectDept,
                          );
                          ref.read(subjectsProvider.notifier).addSubject(newSub);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Subject "${newSub.name}" added.'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
    );
  }

  void _confirmDeleteCourse(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: 'Delete Course — ${course.name}',
        content: 'Permanently delete this course?\n\nCourse: ${course.name}\nCode: ${course.code} | Dept: ${course.department}',
        confirmLabel: 'Yes, Delete',
        cancelLabel: 'No, Cancel',
        verifyText: course.code,
        verifyHint: 'Type "${course.code}" to confirm:',
        onConfirm: () {
          ref.read(coursesProvider.notifier).deleteCourse(course.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Course "${course.name}" deleted.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  void _confirmDeleteSubject(SubjectModel subject) {
    showDialog(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: 'Delete Subject — ${subject.name}',
        content: 'Permanently delete this subject?\n\nSubject: ${subject.name}\nCode: ${subject.code} | Credits: ${subject.credits}',
        confirmLabel: 'Yes, Delete',
        cancelLabel: 'No, Cancel',
        verifyText: subject.code,
        verifyHint: 'Type "${subject.code}" to confirm:',
        onConfirm: () {
          ref.read(subjectsProvider.notifier).deleteSubject(subject.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Subject "${subject.name}" deleted.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCourses = ref.watch(coursesProvider);
    final allSubjects = ref.watch(subjectsProvider);

    // Department filter
    final filteredCourses = allCourses.where((c) {
      final deptMatch = _selectedDept == 'ALL' || c.department == _selectedDept;
      final searchMatch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return deptMatch && searchMatch;
    }).toList();

    final filteredSubjects = allSubjects.where((s) {
      final deptMatch = _selectedDept == 'ALL' || s.department == _selectedDept;
      final searchMatch = _searchQuery.isEmpty ||
          s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.code.toLowerCase().contains(_searchQuery.toLowerCase());
      return deptMatch && searchMatch;
    }).toList();

    // Count per dept for badge
    var deptCourseCounts = <String, int>{};
    final deptSubjectCounts = <String, int>{};
    for (final d in _departments) {
      if (d.code == 'ALL') {
        deptCourseCounts['ALL'] = allCourses.length;
        deptSubjectCounts['ALL'] = allSubjects.length;
      } else {
        deptCourseCounts[d.code] = allCourses.where((c) => c.department == d.code).length;
        deptSubjectCounts[d.code] = allSubjects.where((s) => s.department == d.code).length;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header strip ───────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Courses / Subjects toggle
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(children: [
                      _ToggleTab(label: 'Courses & Curriculum', icon: Icons.menu_book_rounded, selected: _showCourses, onTap: () => setState(() { _showCourses = true; _searchQuery = ''; _searchController.clear(); })),
                      _ToggleTab(label: 'Subjects & Syllabi', icon: Icons.auto_stories_rounded, selected: !_showCourses, onTap: () => setState(() { _showCourses = false; _searchQuery = ''; _searchController.clear(); })),
                    ]),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Department tabs
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _departments.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final dept = _departments[i];
                        final isSelected = _selectedDept == dept.code;
                        final count = _showCourses
                            ? (deptCourseCounts[dept.code] ?? 0)
                            : (deptSubjectCounts[dept.code] ?? 0);
                        return _DeptTab(
                          dept: dept,
                          isSelected: isSelected,
                          count: count,
                          onTap: () => setState(() { _selectedDept = dept.code; _searchQuery = ''; _searchController.clear(); }),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),

            // ─── Search bar ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTypography.bodyLarge,
                decoration: InputDecoration(
                  hintText: _showCourses
                      ? 'Search courses by name or code...'
                      : 'Search subjects by name or code...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted),
                          onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                        )
                      : null,
                ),
              ),
            ),

            // ─── Content ─────────────────────────────────────────────
            Expanded(
              child: _showCourses
                  ? _buildCoursesGrid(filteredCourses)
                  : _buildSubjectsGrid(filteredSubjects),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
        onPressed: _showCourses ? _showAddCourseSheet : _showAddSubjectSheet,
        icon: const Icon(Icons.add_rounded),
        label: Text(_showCourses ? 'Add Course' : 'Add Subject'),
      ),
    );
  }

  Widget _buildCoursesGrid(List<CourseModel> courses) {
    if (courses.isEmpty) {
      return AppEmptyState(
        title: 'No Courses Found',
        description: _selectedDept == 'ALL'
            ? 'No courses match your search.'
            : 'No courses found under the $_selectedDept department.',
        icon: Icons.menu_book_outlined,
        actionLabel: 'Clear Filter',
        onActionPressed: () => setState(() { _selectedDept = 'ALL'; _searchQuery = ''; _searchController.clear(); }),
      );
    }

    // If ALL dept selected, group by department
    if (_selectedDept == 'ALL') {
      final grouped = <String, List<CourseModel>>{};
      for (final c in courses) {
        grouped.putIfAbsent(c.department, () => []).add(c);
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: grouped.entries.map((entry) {
          final dept = _departments.firstWhere((d) => d.code == entry.key, orElse: () => _Dept(entry.key, entry.key, const Color(0xFF374151)));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeptSectionHeader(dept: dept, count: entry.value.length),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.2,
                  children: entry.value.map((course) => _CourseCard(course: course, onDelete: () => _confirmDeleteCourse(course))).toList(),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        }).toList(),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 120,
        ),
        itemCount: courses.length,
        itemBuilder: (context, idx) => _CourseCard(course: courses[idx], onDelete: () => _confirmDeleteCourse(courses[idx])),
      );
    });
  }

  Widget _buildSubjectsGrid(List<SubjectModel> subjects) {
    if (subjects.isEmpty) {
      return AppEmptyState(
        title: 'No Subjects Found',
        description: _selectedDept == 'ALL'
            ? 'No subjects match your search.'
            : 'No subjects found under the $_selectedDept department.',
        icon: Icons.auto_stories_outlined,
        actionLabel: 'Clear Filter',
        onActionPressed: () => setState(() { _selectedDept = 'ALL'; _searchQuery = ''; _searchController.clear(); }),
      );
    }

    if (_selectedDept == 'ALL') {
      final grouped = <String, List<SubjectModel>>{};
      for (final s in subjects) {
        grouped.putIfAbsent(s.department, () => []).add(s);
      }
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: grouped.entries.map((entry) {
          final dept = _departments.firstWhere((d) => d.code == entry.key, orElse: () => _Dept(entry.key, entry.key, const Color(0xFF374151)));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DeptSectionHeader(dept: dept, count: entry.value.length),
              const SizedBox(height: AppSpacing.sm),
              LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3.2,
                  children: entry.value.map((s) => _SubjectCard(subject: s, onDelete: () => _confirmDeleteSubject(s))).toList(),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
            ],
          );
        }).toList(),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 120,
        ),
        itemCount: subjects.length,
        itemBuilder: (context, idx) => _SubjectCard(subject: subjects[idx], onDelete: () => _confirmDeleteSubject(subjects[idx])),
      );
    });
  }
}

// ─── Subwidgets ──────────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {

  const _ToggleTab({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.labelLarge.copyWith(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
}

class _DeptTab extends StatelessWidget {

  const _DeptTab({required this.dept, required this.isSelected, required this.count, required this.onTap});
  final _Dept dept;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? dept.color : dept.color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? dept.color : dept.color.withAlpha(77), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dept.code == 'ALL' ? 'All' : dept.code,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : dept.color,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(64) : dept.color.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : dept.color,
                  fontFamily: AppTypography.fontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}

class _DeptSectionHeader extends StatelessWidget {

  const _DeptSectionHeader({required this.dept, required this.count});
  final _Dept dept;
  final int count;

  @override
  Widget build(BuildContext context) => Row(children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(color: dept.color, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 10),
      Text(
        dept.label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: dept.color,
          fontFamily: AppTypography.fontFamily,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: dept.color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dept.color, fontFamily: AppTypography.fontFamily)),
      ),
    ]);
}

class _CourseCard extends StatelessWidget {

  const _CourseCard({required this.course, required this.onDelete});
  final CourseModel course;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dept = _departments.firstWhere((d) => d.code == course.department, orElse: () => _Dept(course.department, course.department, const Color(0xFF374151)));
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: dept.color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text(course.code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dept.color, fontFamily: AppTypography.fontFamily)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(course.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
            AppStatusBadge(status: course.status),
          ]),
          const Divider(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: dept.color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                child: Text(course.department, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dept.color, fontFamily: AppTypography.fontFamily)),
              ),
              const SizedBox(width: 8),
              Text('${course.subjectsCount} Subjects', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            IconButton(
              constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 16),
              onPressed: onDelete,
            ),
          ]),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {

  const _SubjectCard({required this.subject, required this.onDelete});
  final SubjectModel subject;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dept = _departments.firstWhere((d) => d.code == subject.department, orElse: () => _Dept(subject.department, subject.department, const Color(0xFF374151)));
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: dept.color.withAlpha(25), borderRadius: BorderRadius.circular(6)),
              child: Text(subject.code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dept.color, fontFamily: AppTypography.fontFamily)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(subject.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
            AppStatusBadge(status: subject.status),
          ]),
          const Divider(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: dept.color.withAlpha(25), borderRadius: BorderRadius.circular(4)),
                child: Text(subject.department, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dept.color, fontFamily: AppTypography.fontFamily)),
              ),
              const SizedBox(width: 8),
              Text('${subject.credits} Credits', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: Text(subject.type.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 4),
              IconButton(
                constraints: const BoxConstraints(), padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 16),
                onPressed: onDelete,
              ),
            ]),
          ]),
        ],
      ),
    );
  }
}
