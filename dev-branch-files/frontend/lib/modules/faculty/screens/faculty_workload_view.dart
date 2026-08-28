// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/student_service.dart';
import '../services/workload_service.dart';

/// Faculty Workload View (Faculty Portal — Index 19)
///
/// Read-Only view for logged-in Faculty to inspect their assigned teaching
/// workload and academic responsibilities.
class FacultyWorkloadView extends StatefulWidget {
  const FacultyWorkloadView({super.key});

  @override
  State<FacultyWorkloadView> createState() => _FacultyWorkloadViewState();
}

class _FacultyWorkloadViewState extends State<FacultyWorkloadView> {
  final repo = ErpRepository();
  List<Map<String, dynamic>> _timetableData = [];

  @override
  void initState() {
    super.initState();
    _loadWorkloadData();
  }

  Future<void> _loadWorkloadData() async {
    final facultyId = repo.profile['employeeId']?.toString() ?? '';
    if (facultyId.isNotEmpty) {
      final data = await WorkloadService.fetchFacultyTimetable(facultyId);
      if (mounted) {
        setState(() {
          _timetableData = data;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final facultyId = repo.profile['employeeId']?.toString() ?? '';
    final timetableData = _timetableData.isNotEmpty
        ? _timetableData
        : TimetableService.getByFaculty(facultyId);

    // Compute workload metrics directly from timetable
    int theoryPeriods = 0;
    int labPeriods = 0;

    final Map<String, Map<String, dynamic>> subjectBreakdown = {};

    for (final dayItem in timetableData) {
      final schedule = (dayItem['schedule'] as List? ?? []);
      for (final period in schedule) {
        final subject = period['subject']?.toString() ?? '';
        final code = period['code']?.toString() ?? '';
        final classSec = period['classSec']?.toString() ?? '';
        final type = period['type']?.toString() ?? 'Lecture';

        final isLab = type.toLowerCase().contains('lab');
        if (isLab) {
          labPeriods++;
        } else {
          theoryPeriods++;
        }

        if (subject.isNotEmpty) {
          if (!subjectBreakdown.containsKey(subject)) {
            // Determine year dynamically from classSec
            String year = StudentService.extractYear(classSec);
            if (year.isEmpty) {
              final cSecUpper = classSec.toUpperCase();
              if (cSecUpper.contains('II YEAR') ||
                  cSecUpper.contains(' 2ND') ||
                  cSecUpper.contains('II -')) {
                year = 'II Year';
              } else if (cSecUpper.contains('III YEAR') ||
                  cSecUpper.contains(' 3RD') ||
                  cSecUpper.contains('III -')) {
                year = 'III Year';
              } else if (cSecUpper.contains('IV YEAR') ||
                  cSecUpper.contains(' 4TH') ||
                  cSecUpper.contains('IV -')) {
                year = 'IV Year';
              } else {
                year = 'I Year';
              }
            }

            // Determine semester dynamically from year / classSec
            String semester = 'Semester I';
            if (year.contains('II')) {
              semester = 'Semester IV';
            } else if (year.contains('III')) {
              semester = 'Semester VI';
            } else if (year.contains('IV')) {
              semester = 'Semester VIII';
            } else if (year.contains('I')) {
              semester = 'Semester II';
            }

            subjectBreakdown[subject] = {
              'subject': subject,
              'code': code,
              'year': year,
              'classSec': classSec,
              'semester': semester,
              'type': isLab ? 'Lab' : 'Theory',
              'theory': 0,
              'lab': 0,
            };
          }
          if (isLab) {
            subjectBreakdown[subject]!['lab'] =
                (subjectBreakdown[subject]!['lab'] as int) + 1;
          } else {
            subjectBreakdown[subject]!['theory'] =
                (subjectBreakdown[subject]!['theory'] as int) + 1;
          }
        }
      }
    }

    final totalPeriods = theoryPeriods + labPeriods;
    final totalSubjects = subjectBreakdown.length;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.isLoadingData && repo.timetable.isEmpty) {
          return const FacultyLoadingWidget();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _statCards(theoryPeriods, labPeriods, totalPeriods, totalSubjects),
            const SizedBox(height: 20),
            _subjectBreakdownCard(subjectBreakdown.values.toList()),
            const SizedBox(height: 20),
            _responsibilitiesCard(),
            const SizedBox(height: 20),
            _weeklyGridCard(timetableData),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _pageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        final yearBadge = _badge('Academic Year ${repo.selectedAcademicYear}');

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Faculty Workload',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              yearBadge,
            ],
          );
        }

        return Row(
          children: [
            Text(
              'Faculty Workload',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            yearBadge,
          ],
        );
      },
    );
  }

