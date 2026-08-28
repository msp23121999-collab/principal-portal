import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../models/models.dart';
import '../../services/download_service.dart';

class ExaminationsScreen extends StatefulWidget {
  const ExaminationsScreen({super.key});

  @override
  State<ExaminationsScreen> createState() => _ExaminationsScreenState();
}

class _ExaminationsScreenState extends State<ExaminationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _downloadingResultId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = MockData.selectedStudent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Banner ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.sidebarGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_turned_in_rounded, color: AppTheme.secondaryColor, size: 32),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Examinations & Schedule',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.name} • Reg No: ${student.registerNumber} (${student.department})',
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Tab Bar ─────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Upcoming Exams'),
                Tab(text: 'Completed Exams'),
                Tab(text: 'Semester Results'),
              ],
            ),
            const SizedBox(height: 20),

            // ── Tab Content ─────────────────────────────────────────────
            SizedBox(
              height: 700,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingExamsTab(),
                  _buildCompletedExamsTab(),
                  _buildSemesterResultsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExamsTab() {
    final exams = MockData.upcomingExams;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        final daysLeft = exam.date.difference(DateTime.now()).inDays;

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Box
              Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${exam.date.day}',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    Text(
                      _getMonthName(exam.date.month),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Exam Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          exam.subject,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'STARTS IN $daysLeft DAYS',
                            style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(exam.time, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(width: 20),
                        const Icon(Icons.room_rounded, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(exam.venue, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const StatusBadge(status: 'CONFIRMED'),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () => _showExamDetailsModal(exam),
                          icon: const Icon(Icons.info_outline_rounded, size: 16),
                          label: const Text('View Syllabus & Seating', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedExamsTab() {
    final completed = [
      {'subject': 'Software Engineering', 'date': '15 May 2026', 'score': '92 / 100', 'status': 'Passed'},
      {'subject': 'Web Architecture', 'date': '12 May 2026', 'score': '88 / 100', 'status': 'Passed'},
      {'subject': 'Design & Analysis of Algorithms', 'date': '08 May 2026', 'score': '95 / 100', 'status': 'Passed'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completed.length,
      itemBuilder: (context, index) {
        final item = completed[index];
        return CustomCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.successColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['subject']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Date: ${item['date']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item['score']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor)),
                  const SizedBox(height: 4),
                  StatusBadge(status: item['status']!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemesterResultsTab() {
    final results = MockData.mockResults;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final res = results[index];
        final isDownloading = _downloadingResultId == res.semester;
        final hasUrl = res.pdfUrl != null && res.pdfUrl!.isNotEmpty;

        return CustomCard(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(res.semester, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Result: ${res.resultStatus}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('GPA', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      Text(res.gpa.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: isDownloading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_rounded, color: AppTheme.primaryColor),
                      onPressed: hasUrl && !isDownloading
                          ? () => _downloadSemesterResult(res)
                          : null,
                      tooltip: hasUrl ? 'Download Grade Sheet' : 'No document available',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadSemesterResult(ExamResult result) async {
    if (result.pdfUrl == null || result.pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document is currently unavailable.')),
      );
      return;
    }

    setState(() => _downloadingResultId = result.semester);

    try {
      final fileName = '${result.semester.replaceAll(' ', '_')}_Grade_Sheet.pdf';
      final success = await DownloadService.downloadFromUrl(result.pdfUrl!, fileName);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started: $fileName')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed. Please try again.')),
          );
        }
        setState(() => _downloadingResultId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download document. Please try again.')),
        );
        setState(() => _downloadingResultId = null);
      }
    }
  }

  void _showExamDetailsModal(Exam exam) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(exam.subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 20),
              _detailRow('Date & Time', '${exam.date.day}/${exam.date.month}/${exam.date.year} • ${exam.time}'),
              _detailRow('Venue Seating', '${exam.venue} - Row 4, Bench B'),
              _detailRow('Exam Type', 'Autonomous End-Semester Theory'),
              _detailRow('Total Weightage', '100 Marks (3 Hours Duration)'),
              const SizedBox(height: 16),
              const Text('Syllabus Coverage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              const Text('• Unit 1 to 5 complete syllabus as per 2023 Autonomous Regulations.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}
