import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/timetable_service.dart';
import '../services/syllabus_service.dart';
import '../services/local_storage_base.dart';

/// Course Materials View (Faculty Portal — Index 6)
///
/// Single unified module for uploading and managing Course Materials
/// (Lecture Notes, Syllabus, Question Bank, Lab Manuals, Assignment Notes, Reference Materials).
class SyllabusUploadView extends StatefulWidget {
  const SyllabusUploadView({super.key});

  @override
  State<SyllabusUploadView> createState() => _SyllabusUploadViewState();
}

class _SyllabusUploadViewState extends State<SyllabusUploadView> {
  final repo = ErpRepository();

  String _search = '';
  final _searchCtrl = TextEditingController();

  static const _materialTypes = [
    'Lecture Notes',
    'Syllabus',
    'Question Bank',
    'Lab Manual',
    'Assignment Notes',
    'Reference Material',
    'Other Course Material',
  ];

  // Upload Modal Form Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _uploadType = 'Lecture Notes';
  String _uploadSubject = '';
  String _uploadClassSec = '';

  String? _selectedFileName;
  int _selectedFileSize = 0;
  String? _selectedFileDataUrl;

  // Filters
  String _filterMaterialType = 'Material Type';
  String _filterSubject = 'Subject';
  String _filterClassSection = 'Class & Section';

  String get _facultyId => repo.profile['employeeId']?.toString() ?? 'FAC002';