  Widget _statCards(int theory, int lab, int total, int subjects) {
    final cards = [
      {
        'label': 'Total Teaching Hours',
        'value': '$total hrs/wk',
        'icon': Icons.timer_outlined,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'label': 'Theory Hours',
        'value': '$theory hrs/wk',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
      },
      {
        'label': 'Lab / Practical Hours',
        'value': '$lab hrs/wk',
        'icon': Icons.science_outlined,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFECFDF5),
      },
      {
        'label': 'Total Subjects in Timetable',
        'value': '$subjects Subjects',
        'icon': Icons.auto_stories_outlined,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFFFBEB),
      },
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final perRow = constraints.maxWidth < 650 ? 2 : 4;
        final w = (constraints.maxWidth - (perRow - 1) * 16) / perRow;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards.map((c) {
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: c['bg'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        c['icon'] as IconData,
                        color: c['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c['value'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            c['label'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _subjectBreakdownCard(List<Map<String, dynamic>> list) {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Assigned Course / Subject Breakdown',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _badge('${list.length} Subjects'),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, 850.0);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _th('Course Code')),
                            Expanded(flex: 4, child: _th('Subject Name')),
                            Expanded(flex: 2, child: _th('Year')),
                            Expanded(flex: 3, child: _th('Class / Section')),
                            Expanded(flex: 2, child: _th('Semester')),
                            Expanded(flex: 2, child: _th('Type')),
                            Expanded(flex: 2, child: _th('Weekly Hours')),
                          ],
                        ),
                      ),
                      if (list.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Text(
                            'No courses assigned',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...list.map((item) {
                          final t = item['theory'] as int;
                          final l = item['lab'] as int;
                          final tot = t + l;
                          final isLab = l > 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFF1F5F9)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    (item['code'] ?? '').toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    (item['subject'] ?? '').toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (item['year'] ?? 'I Year').toString(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    (item['classSec'] ?? '').toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    (item['semester'] ?? '').toString(),
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLab
                                          ? const Color(0xFFECFDF5)
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isLab ? 'Lab' : 'Theory',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isLab
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '$tot hrs/wk',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _responsibilitiesCard() {
    final List responsibilities =
        (repo.profile['responsibilities'] as List? ??
        repo.profile['institutional_responsibilities'] as List? ??
        []);

    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Other Assigned Institutional Responsibilities',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          if (responsibilities.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 32,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Not Assigned',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No additional institutional responsibilities assigned.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: responsibilities.map((r) {
                final Map<String, dynamic> item = r is Map<String, dynamic>
                    ? r
                    : Map<String, dynamic>.from(r as Map);
                final role = item['role']?.toString() ?? 'Responsibility';
                final type = item['type']?.toString() ?? 'Institutional';
                final details = item['details']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (details.isNotEmpty)
                              Text(
                                details,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _weeklyGridCard(List<Map<String, dynamic>> timetableData) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Teaching Timetable Allocation',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = math.max(constraints.maxWidth, 850.0);

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    children: days.map((dayName) {
                      final dayMatch =
                          timetableData
                              .where(
                                (d) => (d['day']?.toString() ?? '') == dayName,
                              )
                              .firstOrNull ??
                          <String, dynamic>{'schedule': []};
                      final schedule = (dayMatch['schedule'] as List? ?? []);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                dayName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Expanded(
                              child: schedule.isEmpty
                                  ? Text(
                                      'No lectures assigned',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF94A3B8),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: schedule.map((p) {
                                        final periodStr =
                                            p['period']?.toString() ?? '';
                                        final subjStr =
                                            p['subject']?.toString() ?? '';
                                        final roomStr =
                                            p['room']?.toString() ?? '';
                                        final isLab =
                                            (p['type']?.toString() ?? '')
                                                .toLowerCase()
                                                .contains('lab');

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLab
                                                ? const Color(0xFFECFDF5)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: isLab
                                                  ? const Color(0xFFA7F3D0)
                                                  : const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    periodStr,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isLab
                                                          ? const Color(
                                                              0xFF059669,
                                                            )
                                                          : const Color(
                                                              0xFF2563EB,
                                                            ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    roomStr,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: const Color(
                                                        0xFF64748B,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                subjStr,
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xFF2563EB),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _th(String t) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF64748B),
    ),
  );

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
