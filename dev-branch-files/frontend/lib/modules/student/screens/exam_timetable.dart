// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';
import '../widgets/academic_year_dropdown.dart';

class ExamTimetableScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const ExamTimetableScreen({super.key, this.onNavigate});

  @override
  State<ExamTimetableScreen> createState() => _ExamTimetableScreenState();
}

class _ExamTimetableScreenState extends State<ExamTimetableScreen> {
  String _searchQuery = '';
  String _selectedViewMode = 'Cards View';
  String _selectedSem = '';
  String _filterType = 'All Types';
  String _sortBy = 'Date (Ascending)';

  List<Map<String, dynamic>> _getExamsFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      if (!appState.isCurrentAcademicYear) return [];
      final rawExams = appState.examSchedules;

      if (_selectedSem.isEmpty) return [];

      final semVal = _selectedSem;
      final semNumeric = semVal == 'I' ? '1' : (semVal == 'II' ? '2' : (semVal == 'III' ? '3' : (semVal == 'IV' ? '4' : (semVal == 'V' ? '5' : (semVal == 'VI' ? '6' : (semVal == 'VII' ? '7' : (semVal == 'VIII' ? '8' : semVal)))))));
      final studentDept = appState.getProfileField('department', defaultValue: 'CSE').toString().trim().toUpperCase();

      // Filter strictly by semester and department
      final matched = rawExams.where((e) {
        final deptMap = e['departments'];
        final deptCode = (deptMap is Map ? deptMap['code'] : '').toString().trim().toUpperCase();
        if (deptCode.isNotEmpty && deptCode != studentDept) {
          return false;
        }

        final semStr = (e['semester'] ?? '').toString();
        final matchesSem = semStr.toLowerCase().contains('semester $semNumeric') ||
            semStr.toLowerCase().contains(semVal.toLowerCase()) ||
            semStr == semNumeric;
        return matchesSem;
      }).toList();

      if (matched.isEmpty) {
        return [];
      }

      final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();

      final List<Map<String, dynamic>> list = [];
      for (var e in matched) {
        DateTime dt = DateTime.now();
        if (e['exam_date'] != null) {
          try {
            dt = DateTime.parse(e['exam_date'].toString());
          } catch (_) {}
        }

        final session = (e['session'] ?? '').toString().toUpperCase();
        String timeStr = (e['start_time'] ?? e['time'] ?? '').toString();
        if (timeStr.isEmpty) {
          timeStr = session == 'FN' ? '09:30 AM - 12:30 PM' : (session == 'AN' ? '01:30 PM - 04:30 PM' : session);
        }

        final isPast = dt.isBefore(DateTime(now.year, now.month, now.day));
        final stageStr = (e['stage'] ?? '').toString().toLowerCase();
        final status = isPast || stageStr == 'completed' ? 'Completed' : 'Upcoming';
        final hall = (e['hall'] ?? e['room'] ?? e['venue'] ?? '').toString().trim();
        String type = (e['exam_type'] ?? e['type'] ?? 'Theory').toString().trim();
        final name = (e['subject_name'] ?? e['name'] ?? '').toString().trim();

        if (type.toLowerCase() == 'theory' && name.toLowerCase().contains('lab')) {
          type = 'Lab';
        }

        list.add({
          'dayNum': dt.day.toString().padLeft(2, '0'),
          'month': months[dt.month - 1],
          'day': daysOfWeek[dt.weekday % 7],
          'time': timeStr,
          'code': (e['subject_code'] ?? e['code'] ?? '').toString().trim(),
          'name': name,
          'room': hall,
          'type': type,
          'status': status,
        });
      }

      // Deduplicate by course code and sort by date
      final seen = <String>{};
      final uniqueList = list.where((item) => seen.add(item['code']!)).toList();
      uniqueList.sort((a, b) => _getExamDate(a).compareTo(_getExamDate(b)));
      return uniqueList;
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _exams {
    final dbList = _getExamsFromDb();
    if (dbList.isNotEmpty) return dbList;
    return [];
  }

