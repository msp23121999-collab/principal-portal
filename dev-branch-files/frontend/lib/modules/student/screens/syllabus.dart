// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/app_state.dart';
import '../widgets/academic_year_dropdown.dart';

class SyllabusScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const SyllabusScreen({super.key, this.onNavigate});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  String _searchQuery = '';
  String _selectedSemester = 'V';
  final String _sortBy = 'Code';
  final bool _isLoading = false;
  final bool _hasError = false;

  List<Map<String, dynamic>> _getCourseDocumentsFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      if (!appState.isCurrentAcademicYear) return [];
      final List<Map<String, dynamic>> list = [];

      for (var m in appState.courseMaterials) {
        final title = (m['material_title'] ?? m['file_name'] ?? 'Course Document').toString();
        final subject = (m['subject_name'] ?? m['course_code'] ?? 'Course').toString();
        final type = (m['material_type'] ?? 'Lecture Notes').toString();
        final date = (m['created_at'] ?? '').toString().split('T')[0];
        final url = (m['file_url'] ?? '').toString();
        final fileName = (m['file_name'] ?? '$title.pdf').toString();
        final fileSize = (m['file_size'] ?? 'PDF').toString();
        final faculty = (m['faculty_employee_id'] ?? 'Faculty Professor').toString();

        list.add({
          'name': title,
          'subject': subject,
          'type': type,
          'date': date.isNotEmpty ? date : 'Recent',
          'fileUrl': url,
          'fileName': fileName,
          'fileSize': fileSize,
          'faculty': faculty,
        });
      }

      for (var s in appState.syllabusList) {
        final name = (s['file_name'] ?? s['subject_name'] ?? 'Syllabus Upload').toString();
        final subject = (s['subject_name'] ?? s['course_code'] ?? 'Syllabus').toString();
        final url = (s['file_url'] ?? '').toString();
        final date = (s['created_at'] ?? '').toString().split('T')[0];
        final faculty = (s['faculty_employee_id'] ?? 'Faculty Professor').toString();

        list.add({
          'name': name,
          'subject': subject,
          'type': 'Syllabus PDF',
          'date': date.isNotEmpty ? date : 'Recent',
          'fileUrl': url,
          'fileName': name,
          'fileSize': (s['file_size'] ?? 'PDF').toString(),
          'faculty': faculty,
        });
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  void _openDocumentUrl(String url, String fileName) {
    if (url.isNotEmpty) {
      try {
        if (url.startsWith('data:') || url.startsWith('http')) {
          final anchor = html.AnchorElement(href: url)
            ..target = '_blank'
            ..download = fileName;
          anchor.click();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloading $fileName...')),
          );
          return;
        }
      } catch (e) {
        debugPrint('Error downloading document: $e');
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Document ($fileName) ready.')),
    );
  }

  List<Map<String, dynamic>> _getSyllabusFromDb() {
    try {
      final appState = AppStateProvider.of(context);
      if (!appState.isCurrentAcademicYear) return [];
      final dbSyllabus = appState.syllabusList;

      if (dbSyllabus.isEmpty) {
        return [];
      }

      final List<Map<String, dynamic>> list = [];
      for (var s in dbSyllabus) {
        final code = s['course_code'] ?? 'SUB';
        final name = s['subject_name'] ?? 'Syllabus Course';
        final url = s['file_url'] ?? '';
        final faculty = s['faculty_employee_id'] ?? 'Faculty Professor';

        list.add({
          'code': code,
          'name': name,
          'credits': 4,
          'faculty': faculty,
          'semester': 'V Semester',
          'batch': '2024-2028',
          'degree': 'B.E.',
          'department': 'CSE',
          'academicYear': '2024-2025',
          'fileUrl': url,
          'units': [
            {'title': 'Syllabus Details', 'desc': 'Download and view the uploaded syllabus PDF: $url'},
          ],
          'co': ['Refer to the uploaded syllabus file.'],
          'lo': ['Refer to the uploaded syllabus file.'],
          'references': ['Refer to the uploaded syllabus file.'],
        });
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get _syllabusList {
    final dbList = _getSyllabusFromDb();
    if (dbList.isNotEmpty) return dbList;
    return [];
  }

  Widget _buildPillDropdown<T>({
    required IconData icon,
    required String prefixText,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF2563EB)),
          style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<T>>((T val) {
            return DropdownMenuItem<T>(
              value: val,
              child: Row(
                children: [
                  Icon(icon, size: 16, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text('$prefixText: $val', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Feedback State
  String _feedbackSubject = '';
  String _feedbackFaculty = '';
  double _feedbackRating = 5.0;
  final _feedbackController = TextEditingController();
  final List<Map<String, dynamic>> _feedbackHistory = [
    
  ];

  final List<Map<String, dynamic>> _allSubjects = [];
  final List<Map<String, dynamic>> _courseDocuments = [];
  final List<Map<String, dynamic>> _courseVideos = [];
  final List<Map<String, dynamic>> _facultyDocuments = [];
  final List<Map<String, dynamic>> _facultyVideos = [];

  void _showSubjectDetail(Map<String, dynamic> subject) {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 3,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.menu_book, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subject['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,
              height: 450,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF1D4ED8),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF1D4ED8),
                    tabs: [
                      Tab(text: 'Syllabus'),
                      Tab(text: 'Outcomes'),
                      Tab(text: 'References'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          itemCount: subject['units'].length,
                          itemBuilder: (context, idx) {
                            final unit = subject['units'][idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(unit['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                  const SizedBox(height: 4),
                                  Text(unit['desc'], style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
                                ],
                              ),
                            );
                          },
                        ),
                        ListView(
                          children: [
                            const Text('Course Outcomes (CO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            ...List.generate(subject['co'].length, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(subject['co'][index], style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            )),
                            const Divider(height: 24),
                            const Text('Learning Outcomes (LO)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            ...List.generate(subject['lo'].length, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(subject['lo'][index], style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                            )),
                          ],
                        ),
                        ListView(
                          children: [
                            const Text('Reference Books', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 12),
                            ...List.generate(subject['references'].length, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.book, size: 16, color: Color(0xFF64748B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(subject['references'][index], style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4)),
                                  ),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitFeedback() {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback comments cannot be empty!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() {
      _feedbackHistory.insert(0, {
        'subject': _feedbackSubject,
        'faculty': _feedbackFaculty,
        'semester': 'V Semester',
        'status': 'Submitted',
        'date': '20-07-2026',
        'rating': _feedbackRating,
        'comments': _feedbackController.text.trim()
      });
      _feedbackController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 4.0, right: 8.0, top: 24.0, bottom: 8.0),
              child: Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Color(0xFF1D4ED8),
                    unselectedLabelColor: Color(0xFF64748B),
                    indicatorColor: Color(0xFF1D4ED8),
                    tabs: [
                      Tab(text: 'Syllabus', icon: Icon(Icons.menu_book_outlined, size: 18)),
                      Tab(text: 'Course Docs', icon: Icon(Icons.folder_open_outlined, size: 18)),
                      Tab(text: 'Course Videos', icon: Icon(Icons.video_library_outlined, size: 18)),
                      Tab(text: 'Faculty Docs', icon: Icon(Icons.folder_shared_outlined, size: 18)),
                      Tab(text: 'Faculty Videos', icon: Icon(Icons.video_camera_back_outlined, size: 18)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildSyllabusTab(),
                  _buildCourseDocsTab(),
                  _buildCourseVideosTab(),
                  _buildFacultyDocsTab(),
                  _buildFacultyVideosTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyllabusTab() {
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    if (!sems.contains(_selectedSemester)) {
      _selectedSemester = sems.first;
    }

    final filtered = _syllabusList.where((s) {
      final matchesSearch = s['name'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            s['code'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSemester = s['semester'].toString().startsWith(_selectedSemester);
      return matchesSearch && matchesSemester;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 700;

    final searchInput = TextField(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Search subject...',
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );

    final dropdownsRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const AcademicYearDropdown(),
          const SizedBox(width: 8),
          _buildPillDropdown<String>(
            icon: Icons.school_outlined,
            prefixText: 'SEMESTER',
            value: _selectedSemester,
            items: sems,
            onChanged: (v) => setState(() => _selectedSemester = v!),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchInput,
                    const SizedBox(height: 12),
                    dropdownsRow,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: searchInput),
                    const SizedBox(width: 16),
                    dropdownsRow,
                  ],
                ),
          const SizedBox(height: 24),
          ...filtered.map((s) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s['code'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                          Text('${s['credits']} Credits', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Faculty: ${s['faculty']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _showSubjectDetail(s),
                        child: const Text('View Syllabus details'),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCourseDocsTab() {
    final docs = _getCourseDocumentsFromDb();
    if (docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No course documents found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: docs.length,
      itemBuilder: (context, idx) {
        final doc = docs[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 36),
            title: Text(doc['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${doc['subject']} • Type: ${doc['type']} • ${doc['fileSize']} • Uploaded: ${doc['date']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => _openDocumentUrl(doc['fileUrl'] ?? '', doc['fileName'] ?? 'document.pdf'),
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF16A34A)),
                  onPressed: () => _openDocumentUrl(doc['fileUrl'] ?? '', doc['fileName'] ?? 'document.pdf'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseVideosTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _courseVideos.length,
      itemBuilder: (context, idx) {
        final video = _courseVideos[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(video['subject']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                    Text(video['duration']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(video['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(video['desc']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Video'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacultyDocsTab() {
    final docs = _getCourseDocumentsFromDb();
    if (docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No faculty documents found.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: docs.length,
      itemBuilder: (context, idx) {
        final doc = docs[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.blueAccent, size: 36),
            title: Text(doc['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('Faculty: ${doc['faculty']} • ${doc['subject']} • Type: ${doc['type']} • Uploaded: ${doc['date']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF2563EB)),
                  onPressed: () => _openDocumentUrl(doc['fileUrl'] ?? '', doc['fileName'] ?? 'document.pdf'),
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Color(0xFF16A34A)),
                  onPressed: () => _openDocumentUrl(doc['fileUrl'] ?? '', doc['fileName'] ?? 'document.pdf'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFacultyVideosTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _facultyVideos.length,
      itemBuilder: (context, idx) {
        final video = _facultyVideos[idx];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Faculty: ${video['faculty']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    Text(video['duration']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(video['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(video['subject']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Lecture'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackTab() {
    final appState = AppStateProvider.of(context);
    final dbSubjects = _getSyllabusFromDb();
    final List<Map<String, String>> availableSubjects = [];

    for (var s in dbSubjects) {
      availableSubjects.add({
        'subject': '${s['code']} - ${s['name']}',
        'faculty': s['faculty']?.toString() ?? '',
      });
    }

    if (availableSubjects.isEmpty) {
      for (var t in appState.timetables) {
        final code = (t['subject_code'] ?? t['code'] ?? '').toString();
        final name = (t['subject_name'] ?? t['name'] ?? '').toString();
        final faculty = (t['staff_name'] ?? t['faculty'] ?? '').toString();
        if (code.isNotEmpty || name.isNotEmpty) {
          availableSubjects.add({
            'subject': code.isNotEmpty ? '$code - $name' : name,
            'faculty': faculty,
          });
        }
      }
    }

    final dropdownItems = availableSubjects.map((e) => e['subject']!).toList();
    if (dropdownItems.isNotEmpty && _feedbackSubject.isEmpty) {
      _feedbackSubject = dropdownItems.first;
      _feedbackFaculty = availableSubjects.first['faculty']!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit Feedback / Audit Forms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Subject & Faculty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                if (dropdownItems.isNotEmpty)
                  DropdownButton<String>(
                    value: dropdownItems.contains(_feedbackSubject) ? _feedbackSubject : dropdownItems.first,
                    isExpanded: true,
                    items: dropdownItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        final found = availableSubjects.firstWhere((element) => element['subject'] == v, orElse: () => {'subject': v, 'faculty': ''});
                        setState(() {
                          _feedbackSubject = v;
                          _feedbackFaculty = found['faculty'] ?? '';
                        });
                      }
                    },
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'No subjects available in database for feedback.',
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Faculty: ${_feedbackFaculty.isNotEmpty ? _feedbackFaculty : "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 16),
                const Text('Rating (1 to 5 Stars)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                Slider(
                  value: _feedbackRating,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  label: _feedbackRating.toString(),
                  onChanged: (val) => setState(() => _feedbackRating = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter your feedback comments...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitFeedback,
                  child: const Text('Submit Feedback / Academic Audit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Submission History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (_feedbackHistory.isNotEmpty)
            ..._feedbackHistory.map((item) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  child: ListTile(
                    title: Text(item['subject'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Faculty: ${item['faculty']} • Rating: ${item['rating']} Stars • Comments: "${item['comments']}"'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: item['status'] == 'Approved' ? Colors.green.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(item['status'] ?? 'Submitted', style: TextStyle(fontWeight: FontWeight.bold, color: item['status'] == 'Approved' ? Colors.green : Colors.blue, fontSize: 11)),
                    ),
                  ),
                ))
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'No feedback submissions yet.',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