  @override
  void initState() {
    super.initState();
    _loadFromSupabase();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromSupabase() async {
    final list = await SyllabusService.fetchFromSupabase(facultyId: _facultyId);
    if (mounted) {
      setState(() {
        repo.syllabusUploads = list;
      });
    }
  }

  List<String> get _facultySubjects {
    final list = TimetableService.getSubjectsForFaculty(_facultyId);
    if (list.isEmpty)
      return [
        'Database Management Systems',
        'Theory of Computation',
        'Computer Networks',
        'Principles of Compiler Design',
      ];
    return list;
  }

  List<String> get _facultyClasses {
    final list = TimetableService.getClassesForFaculty(_facultyId);
    if (list.isEmpty)
      return [
        'CSE - A (II Year)',
        'CSE - B (II Year)',
        'IT - A (III Year)',
        'CSE - B (III Year)',
      ];
    return list;
  }

  // 3. Database Course Allocation & Regulation Year Derived Helper
  String _deriveYearForSubject(String subjectName) {
    for (final day in repo.timetable) {
      final schedule = day['schedule'] as List? ?? [];
      for (final period in schedule) {
        if (period['subject'] == subjectName ||
            period['subject_name'] == subjectName) {
          final cls =
              period['classSec']?.toString() ??
              period['section']?.toString() ??
              '';
          if (cls.contains('III') || cls.contains('3')) return 'III Year';
          if (cls.contains('IV') || cls.contains('4')) return 'IV Year';
          if (cls.contains('I') || cls.contains('1')) return 'I Year';
          if (cls.isNotEmpty) return 'II Year';
        }
      }
    }
    if (subjectName.contains('Compiler') || subjectName.contains('Networks'))
      return 'III Year';
    return 'II Year';
  }

  String _deriveClassSecForSubject(String subjectName) {
    for (final day in repo.timetable) {
      final schedule = day['schedule'] as List? ?? [];
      for (final period in schedule) {
        if (period['subject'] == subjectName ||
            period['subject_name'] == subjectName) {
          final cls =
              period['classSec']?.toString() ?? period['section']?.toString();
          if (cls != null && cls.isNotEmpty) return cls;
        }
      }
    }
    final year = _deriveYearForSubject(subjectName);
    return 'CSE - A ($year)';
  }

  List<Map<String, dynamic>> get _filtered {
    var list = repo.syllabusUploads;

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((f) {
        final title = (f['title'] as String? ?? '').toLowerCase();
        final name = (f['fileName'] as String? ?? '').toLowerCase();
        final subj = (f['subject'] as String? ?? '').toLowerCase();
        return title.contains(q) || name.contains(q) || subj.contains(q);
      }).toList();
    }

    if (_filterMaterialType != 'Material Type') {
      list = list
          .where((f) => (f['type']?.toString() ?? '') == _filterMaterialType)
          .toList();
    }

    if (_filterSubject != 'Subject') {
      list = list
          .where((f) => (f['subject']?.toString() ?? '') == _filterSubject)
          .toList();
    }

    if (_filterClassSection != 'Class & Section') {
      list = list
          .where(
            (f) => (f['classSection'] ?? f['classSec'] ?? f['section'] ?? '')
                .toString()
                .contains(_filterClassSection),
          )
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.isLoadingData && repo.syllabusUploads.isEmpty) {
          return const FacultyLoadingWidget();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _mainContentSection(),
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
        final yearBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Text(
            'Academic Year ${repo.selectedAcademicYear}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2563EB),
            ),
          ),
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Materials',
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
              'Course Materials',
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

  Widget _mainContentSection() {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action & Filter Toolbar
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showUploadModal,
                icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                label: Text(
                  'Add Course Material',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Search field
              Container(
                height: 40,
                width: 200,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _search = val),
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search materials...',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),

              // Material Type Filter
              _smallDrop(
                ['Material Type', ..._materialTypes],
                _filterMaterialType,
                (v) {
                  if (v != null) setState(() => _filterMaterialType = v);
                },
              ),

              // Subject Filter
              _smallDrop(['Subject', ..._facultySubjects], _filterSubject, (v) {
                if (v != null) setState(() => _filterSubject = v);
              }),

              // Class Section Filter
              _smallDrop(
                ['Class & Section', ..._facultyClasses],
                _filterClassSection,
                (v) {
                  if (v != null) setState(() => _filterClassSection = v);
                },
              ),

              // Refresh Button
              OutlinedButton.icon(
                onPressed: _loadFromSupabase,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'Refresh',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Reset Button
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _search = '';
                  _searchCtrl.clear();
                  _filterMaterialType = 'Material Type';
                  _filterSubject = 'Subject';
                  _filterClassSection = 'Class & Section';
                }),
                icon: const Icon(Icons.restart_alt, size: 15),
                label: Text('Reset', style: GoogleFonts.inter(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Materials Table
          LayoutBuilder(
            builder: (context, constraints) {
              final tableW = math.max(constraints.maxWidth, 1050.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableW,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: _th('Material Title & File'),
                            ),
                            Expanded(flex: 2, child: _th('Type')),
                            Expanded(flex: 3, child: _th('Subject')),
                            Expanded(flex: 3, child: _th('Class / Section')),
                            Expanded(flex: 2, child: _th('Uploaded On')),
                            Expanded(
                              flex: 2,
                              child: _th('Actions', align: TextAlign.center),
                            ),
                          ],
                        ),
                      ),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 48,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No course materials found',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Click "Add Course Material" to upload notes, PPTs, syllabus or lab manuals.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._filtered.map((doc) => _docTableRow(doc)),
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

  Widget _docTableRow(Map<String, dynamic> doc) {
    final name = doc['fileName']?.toString() ?? '';
    final title = doc['title']?.toString() ?? name;
    final type = doc['type']?.toString() ?? 'Lecture Notes';
    final classSection =
        doc['classSection']?.toString() ??
        doc['classSec']?.toString() ??
        doc['section']?.toString() ??
        '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Material Title & File (flex: 4)
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _typeColors(type)['bg'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _typeIcon(type),
                    size: 18,
                    color: _typeColors(type)['fg'] as Color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Type Badge (flex: 2)
          Expanded(flex: 2, child: _typeBadge(type)),

          // Subject (flex: 3)
          Expanded(
            flex: 3,
            child: Text(
              doc['subject']?.toString() ?? '—',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Class / Section (flex: 3)
          Expanded(
            flex: 3,
            child: Text(
              classSection,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Uploaded On (flex: 2)
          Expanded(
            flex: 2,
            child: Text(
              doc['uploadedOn']?.toString() ?? '—',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF475569),
              ),
            ),
          ),

          // Actions (flex: 2)
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                  tooltip: 'View Details',
                  onPressed: () => _viewMaterialContent(doc),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.file_download_outlined,
                    size: 18,
                    color: Color(0xFF16A34A),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                  tooltip: 'Download',
                  onPressed: () {
                    final url =
                        (doc['fileUrl'] ??
                                doc['file_url'] ??
                                doc['fileData'] ??
                                '')
                            .toString();
                    final n =
                        (doc['fileName'] ??
                                doc['file_name'] ??
                                doc['title'] ??
                                'Course_Material.pdf')
                            .toString();
                    repo.triggerFileDownload(n, url, 'application/pdf');
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 32,
                  ),
                  tooltip: 'Delete Material',
                  onPressed: () => _confirmDeleteMaterial(doc),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Inline Form Validations below inputs
  // 2. Real Functional File Upload
  // 3. Dynamic Subject -> Year & Class/Section Mapping from Database
  void _showUploadModal() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _selectedFileName = null;
    _selectedFileSize = 0;
    _selectedFileDataUrl = null;
    _uploadType = 'Lecture Notes';

    String? titleErrorText;
    String? descErrorText;
    String? fileErrorText;

    final subjects = _facultySubjects;
    if (subjects.isNotEmpty) {
      _uploadSubject = subjects.first;
      _uploadClassSec = _deriveClassSecForSubject(_uploadSubject);
    }

    final classes = _facultyClasses;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 550,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Add Course Material',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      'Upload teaching resources for your assigned subjects.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Material Type Dropdown
                    Text(
                      'Material Type *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _modalDropdown(
                      _materialTypes,
                      _uploadType,
                      (v) => setModalState(() => _uploadType = v!),
                    ),
                    const SizedBox(height: 14),

                    // Material Title * (1. Inline Error Validation below input)
                    Text(
                      'Material Title *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. DBMS Unit I Lecture Notes',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                        errorText:
                            titleErrorText, // 1. Inline error text directly below input
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) {
                        if (titleErrorText != null) {
                          setModalState(() => titleErrorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Description (Optional) (1. Inline Error Validation)
                    Text(
                      'Description (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Brief summary of material contents',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                        errorText:
                            descErrorText, // 1. Inline error text directly below input
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) {
                        if (descErrorText != null) {
                          setModalState(() => descErrorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // 3. Target Subject Dropdown with Dynamic Year Update from Database
                    Text(
                      'Target Subject *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _modalDropdown(subjects, _uploadSubject, (v) {
                      if (v == null) return;
                      setModalState(() {
                        _uploadSubject = v;
                        _uploadClassSec = _deriveClassSecForSubject(
                          _uploadSubject,
                        );
                      });
                    }),
                    const SizedBox(height: 14),

                    // Class / Section Dropdown
                    Text(
                      'Class / Section *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _modalDropdown(
                      classes,
                      _uploadClassSec,
                      (v) => setModalState(() => _uploadClassSec = v!),
                    ),
                    const SizedBox(height: 14),

                    // 2. Real Functional File Upload with Max 50 MB Validation
                    Text(
                      'Document File *',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () {
                        // 2. Real native web/desktop functional file upload
                        repo.triggerNativeUpload((name, size, dataUrl) {
                          setModalState(() {
                            // 50 MB = 50 * 1024 * 1024 = 52,428,800 bytes
                            if (size > 50 * 1024 * 1024) {
                              fileErrorText =
                                  'File size exceeds maximum limit of 50 MB';
                              _selectedFileName = null;
                              _selectedFileSize = size;
                            } else {
                              fileErrorText = null;
                              _selectedFileName = name;
                              _selectedFileSize = size;
                              _selectedFileDataUrl = dataUrl;
                            }
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: fileErrorText != null
                                ? Colors.red
                                : (_selectedFileName != null
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFCBD5E1)),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                _selectedFileName != null
                                    ? Icons.check_circle_outline
                                    : Icons.cloud_upload_outlined,
                                size: 32,
                                color: _selectedFileName != null
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFF2563EB),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedFileName ??
                                    'Click to select document file',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedFileName != null
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                              if (_selectedFileSize > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Size: ${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Supported: PDF, DOCX, PPTX, ZIP (Max 50 MB)',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 1. Inline error message for File Upload directly below input
                    if (fileErrorText != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        fileErrorText!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final title = _titleCtrl.text.trim();
                            final desc = _descCtrl.text.trim();

                            bool hasError = false;

                            // 1. Inline Title Validation directly below input
                            if (title.isEmpty ||
                                !RegExp(r'[a-zA-Z]').hasMatch(title)) {
                              setModalState(() {
                                titleErrorText =
                                    'Material Title is required and must contain valid letters.';
                              });
                              hasError = true;
                            }

                            // 1. Inline Description Validation directly below input
                            if (desc.isNotEmpty &&
                                !RegExp(r'[a-zA-Z]').hasMatch(desc)) {
                              setModalState(() {
                                descErrorText =
                                    'Description must contain valid letters.';
                              });
                              hasError = true;
                            }

                            // 1. Inline File Validation directly below input
                            if (_selectedFileName == null &&
                                _selectedFileSize == 0) {
                              setModalState(() {
                                fileErrorText =
                                    'Please select a document file to upload.';
                              });
                              hasError = true;
                            } else if (_selectedFileSize > 50 * 1024 * 1024) {
                              setModalState(() {
                                fileErrorText =
                                    'File size exceeds maximum limit of 50 MB.';
                              });
                              hasError = true;
                            }

                            if (hasError) return;

                            final fileName =
                                _selectedFileName ??
                                '${title.replaceAll(' ', '_')}.pdf';
                            final fileSizeStr = _selectedFileSize > 0
                                ? '${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(1)} MB'
                                : '2.5 MB';
                            final fileUrl =
                                _selectedFileDataUrl ??
                                'https://storage.supabase.co/course_materials/$fileName';

                            final item = <String, dynamic>{
                              'id': LocalStorageBase.generateId('MAT'),
                              'syllabusId': LocalStorageBase.generateId('MAT'),
                              'facultyId': _facultyId,
                              'title': title,
                              'type': _uploadType,
                              'subject': _uploadSubject.isNotEmpty
                                  ? _uploadSubject
                                  : 'Course Subject',
                              'courseCode': _uploadSubject,
                              'classSection': _uploadClassSec.isNotEmpty
                                  ? _uploadClassSec
                                  : 'CSE - A',
                              'description': desc,
                              'fileName': fileName,
                              'fileSize': fileSizeStr,
                              'fileUrl': fileUrl,
                              'fileData': fileUrl,
                              'uploadedOn': DateTime.now().toString().substring(
                                0,
                                10,
                              ),
                              'status': 'Published',
                            };

                            await SyllabusService.save(item);
                            await _loadFromSupabase();

                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          icon: const Icon(Icons.cloud_upload, size: 16),
                          label: Text(
                            'Upload Material',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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

  void _viewMaterialContent(Map<String, dynamic> doc) {
    final title =
        doc['title']?.toString() ??
        doc['fileName']?.toString() ??
        'Course Material';
    final fileName = doc['fileName']?.toString() ?? 'Document.pdf';
    final type = doc['type']?.toString() ?? 'Lecture Notes';
    final subject = doc['subject']?.toString() ?? 'Course Subject';
    final classSec = doc['classSection']?.toString() ?? 'CSE - A';
    final desc = doc['description']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 850,
          height: 650,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFDC2626),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$fileName  •  $subject ($classSec)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _typeBadge(type),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 20),

              // PDF / Document Viewer Toolbar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Document Viewer',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Page 1 of 6',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.zoom_out, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '100%',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.zoom_in, color: Colors.white70, size: 16),
                  ],
                ),
              ),

              // Document View Canvas Container
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Center(
                      child: Container(
                        width: 680,
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Academic Paper Header
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'DEPARTMENT OF COMPUTER SCIENCE AND ENGINEERING',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1E293B),
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$subject — $type',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2563EB),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 2,
                                    width: 120,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Target Audience: $classSec  |  Academic Term 2026-2027',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),

                            if (desc.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overview & Learning Objectives:',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E40AF),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      desc,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            Text(
                              '1. INTRODUCTION & CORE CONCEPTS',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This document provides fundamental reference material for $title in $subject. Students are expected to review the key theoretical definitions, algorithmic principles, and practical application examples outlined in this section.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF334155),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              '2. KEY TOPICS & ARCHITECTURE',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Fundamental Axioms & Mathematical Formulations\n'
                              '• Algorithmic Complexity Analysis & State Transformations\n'
                              '• System Level Integration & Design Specifications\n'
                              '• Practical Laboratory Workflows & Verification Techniques',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF334155),
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Diagram / Technical Illustration Box
                            Container(
                              width: double.infinity,
                              height: 140,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.schema_outlined,
                                    size: 36,
                                    color: Color(0xFF2563EB),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Figure 1: Architectural Workflow Diagram ($subject)',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            Text(
                              '3. SUMMARY & REVIEW QUESTIONS',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete the end-of-chapter assessment problems and review the corresponding lab exercises prior to the next scheduled lecture period.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF334155),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Footer Action Row (ONLY CLOSE BUTTON AS REQUIRED)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF475569),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close Preview',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMaterial(Map<String, dynamic> doc) {
    final id = doc['id']?.toString() ?? doc['syllabusId']?.toString() ?? '';
    final title =
        doc['title']?.toString() ??
        doc['fileName']?.toString() ??
        'Course Material';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Material',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$title"?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await SyllabusService.delete(id);
              await _loadFromSupabase();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modalDropdown(
    List<String> items,
    String currentVal,
    ValueChanged<String?> onChange,
  ) {
    final val = items.contains(currentVal)
        ? currentVal
        : (items.isNotEmpty ? items.first : null);
    return DropdownButtonFormField<String>(
      initialValue: val,
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(i, style: GoogleFonts.inter(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: onChange,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
    );
  }

  Widget _smallDrop(
    List<String> items,
    String val,
    ValueChanged<String?> onChanged,
  ) {
    final uniqueItems = items.toSet().toList();
    final current = uniqueItems.contains(val)
        ? val
        : (uniqueItems.isNotEmpty ? uniqueItems.first : val);

    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      initialValue: current,
      onSelected: onChanged,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == current;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> _typeColors(String type) {
    if (type.contains('Syllabus')) {
      return {'bg': const Color(0xFFEFF6FF), 'fg': const Color(0xFF2563EB)};
    } else if (type.contains('Notes')) {
      return {'bg': const Color(0xFFF5F3FF), 'fg': const Color(0xFF7C3AED)};
    } else if (type.contains('PPT') || type.contains('Presentation')) {
      return {'bg': const Color(0xFFFFF7ED), 'fg': const Color(0xFFF97316)};
    } else if (type.contains('Lab') || type.contains('Manual')) {
      return {'bg': const Color(0xFFECFDF5), 'fg': const Color(0xFF059669)};
    }
    return {'bg': const Color(0xFFF1F5F9), 'fg': const Color(0xFF475569)};
  }

  IconData _typeIcon(String type) {
    if (type.contains('Syllabus')) return Icons.menu_book_outlined;
    if (type.contains('Notes')) return Icons.description_outlined;
    if (type.contains('PPT') || type.contains('Presentation'))
      return Icons.slideshow_outlined;
    if (type.contains('Lab') || type.contains('Manual'))
      return Icons.science_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Widget _typeBadge(String type) {
    final c = _typeColors(type);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c['bg'],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: c['fg'],
          ),
        ),
      ),
    );
  }

  Widget _th(String t, {TextAlign align = TextAlign.left}) => Text(
    t,
    textAlign: align,
    style: GoogleFonts.inter(
      fontSize: 14,
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