  void _downloadTimetable() {
    final examsList = _getFilteredSortedExams();
    final header = '%PDF-1.4\n';
    final body = StringBuffer();
    body.write('BT\n');
    body.write('/F1 16 Tf\n');
    body.write('50 780 Td\n');
    body.write('22 TL\n');
    body.write('(K.S.R. COLLEGE OF ENGINEERING - EXAM TIMETABLE) Tj T*\n');
    body.write('/F1 12 Tf\n');
    body.write('16 TL\n');
    body.write('0 -10 Td\n');
    body.write('(Semester: $_selectedSem Semester) Tj T*\n');
    body.write('() Tj T*\n');
    for (int i = 0; i < examsList.length; i++) {
      final e = examsList[i];
      body.write('(${i + 1}. ${e['code']} - ${e['name']} - ${e['dayNum']} ${e['month']} - ${e['time']} - ${e['room']}) Tj T*\n');
    }
    body.write('ET');

    final streamContent = body.toString();
    final streamLength = streamContent.length;

    final objects = [
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>\nendobj\n',
      '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
      '5 0 obj\n<< /Length $streamLength >>\nstream\n$streamContent\nendstream\nendobj\n'
    ];

    final pdfContent = StringBuffer();
    pdfContent.write(header);
    final offsets = <int>[];
    for (var obj in objects) {
      offsets.add(pdfContent.length);
      pdfContent.write(obj);
    }
    final xrefStart = pdfContent.length;
    pdfContent.write('xref\n0 6\n0000000000 65535 f \n');
    for (var offset in offsets) {
      pdfContent.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
    }
    pdfContent.write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefStart\n%%EOF');

    final bytes = utf8.encode(pdfContent.toString());
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "Exam_Timetable_${_selectedSem}_Sem.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exam Timetable PDF downloaded successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    
    if (_selectedSem.isEmpty && sems.isNotEmpty) {
      _selectedSem = sems.first;
    } else if (_selectedSem.isNotEmpty && sems.isNotEmpty && !sems.contains(_selectedSem)) {
      _selectedSem = sems.first;
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          const SizedBox(height: 24),
          _buildFilterRow(),
          const SizedBox(height: 24),
          isDesktop
              ? _buildTimetableGrid()
              : (_selectedViewMode == 'Cards View' ? _buildMobileCardsView() : _buildTimetableGrid()),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    return Row(
      children: [
        const AcademicYearDropdown(),
        const SizedBox(width: 6),
        if (sems.isNotEmpty)
          _buildPillDropdown<String>(
            icon: Icons.school_outlined,
            prefixText: 'Semester',
            value: _selectedSem.isNotEmpty && sems.contains(_selectedSem) ? _selectedSem : sems.first,
            items: sems,
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _selectedSem = v;
                });
              }
            },
          ),
        if (!isDesktop) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _selectedViewMode = (_selectedViewMode == 'Cards View') ? 'Grid View' : 'Cards View';
              });
            },
            icon: Icon(
              _selectedViewMode == 'Cards View' ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
              size: 14,
              color: const Color(0xFF2563EB),
            ),
            label: Text(
              _selectedViewMode == 'Cards View' ? 'Grid View' : 'Cards View',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              backgroundColor: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPillDropdown<T>({
    required IconData icon,
    required String prefixText,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
          alignment: Alignment.center,
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((T val) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<T>>((T val) {
            return DropdownMenuItem<T>(
              value: val,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: isDesktop ? 450 : 250,
            child: _buildSearchField(
              'Search by subject or code...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _downloadTimetable,
            icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
            label: const Text('Download Timetable (PDF)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52,
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                onChanged: (val) {
                  if (val != null) setState(() => _filterType = val);
                },
                items: ['All Types', 'Theory', 'Lab'].map((t) => DropdownMenuItem(value: t, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Filter Type', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                  ],
                ))).toList(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            height: 52,
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortBy,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8)),
                onChanged: (val) {
                  if (val != null) setState(() => _sortBy = val);
                },
                items: ['Date (Ascending)', 'Date (Descending)', 'Subject Name'].map((t) => DropdownMenuItem(value: t, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sort By', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ))).toList(),
              ),
            ),
          ),
          const SizedBox(width: 14),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filterType = 'All Types';
                _sortBy = 'Date (Ascending)';
              });
            },
            icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF2563EB)),
            label: const Text('Clear Filters', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCardsView() {
    final filtered = _getFilteredSortedExams();
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Center(child: Text('No matching exams found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 14))),
      );
    }

    return Column(
      children: filtered.map((exam) {
        final isCompleted = exam['status'] == 'Completed';
        final room = exam['room'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text('${exam['dayNum']} ${exam['month']} (${exam['day']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      exam['status'] ?? 'Upcoming',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCompleted ? const Color(0xFF166534) : const Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(exam['code'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(height: 2),
              Text(exam['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(exam['time'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  if (room.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(room, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  ],
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getFilteredSortedExams() {
    final filtered = _exams.where((exam) {
      final query = _searchQuery.toLowerCase();
      final matchesName = exam['name'].toString().toLowerCase().contains(query);
      final matchesCode = exam['code'].toString().toLowerCase().contains(query);
      final matchesQuery = matchesName || matchesCode;
      final matchesType = _filterType == 'All Types' || exam['type'] == _filterType;
      return matchesQuery && matchesType;
    }).toList();

    if (_sortBy == 'Date (Ascending)') {
      filtered.sort((a, b) => _getExamDate(a).compareTo(_getExamDate(b)));
    } else if (_sortBy == 'Date (Descending)') {
      filtered.sort((a, b) => _getExamDate(b).compareTo(_getExamDate(a)));
    } else if (_sortBy == 'Subject Name') {
      filtered.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));
    }
    return filtered;
  }

  Widget _buildSearchField(String hint, {IconData? icon, ValueChanged<String>? onChanged}) {
    return Container(
      height: 52,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon ?? Icons.search, size: 20, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  int _getMonthNumber(String monthName) {
    final months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    final key = monthName.toLowerCase();
    if (key.length >= 3) {
      return months[key.substring(0, 3)] ?? 1;
    }
    return 1;
  }

  DateTime _getExamDate(Map<String, dynamic> exam) {
    final day = int.tryParse(exam['dayNum'].toString()) ?? 1;
    final month = _getMonthNumber(exam['month'].toString());
    return DateTime(2026, month, day);
  }

  Widget _buildTimetableGrid() {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final filtered = _getFilteredSortedExams();

    final tableWidget = Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A), 
            borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
          ),
          child: Row(
            children: [
              Expanded(flex: 10, child: _buildTableText('Date', color: Colors.white, isBold: true, center: true)),
              Expanded(flex: 9, child: _buildTableText('Day', color: Colors.white, isBold: true, center: true)),
              Expanded(flex: 20, child: _buildTableText('Time', color: Colors.white, isBold: true, center: true)),
              Expanded(flex: 16, child: _buildTableText('Subject Code', color: Colors.white, isBold: true, center: true)),
              Expanded(flex: 48, child: _buildTableText('Subject Name', color: Colors.white, isBold: true, center: false)),
              Expanded(flex: 20, child: _buildTableText('Venue / Hall', color: Colors.white, isBold: true, center: false)),
              Expanded(flex: 12, child: _buildTableText('Type', color: Colors.white, isBold: true, center: true)),
              Expanded(flex: 18, child: _buildTableText('Status', color: Colors.white, isBold: true, center: true)),
            ],
          ),
        ),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(48),
            child: const Center(
              child: Text(
                'No matching exams found.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          )
        else
          ...List.generate(filtered.length, (idx) {
            final exam = filtered[idx];
            final isLast = idx == filtered.length - 1;
            final isAlt = idx % 2 != 0;
            return Column(
              children: [
                _buildTableRow(
                  exam['dayNum']!,
                  exam['month']!,
                  exam['day']!,
                  exam['time']!,
                  exam['code']!,
                  exam['name']!,
                  exam['room']!,
                  exam['type']!,
                  exam['status']!,
                  isAlt,
                  isLast,
                ),
                if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            );
          }),
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isDesktop
          ? tableWidget
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1000,
                child: tableWidget,
              ),
            ),
    );
  }

  Widget _buildTableText(String text, {bool center = false, Color color = const Color(0xFF475569), bool isBold = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: TextStyle(fontSize: 13, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, height: 1.4),
    );
  }

  Widget _buildTableRow(String dayNum, String month, String day, String time, String code, String subName, String hall, String type, String status, bool isAlt, bool isLast) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isAlt ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(13)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 10, child: Column(children: [Text(dayNum, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))), Text(month, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))]),),
          Expanded(flex: 9, child: Center(child: Text(day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))))),
          Expanded(flex: 20, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.access_time, size: 15, color: Color(0xFF16A34A)), const SizedBox(width: 6), Flexible(child: Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis))])),
          Expanded(flex: 16, child: Center(child: Text(code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))))),
          // Spacious Subject Name Column
          Expanded(flex: 48, child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle), child: const Icon(Icons.menu_book, size: 16, color: Color(0xFF2563EB))),
              const SizedBox(width: 12),
              Expanded(child: Text(subName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]
          )),
          Expanded(flex: 20, child: Row(
            children: [
              if (hall.isNotEmpty) ...[
                const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Expanded(child: Text(hall, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ] else ...[
                const Text('-', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ]
            ]
          )),
          Expanded(flex: 12, child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: type.toLowerCase() == 'theory' ? const Color(0xFFDCFCE7) : const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
              child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: type.toLowerCase() == 'theory' ? const Color(0xFF16A34A) : const Color(0xFF9333EA))),
            ),
          )),
          // Spacious Status Column
          Expanded(flex: 18, child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: status == 'Upcoming' ? const Color(0xFFEFF6FF) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: status == 'Upcoming' ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: status == 'Upcoming' ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: status == 'Upcoming' ? const Color(0xFF1D4ED8) : const Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }
}
