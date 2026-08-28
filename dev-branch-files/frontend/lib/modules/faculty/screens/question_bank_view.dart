// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/faculty_loading.dart';
import '../erp_repository.dart';
import '../services/question_bank_service.dart';
import '../services/timetable_service.dart';

class QuestionBankView extends StatefulWidget {
  const QuestionBankView({super.key});

  @override
  State<QuestionBankView> createState() => _QuestionBankViewState();
}

class _QuestionBankViewState extends State<QuestionBankView> {
  final repo = ErpRepository();
  String _activeUnit = 'All Questions';
  String _activeDifficulty = 'All Difficulties';
  String _activeBloom = 'All Bloom Levels';
  String _activeType = 'All Types';
  String _activeMarks = 'All Marks';
  String _activeStatus = 'All Statuses';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> get _filteredQuestions {
    final list = repo.questionBank;
    final query = _searchQuery.toLowerCase().trim();

    return list.where((q) {
      final unitStr = q['unit']?.toString() ?? 'Unit 1';
      final diffStr = (q['difficulty']?.toString() ?? 'MEDIUM').toUpperCase();
      final bloomStr = q['bloom']?.toString() ?? 'Understand (L2)';
      final typeStr = q['type']?.toString() ?? 'Part B (13 Marks)';
      final marksVal = q['marks']?.toString() ?? '13';
      final statusVal =
          q['status']?.toString() ??
          q['submissionStatus']?.toString() ??
          'Draft';
      final qText = (q['question']?.toString() ?? '').toLowerCase();
      final subjText = (q['subject']?.toString() ?? '').toLowerCase();

      final matchesUnit =
          _activeUnit == 'All Questions' || unitStr == _activeUnit;
      final matchesDifficulty =
          _activeDifficulty == 'All Difficulties' ||
          diffStr == _activeDifficulty.toUpperCase();
      final matchesBloom =
          _activeBloom == 'All Bloom Levels' || bloomStr.contains(_activeBloom);
      final matchesType = _activeType == 'All Types' || typeStr == _activeType;
      final matchesMarks =
          _activeMarks == 'All Marks' ||
          marksVal == _activeMarks.replaceAll('M', '');

      bool matchesStatus = _activeStatus == 'All Statuses';
      if (!matchesStatus) {
        if (_activeStatus == 'Draft') {
          matchesStatus = statusVal == 'Draft';
        } else if (_activeStatus == 'Pending HOD Review') {
          matchesStatus =
              statusVal == 'Pending HOD Review' || statusVal == 'Submitted';
        } else if (_activeStatus == 'Approved by HOD') {
          matchesStatus =
              statusVal == 'Approved by HOD' || statusVal == 'Approved';
        } else if (_activeStatus == 'Rejected by HOD') {
          matchesStatus =
              statusVal == 'Rejected by HOD' || statusVal == 'Rejected';
        }
      }

      final matchesQuery =
          query.isEmpty ||
          qText.contains(query) ||
          subjText.contains(query) ||
          unitStr.toLowerCase().contains(query) ||
          diffStr.toLowerCase().contains(query) ||
          bloomStr.toLowerCase().contains(query) ||
          typeStr.toLowerCase().contains(query) ||
          marksVal.contains(query);

      return matchesUnit &&
          matchesDifficulty &&
          matchesBloom &&
          matchesType &&
          matchesMarks &&
          matchesStatus &&
          matchesQuery;
    }).toList();
  }

  // ── Question Bank Level State ─────────────────────────────────────────────
  String get _currentBankStatus {
    if (repo.questionBank.isEmpty) return 'Draft';
    final statuses = repo.questionBank
        .map((q) => q['status']?.toString() ?? 'Draft')
        .toSet();
    if (statuses.contains('Pending HOD Review') ||
        statuses.contains('Submitted') ||
        statuses.contains('Pending Review'))
      return 'Pending HOD Review';
    if (statuses.contains('Approved by HOD') ||
        (statuses.contains('Approved') && !statuses.contains('Draft')))
      return 'Approved by HOD';
    if (statuses.contains('Rejected by HOD') || statuses.contains('Rejected'))
      return 'Rejected by HOD';
    return 'Draft';
  }

