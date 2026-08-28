// ignore_for_file: avoid_web_libraries_in_flutter, unused_element
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:html' as html;
import '../models/app_state.dart';
import '../widgets/student_loading_widget.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _selectedAttendanceMonth;
  int _subjectsCurrentPage = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    _selectedAttendanceMonth = '${months[now.month - 1]} ${now.year}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.instance.fetchAllData();
    });
  }

  void _showEditProfileModal(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController(text: appState.getProfileField('full_name').isEmpty ? appState.studentName : appState.getProfileField('full_name'));
    final emailCtrl = TextEditingController(text: appState.personalEmail);
    final phoneCtrl = TextEditingController(text: appState.mobileNumber);
    final addrCtrl = TextEditingController(text: appState.address);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.edit_note, color: Color(0xFF2563EB), size: 24),
                        SizedBox(width: 8),
                        Text('Update Profile Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Personal Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Residential Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: addrCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        appState.updateProfile(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          addr: addrCtrl.text.trim(),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: Color(0xFF16A34A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768 && !isDesktop;

    if (appState.isLoading && !appState.isDataFetched) {
      return const SizedBox(
        height: 400,
        child: StudentLoadingWidget(
          size: 60,
          showMessage: false,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mega Announcement Ticker & Header Row
          Row(
            children: [
              Expanded(
                child: AnnouncementTicker(
                  onTap: () => widget.onNavigate(20),
                  notices: (() {
                    final last3 = appState.notices.take(3).map((n) => n.title).toList();
                    if (last3.isEmpty) {
                      return [
                        'Hackathon 2026 Registration Open • Test Hackathon Notice 1785495498071',
                        'Admissions Open 2024 • K.S.R. College of Engineering Admissions',
                        'Summer Internship Registration Closes in 3 Days',
                      ];
                    } else if (last3.length == 1) {
                      return [
                        last3[0],
                        'Admissions Open 2024 • K.S.R. College of Engineering Admissions',
                        'Summer Internship Registration Closes in 3 Days',
                      ];
                    } else if (last3.length == 2) {
                      return [
                        last3[0],
                        last3[1],
                        'Summer Internship Registration Closes in 3 Days',
                      ];
                    }
                    return last3;
                  })(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Row Metric Cards (4 Cards)
          LayoutBuilder(
            builder: (context, constraints) {
              final double spacing = 16.0;
              int crossAxisCount = 4;
              if (constraints.maxWidth < 600) {
                crossAxisCount = 2;
              } else if (constraints.maxWidth < 900) {
                crossAxisCount = 2;
              } else {
                crossAxisCount = 4;
              }

              final double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

              final issuedBooksCount = appState.libraryTransactions.where((t) => (t['is_active'] == true || t['type'] == 'Issue')).length + appState.books.where((b) => b.isIssued).length;
              final pendingFees = appState.getProfileField('pending_fees').isEmpty ? appState.getProfileField('pending_fees_total') : appState.getProfileField('pending_fees');
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(width: itemWidth, child: _buildAttendanceCard(appState)),
                  SizedBox(width: itemWidth, child: _buildStandardMetricCard(icon: Icons.school_outlined, iconBg: const Color(0xFFDBEAFE), iconColor: const Color(0xFF2563EB), value: appState.getProfileField('cgpa').isEmpty ? '-' : appState.getProfileField('cgpa'), label: 'CGPA', subtitle: 'Semester ${appState.getProfileField('semester')}', footer: '', footerIcon: null)),
                  SizedBox(width: itemWidth, child: _buildStandardMetricCard(icon: Icons.currency_rupee, iconBg: const Color(0xFFFFEDD5), iconColor: const Color(0xFFF97316), value: pendingFees.isEmpty || pendingFees == '0' ? '₹0' : '₹$pendingFees', label: 'Fees', subtitle: 'Due Amount', footer: pendingFees.isEmpty || pendingFees == '0' ? 'All Fees Paid' : 'Pending Payment', footerColor: const Color(0xFFDC2626))),
                  SizedBox(width: itemWidth, child: _buildStandardMetricCard(icon: Icons.menu_book_outlined, iconBg: const Color(0xFFE0E7FF), iconColor: const Color(0xFF4F46E5), value: '$issuedBooksCount', label: 'Library', subtitle: 'Books Issued', footer: issuedBooksCount > 0 ? '$issuedBooksCount Active Borrowed' : 'No Books Issued', footerColor: const Color(0xFF2563EB))),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Row 1: Today's Schedule + Attendance Heatmap + Fee Overview (equal height)
          if (isDesktop || isTablet)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _buildTodaysSchedule(appState)),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: _buildAttendanceHeatmap(appState)),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildFeeOverview(appState)),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildTodaysSchedule(appState),
                const SizedBox(height: 16),
                _buildAttendanceHeatmap(appState),
                const SizedBox(height: 16),
                _buildFeeOverview(appState),
              ],
            ),
          const SizedBox(height: 16),

          // Row 2: My Subjects, Placement Tracker & Upcoming Events (three equal columns)
          if (isDesktop || isTablet)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildMySubjects(appState)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPlacementTracker(appState)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUpcomingEvents(appState)),
                ],
              ),
            )
          else
            Column(
              children: [
                _buildMySubjects(appState),
                const SizedBox(height: 16),
                _buildPlacementTracker(appState),
                const SizedBox(height: 16),
                _buildUpcomingEvents(appState),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dashboard Metric Cards
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceCard(AppState appState) {
    // Primary: use profile field; Fallback: compute from Supabase attendance records
    String attRaw = appState.getProfileField('attendance_percentage');
    if (attRaw.isEmpty && appState.attendanceRecords.isNotEmpty) {
      double sum = 0;
      int count = 0;
      for (var r in appState.attendanceRecords) {
        final p = double.tryParse(r['attendance_percentage']?.toString() ?? '');
        if (p != null) {
          sum += p;
          count++;
        }
      }
      if (count > 0) {
        attRaw = (sum / count).toStringAsFixed(1);
      }
    }
    final double attValue = (double.tryParse(attRaw) ?? 0.0) / 100.0;
    final String attText = attRaw.isEmpty ? '0%' : '$attRaw%';
    final Color attColor = attValue >= 0.85 ? const Color(0xFF16A34A) : (attValue >= 0.75 ? const Color(0xFFF59E0B) : const Color(0xFFDC2626));
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: attValue,
                    strokeWidth: 6.5,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(attColor),
                  ),
                ),
                Text(
                  attText,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Attendance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                const Text('Overall Status', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  attValue >= 0.75 ? 'Good Standing' : 'Low Standing',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: attColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardMetricCard({
    required IconData icon, required Color iconBg, required Color iconColor,
    required String label, required String value, required String subtitle,
    required String footer, Color? footerColor, IconData? footerIcon,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: iconColor, size: 22)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (footer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (footerIcon != null) ...[
                        Icon(footerIcon, size: 10, color: footerColor),
                        const SizedBox(width: 2),
                      ],
                      Expanded(child: Text(footer, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: footerColor ?? const Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterProgressCard(AppState appState) {
    final now = DateTime.now();
    final semType = appState.getProfileField('semester_type').toUpperCase();
    
    DateTime start;
    DateTime end;
    if (semType == 'EVEN') {
      start = DateTime(now.year - (now.month < 6 ? 1 : 0), 12, 1);
      end = DateTime(now.year + (now.month >= 6 ? 1 : 0), 5, 31);
    } else {
      start = DateTime(now.year - (now.month < 6 ? 1 : 0), 6, 1);
      end = DateTime(now.year + (now.month >= 6 ? 1 : 0), 11, 30);
    }

    double progress = 0.0;
    int totalDays = end.difference(start).inDays;
    int passedDays = now.difference(start).inDays;
    if (totalDays > 0) {
      progress = (passedDays / totalDays).clamp(0.0, 1.0);
    }
    final int progressPct = (progress * 100).round();
    final int remainingDays = end.difference(now).inDays.clamp(0, 365);
    final int currentWeek = (passedDays / 7).ceil().clamp(1, 16);

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 70, height: 70,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF14B8A6))),
                Text('$progressPct%', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sem Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Week $currentWeek / 16', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$remainingDays Days Left', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Card (Right Column)
  // ---------------------------------------------------------------------------
  Widget _buildStudentProfileCard(AppState appState) {
    final name = appState.getProfileField('full_name').isNotEmpty 
        ? appState.getProfileField('full_name') 
        : (appState.studentName.isNotEmpty ? appState.studentName : 'Student');
    
    final initials = name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    final regNo = appState.getProfileField('register_no').isNotEmpty ? appState.getProfileField('register_no') : appState.studentId;
    final dept = appState.getProfileField('department').isNotEmpty ? appState.getProfileField('department') : 'CSE';
    final year = appState.getProfileField('year_of_study').isNotEmpty ? appState.getProfileField('year_of_study') : '${appState.yearOfStudy}';
    final advisor = appState.getProfileField('class_advisor_name').isNotEmpty 
        ? appState.getProfileField('class_advisor_name') 
        : (appState.getProfileField('class_advisor').isNotEmpty ? appState.getProfileField('class_advisor') : 'Class Advisor');
    final batch = appState.getProfileField('batch').isNotEmpty ? appState.getProfileField('batch') : '2022-2026';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0B2265),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF0B2265).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Online', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.qr_code_2, color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 2)),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF1E3A8A),
                child: Text(initials.isEmpty ? 'ST' : initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEAB308).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('Year $year • $dept', style: const TextStyle(color: Color(0xFFFDE047), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          _buildProfileDetailRow(Icons.badge_outlined, 'Register No.', regNo),
          _buildProfileDetailRow(Icons.domain, 'Department', dept),
          _buildProfileDetailRow(Icons.person_pin_circle_outlined, 'Advisor', advisor),
          _buildProfileDetailRow(Icons.calendar_today, 'Batch', batch),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onNavigate(2),
              icon: const Icon(Icons.person_outline, size: 18, color: Colors.white),
              label: const Text('View Full Profile', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white30),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Today's Schedule
  // ---------------------------------------------------------------------------
  Widget _buildTodaysSchedule(AppState appState) {
    final String currentDayName = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ][DateTime.now().weekday % 7];

    var todaySlots = appState.timetables.where((t) {
      final day = t['day_of_week']?.toString().trim().toLowerCase() ?? '';
      return day == currentDayName.toLowerCase();
    }).toList();

    if (todaySlots.isEmpty && appState.timetables.isNotEmpty) {
      final firstDay = appState.timetables.first['day_of_week']?.toString() ?? 'Monday';
      todaySlots = appState.timetables.where((t) => (t['day_of_week']?.toString().trim().toLowerCase() ?? '') == firstDay.toLowerCase()).toList();
    }

    todaySlots.sort((a, b) {
      final sa = a['start_time']?.toString() ?? '';
      final sb = b['start_time']?.toString() ?? '';
      return sa.compareTo(sb);
    });

    return _buildBentoCard(
      title: 'Today\'s Schedule (${todaySlots.isNotEmpty ? (todaySlots.first['day_of_week'] ?? currentDayName) : currentDayName})',
      actionText: 'View Full Timetable',
      onAction: () => widget.onNavigate(1),
      child: todaySlots.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Text('No classes scheduled for today', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            )
          : Column(
              children: todaySlots.take(4).map((t) {
                final startRaw = t['start_time']?.toString() ?? '09:00';
                final endRaw = t['end_time']?.toString() ?? '10:00';
                final start = startRaw.length >= 5 ? startRaw.substring(0, 5) : startRaw;
                final end = endRaw.length >= 5 ? endRaw.substring(0, 5) : endRaw;
                final timeRange = '$start - $end';
                final subject = t['subject_name']?.toString() ?? t['course_code']?.toString() ?? 'Subject';
                final room = t['room_number']?.toString() ?? 'LH-101';
                
                final int codeSum = subject.codeUnits.fold(0, (prev, element) => prev + element);
                final Color color = [
                  const Color(0xFF3B82F6),
                  const Color(0xFF10B981),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFF59E0B),
                ][codeSum % 4];

                return Column(
                  children: [
                    _buildScheduleItem(timeRange, subject, room, color),
                    if (t != todaySlots.take(4).last)
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildScheduleItem(String time, String subject, String room, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
        Container(width: 2, height: 30, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(room, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        Container(width: 4, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Attendance Heatmap
  // ---------------------------------------------------------------------------
  Widget _buildAttendanceHeatmap(AppState appState) {
    final Map<String, String> monthKeys = {
      'July 2026': '2026-07',
      'August 2026': '2026-08',
      'September 2026': '2026-09',
      'October 2026': '2026-10',
    };

    final selectedKey = monthKeys[_selectedAttendanceMonth] ?? '2026-07';

    final monthRecords = appState.attendanceRecords.where((a) {
      final dt = a['date']?.toString() ?? '';
      return dt.startsWith(selectedKey);
    }).toList();

    monthRecords.sort((a, b) {
      final da = a['date']?.toString() ?? '';
      final db = b['date']?.toString() ?? '';
      return da.compareTo(db);
    });

    return _buildBentoCard(
      title: 'Attendance Heatmap',
      headerWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                final keys = monthKeys.keys.toList();
                final idx = keys.indexOf(_selectedAttendanceMonth);
                if (idx > 0) {
                  setState(() => _selectedAttendanceMonth = keys[idx - 1]);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(Icons.chevron_left, size: 18, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _selectedAttendanceMonth,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () {
                final keys = monthKeys.keys.toList();
                final idx = keys.indexOf(_selectedAttendanceMonth);
                if (idx < keys.length - 1) {
                  setState(() => _selectedAttendanceMonth = keys[idx + 1]);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(Icons.chevron_right, size: 18, color: Color(0xFF2563EB)),
              ),
            ),
          ],
        ),
      ),
      actionText: '',
      onAction: () {},
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((d) => SizedBox(width: 32, child: Center(child: Text(d, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)))))).toList(),
          ),
          const SizedBox(height: 12),
          for (int row = 0; row < 4; row++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                final int recordIndex = row * 6 + index;
                
                Color bg = const Color(0xFFF1F5F9);
                String label = '-';
                
                if (recordIndex < monthRecords.length) {
                  final item = monthRecords[recordIndex];
                  bool hasPresent = false;
                  bool hasAbsent = false;
                  bool hasOD = false;
                  for (int p = 1; p <= 8; p++) {
                    final val = item['p$p'];
                    if (val != null) {
                      final str = val.toString().trim().toUpperCase();
                      if (str == 'P' || str == 'PRESENT' || str == 'TRUE') hasPresent = true;
                      if (str == 'A' || str == 'ABSENT' || str == 'FALSE') hasAbsent = true;
                      if (str == 'OD' || str == 'ML') hasOD = true;
                    }
                  }
                  
                  if (hasAbsent) {
                    bg = const Color(0xFFEF4444);
                    label = 'A';
                  } else if (hasOD) {
                    bg = const Color(0xFFF59E0B);
                    label = 'OD';
                  } else if (hasPresent) {
                    bg = const Color(0xFF10B981);
                    label = 'P';
                  } else {
                    bg = const Color(0xFF10B981);
                    label = 'P';
                  }
                }

                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: bg.withValues(alpha: label == '-' ? 0.5 : 0.15), borderRadius: BorderRadius.circular(6)),
                  alignment: Alignment.center,
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: label == '-' ? const Color(0xFF94A3B8) : bg)),
                );
              }),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('P', 'Present', const Color(0xFF10B981)),
              const SizedBox(width: 16),
              _buildLegend('A', 'Absent', const Color(0xFFEF4444)),
              const SizedBox(width: 16),
              _buildLegend('OD', 'On Duty', const Color(0xFFF59E0B)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // My Subjects (This Semester)
  // ---------------------------------------------------------------------------
  Widget _buildMySubjects(AppState appState) {
    if (!appState.isCurrentAcademicYear) {
      return _buildBentoCard(
        title: 'My Subjects (This Sem)',
        actionText: '',
        onAction: () {},
        child: const SizedBox(
          height: 180,
          child: Center(
            child: Text(
              'No subjects assigned for this academic year.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final Map<String, String> subjectsMap = {};
    final studentDept = appState.getProfileField('department', defaultValue: 'CSE').trim().toUpperCase();
    final studentSemStr = appState.getProfileField('semester', defaultValue: '5').trim();

    int romanToSubspaceInt(String roman) {
      final trimmed = roman.trim();
      final parsed = int.tryParse(trimmed);
      if (parsed != null) return parsed;
      switch (trimmed.toUpperCase()) {
        case 'I': return 1;
        case 'II': return 2;
        case 'III': return 3;
        case 'IV': return 4;
        case 'V': return 5;
        case 'VI': return 6;
        case 'VII': return 7;
        case 'VIII': return 8;
        default: return 0;
      }
    }

    final int targetSemInt = romanToSubspaceInt(studentSemStr.isEmpty ? 'V' : studentSemStr);
    for (var reg in appState.regulationsList) {
      final regSem = int.tryParse(reg['semester']?.toString() ?? '') ?? 0;
      final regDept = (reg['department'] ?? '').toString().trim().toUpperCase();
      if (regSem == targetSemInt && regDept == studentDept) {
        final code = (reg['course_code'] ?? '').toString().trim();
        final name = (reg['course_name'] ?? '').toString().trim();
        if (code.isNotEmpty && name.isNotEmpty) {
          subjectsMap[code] = name;
        }
      }
    }

    final List<Map<String, String>> subjects = subjectsMap.entries.map((e) => {
      'course_code': e.key,
      'subject_name': e.value,
    }).toList();

    // Clean up parenthesis from subject names
    for (var s in subjects) {
      String name = s['subject_name']!;
      if (name.contains('(') && name.contains(')')) {
        final start = name.indexOf('(');
        s['subject_name'] = name.substring(0, start).trim();
      }
    }

    int activePage = _subjectsCurrentPage;
    final totalPages = (subjects.length / 5).ceil();
    if (activePage > totalPages) {
      activePage = totalPages > 0 ? totalPages : 1;
    }

    final startIndex = (activePage - 1) * 5;
    final endIndex = startIndex + 5;
    final displayedSubjects = subjects.isEmpty
        ? <Map<String, String>>[]
        : subjects.sublist(startIndex, endIndex > subjects.length ? subjects.length : endIndex);

    final List<Widget> list = [];
    for (int i = 0; i < displayedSubjects.length; i++) {
      final row = displayedSubjects[i];
      String code = row['course_code']!;
      String name = row['subject_name']!;
      
      list.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ));
      if (i < displayedSubjects.length - 1) {
        list.add(const Divider(height: 12, color: const Color(0xFFF1F5F9)));
      }
    }

    // Pagination controls row
    Widget paginationWidget = const SizedBox();
    if (subjects.length > 5) {
      final actualEndIndex = endIndex > subjects.length ? subjects.length : endIndex;
      paginationWidget = Column(
        children: [
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${startIndex + 1} to $actualEndIndex of ${subjects.length} subjects',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 16),
                    color: activePage > 1 ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: activePage > 1
                        ? () => setState(() => _subjectsCurrentPage = activePage - 1)
                        : null,
                  ),
                  const SizedBox(width: 4),
                  ...List.generate(totalPages, (index) {
                    final pageNum = index + 1;
                    final isSelected = activePage == pageNum;
                    return InkWell(
                      onTap: () => setState(() => _subjectsCurrentPage = pageNum),
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$pageNum',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 16),
                    color: activePage < totalPages ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: activePage < totalPages
                        ? () => setState(() => _subjectsCurrentPage = activePage + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    return _buildBentoCard(
      title: 'My Subjects (This Sem)',
      actionText: '',
      onAction: () {},
      child: subjects.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Text('No subjects assigned', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...list,
                paginationWidget,
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Placement Tracker
  // ---------------------------------------------------------------------------
  Widget _buildPlacementTracker(AppState appState) {
    Widget buildEmailDetailRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w600))),
          ],
        ),
      );
    }

    final drives = appState.placements;
    final int totalDrives = drives.length;
    final int applied = drives.where((p) => p.hasApplied).length;
    final int shortlisted = drives.where((p) => p.status.toLowerCase() == 'shortlisted' || p.status.toLowerCase() == 'selected').length;
    final int interviews = drives.where((p) => p.status.toLowerCase() == 'interview' || p.status.toLowerCase() == 'interviewing').length;

    final appliedDrives = drives.where((p) => p.hasApplied).toList();

    return _buildBentoCard(
      title: 'Placement Tracker',
      actionText: 'Update',
      onAction: () => html.window.open('https://placement--portal.vercel.app', '_blank'),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPlacementStat(totalDrives.toString(), 'Companies', const Color(0xFF8B5CF6)),
              _buildPlacementStat(applied.toString(), 'Applied', const Color(0xFF3B82F6)),
              _buildPlacementStat(shortlisted.toString(), 'Shortlisted', const Color(0xFFF59E0B)),
              _buildPlacementStat(interviews.toString(), 'Interviews', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 16),
          if (appliedDrives.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'No active placement applications found.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business, size: 14, color: Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        appliedDrives.first.company,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          appliedDrives.first.status,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  const Text(
                    'Application Summary',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  buildEmailDetailRow('Role', appliedDrives.first.role),
                  buildEmailDetailRow('Package (CTC)', appliedDrives.first.package),
                  buildEmailDetailRow('Status', appliedDrives.first.status),
                  buildEmailDetailRow('Deadline', appliedDrives.first.deadline),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlacementStat(String val, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 3)),
          alignment: Alignment.center,
          child: Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }
  // ---------------------------------------------------------------------------
  // Fee Overview
  // ---------------------------------------------------------------------------
  Widget _buildFeeOverview(AppState appState) {
    final selectedAy = appState.selectedAcademicYear;
    final matchingFees = appState.fees.where((f) {
      return f.academicYear.isEmpty || f.academicYear == selectedAy || f.academicYear.contains(selectedAy) || selectedAy.contains(f.academicYear);
    }).toList();

    double paid = 0.0;
    double pending = 0.0;
    if (matchingFees.isNotEmpty) {
      for (var f in matchingFees) {
        if (f.isPaid) {
          paid += f.amount;
        } else {
          pending += f.amount;
        }
      }
    } else {
      paid = double.tryParse(appState.getProfileField('fees_paid')) ?? 0.0;
      pending = double.tryParse(appState.getProfileField('pending_fees').isEmpty ? appState.getProfileField('pending_fees_total') : appState.getProfileField('pending_fees')) ?? 0.0;
    }
    final double total = paid + pending;
    
    double progress = 1.0;
    if (total > 0) {
      progress = paid / total;
    }
    final int progressPct = (progress * 100).round();

    return _buildBentoCard(
      title: 'Fee Overview',
      actionText: 'View Details',
      onAction: () => widget.onNavigate(9),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 75, 
                height: 75, 
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        child: CircularProgressIndicator(
                          value: progress, 
                          strokeWidth: 6, 
                          backgroundColor: const Color(0xFFF1F5F9), 
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$progressPct%', 
                          textAlign: TextAlign.center, 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)), 
                        ),
                        const Text(
                          'Paid', 
                          textAlign: TextAlign.center, 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Fees', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 8),
                    const Text('Paid Fees', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                    Text('₹${paid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    const SizedBox(height: 8),
                    const Text('Due Fees', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                    Text('₹${pending.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onNavigate(9),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), 
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Pay Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Base Bento Box Card Wrapper
  // ---------------------------------------------------------------------------
  Widget _buildBentoCard({required String title, required String actionText, required VoidCallback onAction, Widget? headerWidget, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              if (headerWidget != null)
                headerWidget
              else if (actionText.isNotEmpty)
                InkWell(
                  onTap: onAction,
                  child: Text(actionText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Upcoming Events
  // ---------------------------------------------------------------------------
  Widget _buildUpcomingEvents(AppState appState) {
    final List<Map<String, dynamic>> events = [];
    if (appState.academicCalendarEvents.isNotEmpty) {
      events.addAll(appState.academicCalendarEvents);
    } else if (appState.notices.isNotEmpty) {
      for (var n in appState.notices) {
        events.add({
          'title': n.title,
          'event_date': n.date,
          'start_time': n.time,
          'event_type': n.category,
        });
      }
    }

    events.sort((a, b) {
      final da = a['event_date']?.toString() ?? '';
      final db = b['event_date']?.toString() ?? '';
      return da.compareTo(db);
    });

    final List<Widget> list = [];
    for (int i = 0; i < events.length && i < 3; i++) {
      final e = events[i];
      final title = e['title'] ?? 'Event';
      final dateStr = e['event_date']?.toString() ?? '';
      final timeStr = e['start_time']?.toString() ?? '';
      final displayTime = '$dateStr • $timeStr';
      final type = (e['event_type'] ?? '').toString().toLowerCase();
      
      IconData icon = Icons.event;
      Color color = const Color(0xFF3B82F6);
      if (type.contains('exam') || type.contains('test')) {
        icon = Icons.assignment;
        color = const Color(0xFFEF4444);
      } else if (type.contains('holiday')) {
        icon = Icons.calendar_today;
        color = const Color(0xFF10B981);
      } else if (type.contains('meet')) {
        icon = Icons.people;
        color = const Color(0xFFF59E0B);
      }
      
      list.add(_buildEventItem(
        icon,
        color,
        title,
        displayTime,
      ));
      if (i < events.length - 1 && i < 2) {
        list.add(const SizedBox(height: 12));
      }
    }

    return _buildBentoCard(
      title: 'Upcoming Events',
      actionText: '',
      onAction: () {},
      child: Column(
        children: [
          if (events.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text('No upcoming events scheduled', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              ),
            )
          else
            ...list,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onNavigate(1),
              icon: const Icon(Icons.calendar_month, size: 16, color: Color(0xFF2563EB)),
              label: const Text('View Full Events Calendar', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2563EB)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(IconData icon, Color color, String title, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class SlidingNoticeWidget extends StatefulWidget {
  final List<String> notices;
  final bool isPaused;
  const SlidingNoticeWidget({super.key, required this.notices, this.isPaused = false});

  @override
  State<SlidingNoticeWidget> createState() => _SlidingNoticeWidgetState();
}

class _SlidingNoticeWidgetState extends State<SlidingNoticeWidget> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final initialPage = widget.notices.isNotEmpty ? 12000 - (12000 % widget.notices.length) : 0;
    _currentPageIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.isPaused) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (widget.notices.isEmpty) return;
      
      _currentPageIndex++;
      
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPageIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SlidingNoticeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPaused != widget.isPaused || oldWidget.notices.length != widget.notices.length) {
      if (widget.notices.isNotEmpty) {
        final initialPage = 12000 - (12000 % widget.notices.length);
        _currentPageIndex = initialPage;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(initialPage);
        }
      }
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notices.isEmpty) {
      return const Text(
        'No notifications at the moment.',
        style: TextStyle(color: Colors.white, fontSize: 13),
      );
    }

    return SizedBox(
      height: 22,
      child: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          final noticeIndex = index % widget.notices.length;
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.notices[noticeIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ),
    );
  }
}

class AnnouncementTicker extends StatefulWidget {
  final List<String> notices;
  final VoidCallback onTap;

  const AnnouncementTicker({
    super.key,
    required this.notices,
    required this.onTap,
  });

  @override
  State<AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<AnnouncementTicker> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF1E3A8A) : const Color(0xFF0B2265),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SlidingNoticeWidget(
                  notices: widget.notices,
                  isPaused: _isHovered,
                ),
              ),
              const SizedBox(width: 12),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isHovered ? 1.0 : 0.0,
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
