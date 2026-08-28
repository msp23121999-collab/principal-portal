import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../models/models.dart';

/// Student Profile Screen with comprehensive personal, academic, and admission information.
class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = MockData.selectedStudent;
    final academic = MockData.mockAcademicPerformance;


    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with Student Photo & Basic Info ──────────────────
            _buildProfileHeader(student),
            const SizedBox(height: 20),

            // ── Tab Navigation ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.accentColor,
                  indicatorWeight: 3,
                  isScrollable: true,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Personal'),
                    Tab(text: 'Academic'),
                    Tab(text: 'Contact'),
                    Tab(text: 'Admission'),
                    Tab(text: 'Education'),
                  ],
                ),
              ),
            ),

            // ── Tab Content ────────────────────────────────────────────
            SizedBox(
              height: MediaQuery.of(context).size.height * 1.5,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(student, academic),
                  _buildPersonalTab(student),
                  _buildAcademicTab(student, academic),
                  _buildContactTab(student),
                  _buildAdmissionTab(student),
                  _buildEducationTab(student),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with student photo, name, and key info
  Widget _buildProfileHeader(Student student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Photo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: DecorationImage(
                image: NetworkImage(student.photoUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.year} ${student.section}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'ID: ${student.registerNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right info card
          Column(
            children: [
              _buildInfoBadge('Reg. Date', student.admissionDate != null
                  ? '${student.admissionDate!.year}-${student.admissionDate!.month.toString().padLeft(2, '0')}'
                  : 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  /// Overview Tab - Key statistics and summaries
  Widget _buildOverviewTab(Student student, AcademicPerformance academic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Academic Summary'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('CGPA', '${student.cgpa ?? 'N/A'}',
                    color: AppTheme.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('SGPA', '${student.sgpa ?? 'N/A'}',
                    color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('Credits',
                    '${student.totalCredits ?? 'N/A'}',
                    color: Color(0xFFF59E0B)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Attendance Summary
          const SectionHeader(title: 'Attendance Summary'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard('Overall', '91.0%',
                    color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('Days Present', '182',
                    color: Color(0xFF06B6D4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard('Days Absent', '18',
                    color: Color(0xFFEF4444)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Summary
          const SectionHeader(title: 'Quick Contact'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildContactRow('Mentor', student.mentor),
                const SizedBox(height: 12),
                _buildContactRow('Mentor Contact', student.mentorContact),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Personal Information Tab
  Widget _buildPersonalTab(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Personal Information'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Gender', student.gender ?? 'N/A'),
            _buildDetailRow('Date of Birth',
                student.dateOfBirth != null
                    ? '${student.dateOfBirth!.day.toString().padLeft(2, '0')}-${student.dateOfBirth!.month.toString().padLeft(2, '0')}-${student.dateOfBirth!.year}'
                    : 'N/A'),
            _buildDetailRow('Blood Group', student.bloodGroup ?? 'N/A'),
            _buildDetailRow('Religion', student.religion ?? 'N/A'),
            _buildDetailRow('Mother Tongue', student.motherTongue ?? 'N/A'),
            _buildDetailRow('Caste Category', student.casteCategory ?? 'N/A'),
            _buildDetailRow('Aadhar Number', student.aadharNumber ?? 'N/A'),
          ]),
        ],
      ),
    );
  }

  /// Academic Information Tab
  Widget _buildAcademicTab(Student student, AcademicPerformance academic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Academic Performance'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('CGPA', '${student.cgpa ?? 'N/A'}'),
            _buildDetailRow('SGPA', '${student.sgpa ?? 'N/A'}'),
            _buildDetailRow('Total Credits', '${student.totalCredits ?? 'N/A'}'),
            _buildDetailRow('Department', student.department),
            _buildDetailRow('Year', student.year),
            _buildDetailRow('Section', student.section),
          ]),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Current Semester'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Current GPA', '${academic.currentGpa}'),
            _buildDetailRow('Semester', academic.currentSemester),
          ]),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Internal Marks'),
          const SizedBox(height: 16),
          ...academic.internalMarks.map((mark) => Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mark.subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMarkBadge('Int1', mark.internal1),
                        _buildMarkBadge('Int2', mark.internal2),
                        _buildMarkBadge('Assign', mark.assignment),
                        _buildMarkBadge('Total', mark.total),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  /// Contact Information Tab
  Widget _buildContactTab(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Contact Information'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Mobile Number', student.mobileNumber ?? 'N/A'),
            _buildDetailRow('Personal Email', student.personalEmail ?? 'N/A'),
            _buildDetailRow('Parent Mobile',
                student.parentMobileNumber ?? 'N/A'),
          ]),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Address'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Current Address',
                student.currentAddress ?? 'N/A'),
            _buildDetailRow('Permanent Address',
                student.permanentAddress ?? 'N/A'),
          ]),
        ],
      ),
    );
  }

  /// Admission Details Tab
  Widget _buildAdmissionTab(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Admission Details'),
          const SizedBox(height: 16),
          _buildDetailCard([
            _buildDetailRow('Register Number', student.registerNumber),
            _buildDetailRow('Admission Date',
                student.admissionDate != null
                    ? '${student.admissionDate!.day}-${student.admissionDate!.month}-${student.admissionDate!.year}'
                    : 'N/A'),
            _buildDetailRow('Admission Type', student.admissionType ?? 'N/A'),
            _buildDetailRow('Admission Mode', student.admissionMode ?? 'N/A'),
            _buildDetailRow('Admission Status',
                student.admissionStatus ?? 'N/A'),
          ]),
        ],
      ),
    );
  }

  /// Education Details Tab
  Widget _buildEducationTab(Student student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (student.isHosteller) ...[
            const SectionHeader(title: 'Hostel Information'),
            const SizedBox(height: 16),
            _buildDetailCard([
              _buildDetailRow('Hostel Name', student.hostelName ?? 'N/A'),
              _buildDetailRow('Room Number', student.roomNumber ?? 'N/A'),
              _buildDetailRow('Warden Name', student.wardenName ?? 'N/A'),
            ]),
            const SizedBox(height: 24),
          ],
          if (student.busNumber != null && student.busNumber!.isNotEmpty) ...[
            const SectionHeader(title: 'Transport Information'),
            const SizedBox(height: 16),
            _buildDetailCard([
              _buildDetailRow('Bus Number', student.busNumber ?? 'N/A'),
              _buildDetailRow('Route', student.route ?? 'N/A'),
              _buildDetailRow('Pickup Point', student.pickupPoint ?? 'N/A'),
              _buildDetailRow('Pickup Time', student.pickupTime ?? 'N/A'),
            ]),
          ],
        ],
      ),
    );
  }

  /// Helper widget: Info Card with colored background
  Widget _buildInfoCard(String label, String value, {required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget: Info Badge
  Widget _buildInfoBadge(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Helper widget: Contact Row
  Widget _buildContactRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Helper widget: Detail Card containing multiple rows
  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: List.generate(
          children.length,
          (index) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: children[index],
              ),
              if (index < children.length - 1)
                Divider(height: 0, color: Colors.grey.shade100),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget: Detail Row
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  /// Helper widget: Mark Badge
  Widget _buildMarkBadge(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentColor,
            ),
          ),
        ),
      ],
    );
  }
}