  bool get _isLocked =>
      _currentBankStatus == 'Pending HOD Review' ||
      _currentBankStatus == 'Approved by HOD';

  List<String> get _latestRejectionRemarks {
    final firstRejected =
        repo.questionBank
            .where((q) => (q['status']?.toString() ?? '').contains('Rejected'))
            .firstOrNull ??
        <String, dynamic>{};
    if (firstRejected.isNotEmpty && firstRejected['rejectionRemarks'] != null) {
      return List<String>.from(firstRejected['rejectionRemarks']);
    }
    return [
      'Unit 3 requires additional Part A questions.',
      "Bloom's Taxonomy mapping is incorrect.",
      'Review CO alignment before resubmission.',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final wide = sw > 1050;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        if (repo.isLoadingData && repo.questionBank.isEmpty) {
          return const FacultyLoadingWidget();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) repo.setGlobalPrintContent(_buildQuestionBankHtml());
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(),
            const SizedBox(height: 20),
            _statusNotificationBanner(),
            const SizedBox(height: 20),
            _summaryStatsPanel(),
            const SizedBox(height: 20),
            _heroBanner(),
            const SizedBox(height: 20),
            _unitProgressCard(),
            const SizedBox(height: 20),
            _filterBar(),
            const SizedBox(height: 20),
            wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _questionList()),
                      const SizedBox(width: 20),
                      SizedBox(width: 280, child: _rightPanel()),
                    ],
                  )
                : Column(
                    children: [
                      _questionList(),
                      const SizedBox(height: 16),
                      _rightPanel(),
                    ],
                  ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Page Header ───────────────────────────────────────────────────────────
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
                'Question Bank',
                style: GoogleFonts.inter(
                  fontSize: 20,
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
              'Question Bank',
              style: GoogleFonts.inter(
                fontSize: 22,
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

  // ── Status Banners & Rejection Remarks ────────────────────────────────────
  Widget _statusNotificationBanner() {
    final status = _currentBankStatus;

    if (status == 'Pending HOD Review') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Question Bank submitted successfully. Awaiting HOD review.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'Approved by HOD') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF059669),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your Question Bank has been approved by the HOD.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (status == 'Rejected by HOD') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cancel_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'HOD Review',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const Spacer(),
                _statusChip('Rejected by HOD'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Remarks:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7F1D1D),
              ),
            ),
            const SizedBox(height: 6),
            ..._latestRejectionRemarks.map(
              (remark) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        remark,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7F1D1D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ── Summary Panel ─────────────────────────────────────────────────────────
  Widget _summaryStatsPanel() {
    final total = repo.questionBank.length;
    final easy = repo.questionBank
        .where(
          (q) => (q['difficulty'] ?? '').toString().toUpperCase() == 'EASY',
        )
        .length;
    final med = repo.questionBank
        .where(
          (q) => (q['difficulty'] ?? '').toString().toUpperCase() == 'MEDIUM',
        )
        .length;
    final hard = repo.questionBank
        .where(
          (q) => (q['difficulty'] ?? '').toString().toUpperCase() == 'HARD',
        )
        .length;
    final twoM = repo.questionBank
        .where((q) => q['marks'] == 2 || q['marks'] == '2')
        .length;
    final thirteenM = repo.questionBank
        .where((q) => q['marks'] == 13 || q['marks'] == '13')
        .length;

    final draftCount = repo.qbDraftCount;
    final subCount = repo.qbPendingHodCount;
    final appCount = repo.qbApprovedCount;
    final rejCount = repo.qbRejectedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Summary Overview',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _statusChip(_currentBankStatus),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _statTile(
                'Total',
                '$total',
                const Color(0xFF2563EB),
                const Color(0xFFEFF6FF),
              ),
              _statTile(
                'Easy',
                '$easy',
                const Color(0xFF10B981),
                const Color(0xFFECFDF5),
              ),
              _statTile(
                'Medium',
                '$med',
                const Color(0xFFF59E0B),
                const Color(0xFFFFFBEB),
              ),
              _statTile(
                'Hard',
                '$hard',
                const Color(0xFFEF4444),
                const Color(0xFFFEF2F2),
              ),
              _statTile(
                '2 Marks',
                '$twoM',
                const Color(0xFF8B5CF6),
                const Color(0xFFF5F3FF),
              ),
              _statTile(
                '13 Marks',
                '$thirteenM',
                const Color(0xFF6366F1),
                const Color(0xFFEEF2FF),
              ),
              _statTile(
                'Draft',
                '$draftCount',
                const Color(0xFF64748B),
                const Color(0xFFF8FAFC),
              ),
              _statTile(
                'Pending HOD Review',
                '$subCount',
                const Color(0xFFD97706),
                const Color(0xFFFFF7ED),
              ),
              _statTile(
                'Approved by HOD',
                '$appCount',
                const Color(0xFF059669),
                const Color(0xFFECFDF5),
              ),
              _statTile(
                'Rejected by HOD',
                '$rejCount',
                const Color(0xFFDC2626),
                const Color(0xFFFEF2F2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _selectedSubject = '';

  // ── Hero Banner ───────────────────────────────────────────────────────────
  Widget _heroBanner() {
    final status = _currentBankStatus;
    final isResubmission = status == 'Rejected by HOD';
    final facultyId = repo.profile['employeeId'] ?? 'EMP_CSE_002';
    final assignedSubjects = TimetableService.getSubjectsForFaculty(facultyId);
    final subjectList = assignedSubjects;

    if (subjectList.isNotEmpty && !subjectList.contains(_selectedSubject)) {
      _selectedSubject = subjectList.first;
    }

    final subjectQuestions = repo.questionBank
        .where((q) => (q['subject'] ?? '') == _selectedSubject)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;

          final uniqueSubjects = subjectList.toSet().toList();
          final validSubject = uniqueSubjects.contains(_selectedSubject)
              ? _selectedSubject
              : (uniqueSubjects.isNotEmpty
                    ? uniqueSubjects.first
                    : _selectedSubject);

          final subjectDrop = PopupMenuButton<String>(
            tooltip: '',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 4),
            elevation: 4,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            initialValue: validSubject,
            onSelected: (v) {
              setState(() => _selectedSubject = v);
            },
            itemBuilder: (context) {
              return uniqueSubjects.map((item) {
                final bool isSelected = item == validSubject;
                return PopupMenuItem<String>(
                  value: item,
                  height: 38,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    validSubject,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.bold,
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

          final searchBox = Container(
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search questions...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          );

          final previewBtn = OutlinedButton.icon(
            onPressed: _showFullPreviewDialog,
            icon: const Icon(Icons.visibility_outlined, size: 16),
            label: Text(
              'Preview',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          final addBtn = ElevatedButton.icon(
            onPressed: _isLocked ? null : () => _showAddQuestionDialog(null),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              'Add Question',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLocked
                  ? Colors.grey
                  : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          final submitBtn = ElevatedButton.icon(
            onPressed: _isLocked ? null : _submitToHOD,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(
              isResubmission ? 'Resubmit to HOD' : 'Submit to HOD',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLocked
                  ? Colors.grey
                  : const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question Bank',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            '${subjectQuestions.length} Questions for selected subject.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                subjectDrop,
                const SizedBox(height: 12),
                searchBox,
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [previewBtn, addBtn, submitBtn],
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        subjectDrop,
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${subjectQuestions.length} Questions',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build and submit complete subject question bank to HOD for approval.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: searchBox),
              const SizedBox(width: 8),
              previewBtn,
              const SizedBox(width: 8),
              addBtn,
              const SizedBox(width: 8),
              submitBtn,
            ],
          );
        },
      ),
    );
  }

  // ── Unit Completion Progress Card ──────────────────────────────────────────
  Widget _unitProgressCard() {
    final units = ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5'];
    final Map<String, int> counts = {};
    for (final u in units) {
      counts[u] = repo.questionBank.where((q) => q['unit'] == u).length;
    }
    final targetTotal = 50;
    final currentTotal = repo.questionBank.length;
    final progress = (currentTotal / targetTotal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Unit Completion & Progress',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                'Question Bank Completion: $percentage%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: units.map((u) {
              final cnt = counts[u] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text(
                      u,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$cnt Qs',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
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

  // ── Multi-Filter Bar ─────────────────────────────────────────────────────
  Widget _filterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Wrap(
            spacing: 6,
            children:
                [
                  'All Questions',
                  'Unit 1',
                  'Unit 2',
                  'Unit 3',
                  'Unit 4',
                  'Unit 5',
                ].map((u) {
                  final sel = _activeUnit == u;
                  return ChoiceChip(
                    label: Text(
                      u,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        color: sel ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    selected: sel,
                    selectedColor: const Color(0xFF1E3A8A),
                    backgroundColor: Colors.white,
                    onSelected: (selected) {
                      if (selected) setState(() => _activeUnit = u);
                    },
                    side: BorderSide(
                      color: sel
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(width: 12),
          _dropdown(
            ['All Difficulties', 'Easy', 'Medium', 'Hard'],
            _activeDifficulty,
            (v) => setState(() => _activeDifficulty = v!),
          ),
          const SizedBox(width: 6),
          _dropdown(
            [
              'All Bloom Levels',
              'Remember',
              'Understand',
              'Apply',
              'Analyze',
              'Evaluate',
              'Create',
            ],
            _activeBloom,
            (v) => setState(() => _activeBloom = v!),
          ),
          const SizedBox(width: 6),
          _dropdown(
            [
              'All Types',
              'Part A (2 Marks)',
              'Part B (13 Marks)',
              'Part C (15 Marks)',
            ],
            _activeType,
            (v) => setState(() => _activeType = v!),
          ),
          const SizedBox(width: 6),
          _dropdown(
            ['All Marks', '2M', '13M', '15M'],
            _activeMarks,
            (v) => setState(() => _activeMarks = v!),
          ),
          const SizedBox(width: 6),
          _dropdown(
            [
              'All Statuses',
              'Draft',
              'Pending HOD Review',
              'Approved by HOD',
              'Rejected by HOD',
            ],
            _activeStatus,
            (v) => setState(() => _activeStatus = v!),
          ),
        ],
      ),
    );
  }

  // ── Question Cards List ───────────────────────────────────────────────────
  Widget _questionList() {
    final filtered = _filteredQuestions;
    return Column(
      children: [
        if (repo.isLoadingData)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: _cardDecor(),
            child: const FacultyLoadingWidget(),
          )
        else if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: _cardDecor(),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No questions found matching your filter scope.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try adjusting your search query or filters.',
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
          ...filtered.asMap().entries.map(
            (e) => _questionCard(e.value, e.key + 1),
          ),
      ],
    );
  }

  Widget _questionCard(Map<String, dynamic> q, int index) {
    Color color = const Color(0xFF10B981);
    Color bgColor = const Color(0xFFF0FDF4);
    final diff = (q['difficulty'] ?? 'MEDIUM').toString().toUpperCase();
    if (diff == 'HARD') {
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFFEF2F2);
    } else if (diff == 'MEDIUM') {
      color = const Color(0xFFF59E0B);
      bgColor = const Color(0xFFFFF7ED);
    }

    final status =
        q['status']?.toString() ?? q['submissionStatus']?.toString() ?? 'Draft';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              q['marks'] != null ? '${q['marks']}M' : '—',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _smallBadge(
                      'Q#$index',
                      const Color(0xFFF1F5F9),
                      const Color(0xFF334155),
                    ),
                    const SizedBox(width: 6),
                    _smallBadge(
                      q['unit'] ?? 'Unit 1',
                      const Color(0xFFEFF6FF),
                      const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    _smallBadge(diff, bgColor, color),
                    const SizedBox(width: 6),
                    _smallBadge(
                      q['bloom'] ?? 'Understand (L2)',
                      const Color(0xFFF1F5F9),
                      const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    _smallBadge(
                      q['type'] ?? 'Part B (13 Marks)',
                      const Color(0xFFF3E8FF),
                      const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  q['question'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (q['createdAt'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Created: ${q['createdAt'].toString().substring(0, 10)}  |  Faculty: ${q['facultyName'] ?? repo.profile['name']}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              _circleAction(
                Icons.visibility_outlined,
                const Color(0xFF2563EB),
                const Color(0xFFEFF6FF),
                onTap: () => _showSinglePreviewDialog(q, index),
              ),
              const SizedBox(width: 6),
              if (!_isLocked) ...[
                _circleAction(
                  Icons.copy_outlined,
                  const Color(0xFF059669),
                  const Color(0xFFECFDF5),
                  onTap: () => _duplicateQuestion(q),
                ),
                const SizedBox(width: 6),
                _circleAction(
                  Icons.edit_outlined,
                  const Color(0xFF475569),
                  const Color(0xFFF1F5F9),
                  onTap: () => _showAddQuestionDialog(q),
                ),
                const SizedBox(width: 6),
                _circleAction(
                  Icons.delete_outline,
                  const Color(0xFFDC2626),
                  const Color(0xFFFEF2F2),
                  onTap: () => _deleteQuestion(q),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Actions & Dialogs ─────────────────────────────────────────────────────
  void _duplicateQuestion(Map<String, dynamic> q) {
    final newQ = Map<String, dynamic>.from(q);
    newQ['questionBankId'] = 'QB00${repo.questionBank.length + 1}';
    newQ['id'] = newQ['questionBankId'];
    newQ['question'] = '${q['question']} (Copy)';
    newQ['status'] = 'Draft';
    newQ['submissionStatus'] = 'Draft';
    newQ['createdAt'] = DateTime.now().toIso8601String();
    QuestionBankService.save(newQ);
    repo.questionBank = QuestionBankService.getAll();
    repo.notify();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question duplicated as Draft! ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteQuestion(Map<String, dynamic> q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Question',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this question?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              QuestionBankService.delete(
                q['questionBankId']?.toString() ?? q['id']?.toString() ?? '',
              );
              repo.questionBank = QuestionBankService.getAll();
              repo.notify();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Question deleted ✓'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

  void _submitToHOD() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Text(
              'Submit to HOD',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to submit the complete Question Bank for $_selectedSubject to the HOD?\n\nOnce submitted, question editing will be locked pending review.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              QuestionBankService.updateBankStatus(
                subject: _selectedSubject,
                status: 'Pending HOD Review',
              );
              repo.questionBank = QuestionBankService.getAll();
              repo.notify();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Question Bank submitted successfully. Awaiting HOD review. ✓',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
            ),
            child: Text(
              'Confirm & Submit',
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

  void _showFullPreviewDialog() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final u in ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5']) {
      grouped[u] = repo.questionBank.where((q) => q['unit'] == u).toList();
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          width: 900,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.preview_rounded,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Complete Question Bank Preview — DBMS',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: grouped.entries.map((e) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${e.key} (${e.value.length} Questions)',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        if (e.value.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              bottom: 12,
                            ),
                            child: Text(
                              'No questions added for this unit.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          ...e.value.asMap().entries.map((qEntry) {
                            final q = qEntry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${qEntry.key + 1}.',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q['question']?.toString() ?? '',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          children: [
                                            _smallBadge(
                                              '${q['marks']} Marks',
                                              const Color(0xFFEFF6FF),
                                              const Color(0xFF2563EB),
                                            ),
                                            _smallBadge(
                                              q['difficulty']?.toString() ??
                                                  'MEDIUM',
                                              const Color(0xFFFFF7ED),
                                              const Color(0xFFF59E0B),
                                            ),
                                            _smallBadge(
                                              q['bloom']?.toString() ??
                                                  'Understand (L2)',
                                              const Color(0xFFF1F5F9),
                                              const Color(0xFF475569),
                                            ),
                                            _smallBadge(
                                              q['type']?.toString() ??
                                                  'Part B (13 Marks)',
                                              const Color(0xFFF3E8FF),
                                              const Color(0xFF8B5CF6),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSinglePreviewDialog(Map<String, dynamic> q, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Question #$index Detail View',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question:',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              q['question']?.toString() ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _infoRow('Unit', q['unit'] ?? 'Unit 1'),
            _infoRow('Difficulty', q['difficulty'] ?? 'MEDIUM'),
            _infoRow('Bloom Level', q['bloom'] ?? 'Understand (L2)'),
            _infoRow('Question Type', q['type'] ?? 'Part B (13 Marks)'),
            _infoRow('Marks', '${q['marks']} Marks'),
            _infoRow('Status', q['status'] ?? 'Draft'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    ),
  );

  Widget _rightPanel() {
    return Column(
      children: [
        // Review History Timeline Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_edu_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Review History',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _timelineItem(
                    'Draft',
                    'Faculty created question bank draft',
                    true,
                    false,
                  ),
                  _timelineItem(
                    'Submitted to HOD',
                    'Awaiting HOD review',
                    _currentBankStatus != 'Draft',
                    false,
                  ),
                  if (_currentBankStatus == 'Rejected by HOD')
                    _timelineItem(
                      'Rejected by HOD',
                      'Requires revisions',
                      true,
                      true,
                    )
                  else if (_currentBankStatus == 'Approved by HOD')
                    _timelineItem(
                      'Approved by HOD',
                      'Finalized by HOD',
                      true,
                      false,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Export Actions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecor(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export & Report Tools',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _qaRow(
                Icons.picture_as_pdf_outlined,
                const Color(0xFFEF4444),
                'Export PDF Report',
                () => _exportData('PDF'),
              ),
              const SizedBox(height: 8),
              _qaRow(
                Icons.table_view_outlined,
                const Color(0xFF10B981),
                'Export Excel Sheet',
                () => _exportData('Excel'),
              ),
              const SizedBox(height: 8),
              _qaRow(
                Icons.article_outlined,
                const Color(0xFF2563EB),
                'Export CSV Bank',
                () => _exportData('CSV'),
              ),
              const SizedBox(height: 8),
              _qaRow(
                Icons.print_outlined,
                const Color(0xFF475569),
                'Print Question Bank',
                _printQuestionBank,
              ),
              const SizedBox(height: 8),
              _qaRow(
                Icons.copy_all_outlined,
                const Color(0xFF8B5CF6),
                'Copy Filtered Records',
                _copyFilteredRecords,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _buildQuestionBankHtml() {
    final html = StringBuffer();
    final dept =
        repo.profile['department'] ?? 'Computer Science and Engineering';
    final facultyName = repo.profile['name'] ?? 'Mr. P. Kalaiyarasan';

    final rowsBuf = StringBuffer();
    int idx = 1;
    for (final q in _filteredQuestions) {
      rowsBuf.writeln('''
        <div style="border:1px solid #cbd5e1; border-radius:6px; padding:12px; margin-bottom:12px; page-break-inside:avoid;">
          <div style="display:flex; justify-content:space-between; font-size:11px; color:#64748b; font-weight:bold; margin-bottom:6px; border-bottom:1px solid #f1f5f9; padding-bottom:4px;">
            <span>Q${idx++}. [${q['unit']}] — ${q['type']}</span>
            <span>Marks: ${q['marks']}M | Bloom: ${q['bloom']} | CO: ${q['co'] ?? 'CO1'}</span>
          </div>
          <div style="font-size:13px; font-weight:bold; color:#0f172a; margin-bottom:6px;">${q['question']}</div>
          ${q['optionA'] != null ? '<div style="font-size:11px; color:#334155; margin-left:12px;">A) ${q['optionA']}<br>B) ${q['optionB']}<br>C) ${q['optionC']}<br>D) ${q['optionD']}</div>' : ''}
          ${q['answerKey'] != null ? '<div style="font-size:10px; color:#059669; font-weight:bold; margin-top:6px;">Answer Key: ${q['answerKey']}</div>' : ''}
        </div>
      ''');
    }

    html.writeln('''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Question Bank Report</title>
<style>
  @page { size: portrait; margin: 10mm; }
  body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; padding: 20px; color: #0f172a; background: #fff; margin: 0; }
  .header { text-align:center; margin-bottom:12px; border-bottom: 2px solid #1e3a8a; padding-bottom: 8px; }
  .header h1 { margin:0; font-size:22px; color:#1e3a8a; font-weight:bold; }
  .header h3 { margin:4px 0 0; font-size:13px; color:#475569; font-weight:600; }
  .info { display:flex; justify-content:space-between; border:1px solid #cbd5e1;
          background:#f8fafc; border-radius:6px; padding:10px 16px; margin:12px 0; font-size:12px; }
  .info span { font-weight:bold; color:#1e293b; }
</style>
</head>
<body>
<div class="header">
  <h1>K.S.R. COLLEGE OF ENGINEERING</h1>
  <h3>Department of $dept</h3>
  <h3>Academic Question Bank Repository — $_selectedSubject</h3>
</div>
<div class="info">
  <div>Faculty: <span>$facultyName</span></div>
  <div>Subject: <span>$_selectedSubject</span></div>
  <div>Unit Filter: <span>$_activeUnit</span></div>
  <div>Generated: <span>${DateTime.now().toString().substring(0, 16)}</span></div>
</div>
$rowsBuf
</body>
</html>''');

    return html.toString();
  }

  void _printQuestionBank() {
    repo.triggerPrintHtmlDocument(_buildQuestionBankHtml());
  }

  Widget _timelineItem(
    String title,
    String subtitle,
    bool isCompleted,
    bool isError,
  ) {
    final Color col = isError
        ? const Color(0xFFDC2626)
        : (isCompleted ? const Color(0xFF059669) : const Color(0xFF94A3B8));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF334155),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyFilteredRecords() {
    final text = _filteredQuestions
        .map(
          (q) =>
              '${q['unit']} | ${q['difficulty']} | ${q['question']} (${q['marks']}M)',
        )
        .join('\n');
    repo.triggerFileDownload('question_bank_copied.txt', text, 'text/plain');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filtered records copied to clipboard ✓'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData(String format) {
    final csv = StringBuffer();
    csv.writeln(
      'ID,Subject,Unit,Difficulty,Bloom Level,Type,Question,Marks,Status',
    );
    for (final q in _filteredQuestions) {
      csv.writeln(
        '"${q['id']}","${q['subject']}","${q['unit']}","${q['difficulty']}","${q['bloom']}","${q['type']}","${q['question']}",${q['marks']},"${q['status']}"',
      );
    }
    repo.triggerFileDownload(
      'question_bank_dbms.${format.toLowerCase() == 'excel' ? 'xls' : format.toLowerCase()}',
      csv.toString(),
      'text/csv',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting $format question bank report...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAddQuestionDialog(Map<String, dynamic>? editing) {
    final isEdit = editing != null;
    final qCtrl = TextEditingController(
      text: isEdit ? editing['question'] : '',
    );
    final marksCtrl = TextEditingController(
      text: isEdit ? '${editing['marks']}' : '13',
    );
    final coCtrl = TextEditingController(
      text: isEdit ? (editing['co'] ?? 'CO1') : 'CO1',
    );

    String difficulty = isEdit ? editing['difficulty'] : 'MEDIUM';
    String unit = isEdit ? editing['unit'] : 'Unit 1';
    String bloom = isEdit ? editing['bloom'] : 'Understand (L2)';
    String type = isEdit ? editing['type'] : 'Part B (13 Marks)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit_note : Icons.add_circle_outline,
                      color: const Color(0xFF2563EB),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEdit ? 'Edit Question' : 'Add New Question to Bank',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _dlgDropdown(
                      'Unit',
                      ['Unit 1', 'Unit 2', 'Unit 3', 'Unit 4', 'Unit 5'],
                      unit,
                      (v) => setModal(() => unit = v!),
                    ),
                    _dlgDropdown(
                      'Difficulty',
                      ['EASY', 'MEDIUM', 'HARD'],
                      difficulty,
                      (v) => setModal(() => difficulty = v!),
                    ),
                    _dlgDropdown(
                      'Bloom Taxonomy',
                      [
                        'Remember (L1)',
                        'Understand (L2)',
                        'Apply (L3)',
                        'Analyze (L4)',
                        'Evaluate (L5)',
                        'Create (L6)',
                      ],
                      bloom,
                      (v) => setModal(() => bloom = v!),
                    ),
                    _dlgDropdown(
                      'Question Type',
                      [
                        'Part A (2 Marks)',
                        'Part B (13 Marks)',
                        'Part C (15 Marks)',
                      ],
                      type,
                      (v) => setModal(() => type = v!),
                    ),
                    _dlgField('Marks', marksCtrl),
                    _dlgField('Course Outcome (CO)', coCtrl),
                  ],
                ),
                const SizedBox(height: 16),
                _dlgField('Question Text', qCtrl, maxLines: 4),
                const SizedBox(height: 20),
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
                    ElevatedButton(
                      onPressed: () {
                        if (qCtrl.text.trim().isEmpty) return;
                        final map = <String, dynamic>{
                          'questionBankId': isEdit
                              ? editing['questionBankId']
                              : 'QB00${repo.questionBank.length + 1}',
                          'id': isEdit
                              ? editing['id']
                              : 'QB00${repo.questionBank.length + 1}',
                          'facultyId':
                              repo.profile['employeeId'] ?? 'EMP_CSE_002',
                          'facultyName': repo.profile['name'] ?? '',
                          'subject': _selectedSubject,
                          'unit': unit,
                          'difficulty': difficulty,
                          'bloom': bloom,
                          'type': type,
                          'marks': int.tryParse(marksCtrl.text.trim()) ?? 13,
                          'co': coCtrl.text.trim(),
                          'question': qCtrl.text.trim(),
                          'status': 'Draft',
                          'submissionStatus': 'Draft',
                          'createdAt': DateTime.now().toIso8601String(),
                        };

                        QuestionBankService.save(map);
                        repo.questionBank = QuestionBankService.getAll();
                        repo.notify();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Question updated ✓'
                                  : 'Question added to Draft bank ✓',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Save Question as Draft',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dlgDropdown(
    String label,
    List<String> items,
    String currentVal,
    ValueChanged<String?> onChange,
  ) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<String>(
        value: currentVal,
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
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 11),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dlgField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return SizedBox(
      width: maxLines > 1 ? double.infinity : 200,
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 11),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dropdown(
    List<String> items,
    String val,
    ValueChanged<String?> onChange,
  ) {
    final uniqueItems = items.toSet().toList();
    final validVal = uniqueItems.contains(val)
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
      initialValue: validVal,
      onSelected: onChange,
      itemBuilder: (context) {
        return uniqueItems.map((item) {
          final bool isSelected = item == validVal;
          return PopupMenuItem<String>(
            value: item,
            height: 38,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 11,
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              validVal,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
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

  Widget _statusChip(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);
    if (status == 'Approved by HOD' || status == 'Approved') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF059669);
    } else if (status == 'Pending HOD Review' ||
        status == 'Submitted' ||
        status == 'Pending Review') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFD97706);
    } else if (status == 'Rejected by HOD' || status == 'Rejected') {
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
    } else if (status == 'Draft') {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _smallBadge(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: fg,
      ),
    ),
  );

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

  Widget _bc(String t, {bool active = false}) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 12,
      color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
      fontWeight: active ? FontWeight.w600 : FontWeight.normal,
    ),
  );

  Widget _circleAction(
    IconData icon,
    Color fg,
    Color bg, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: fg),
      ),
    );
  }

  Widget _qaRow(IconData icon, Color col, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: col, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
