import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../erp_repository.dart';
import '../services/course_allocation_service.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  final repo = ErpRepository();
  late TabController _tabController;

  // Controllers for editing personal details
  late TextEditingController _nameCtrl;
  late TextEditingController _empIdCtrl;
  late TextEditingController _deptCtrl;
  late TextEditingController _staffTypeCtrl;
  late TextEditingController _dojCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _bloodGroupCtrl;
  late TextEditingController _emergencyContactCtrl;

  // Professional Controllers
  late TextEditingController _qualificationCtrl;
  late TextEditingController _specializationCtrl;
  late TextEditingController _experienceCtrl;
  late TextEditingController _employmentTypeCtrl;
  late TextEditingController _facultyTypeCtrl;
  late TextEditingController _reportingHodCtrl;

  // Academic Controllers
  late TextEditingController _assignedSubjectsCtrl;
  late TextEditingController _assignedClassesCtrl;
  late TextEditingController _semesterHandlingCtrl;
  late TextEditingController _sectionHandlingCtrl;
  late TextEditingController _academicYearCtrl;

  // Password Controllers
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  // Designation Change Request State
  Map<String, dynamic>? _designationRequest;
  bool _isDesignationEditable = false;
  bool _twoFactorEnabled = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _nameCtrl = TextEditingController(
      text: repo.profile['name'] ?? repo.profile['full_name'] ?? '',
    );
    _empIdCtrl = TextEditingController(
      text: repo.profile['employeeId'] ?? repo.profile['employee_id'] ?? '',
    );
    _deptCtrl = TextEditingController(
      text: repo.profile['department'] ?? repo.profile['dept'] ?? '',
    );
    _staffTypeCtrl = TextEditingController(
      text: repo.profile['staffType'] ?? repo.profile['staff_type'] ?? '',
    );
    _dojCtrl = TextEditingController(
      text:
          repo.profile['dateOfJoining'] ??
          repo.profile['date_of_joining'] ??
          '',
    );
    _designationCtrl = TextEditingController(
      text: repo.profile['designation'] ?? '',
    );
    _emailCtrl = TextEditingController(
      text: repo.profile['officialEmail'] ?? repo.profile['email'] ?? '',
    );
    _phoneCtrl = TextEditingController(text: repo.profile['phone'] ?? '');
    _addressCtrl = TextEditingController(text: repo.profile['address'] ?? '');
    _dobCtrl = TextEditingController(text: repo.profile['dob'] ?? '');
    _genderCtrl = TextEditingController(text: repo.profile['gender'] ?? '');
    _bloodGroupCtrl = TextEditingController(
      text: repo.profile['bloodGroup'] ?? repo.profile['blood_group'] ?? '',
    );
    _emergencyContactCtrl = TextEditingController(
      text:
          repo.profile['emergencyContact'] ??
          repo.profile['emergency_contact'] ??
          '',
    );

    // Professional
    _qualificationCtrl = TextEditingController(
      text: repo.profile['qualification'] ?? '',
    );
    _specializationCtrl = TextEditingController(
      text: repo.profile['specialization'] ?? '',
    );
    _experienceCtrl = TextEditingController(
      text: repo.profile['experience'] ?? '',
    );
    _employmentTypeCtrl = TextEditingController(
      text:
          repo.profile['employmentType'] ??
          repo.profile['employment_type'] ??
          '',
    );
    _facultyTypeCtrl = TextEditingController(
      text: repo.profile['staffType'] ?? repo.profile['staff_type'] ?? '',
    );
    _reportingHodCtrl = TextEditingController(
      text: repo.profile['hodName'] ?? '',
    );

    // Academic
    _assignedSubjectsCtrl = TextEditingController(
      text:
          (repo.profile['subjects'] is List
              ? (repo.profile['subjects'] as List).join(', ')
              : repo.profile['assignedSubjects']?.toString()) ??
          '',
    );
    _assignedClassesCtrl = TextEditingController(
      text: repo.profile['assignedClasses']?.toString() ?? '',
    );
    _semesterHandlingCtrl = TextEditingController(
      text: repo.profile['semesterHandling']?.toString() ?? '',
    );
    _sectionHandlingCtrl = TextEditingController(
      text: repo.profile['sectionHandling']?.toString() ?? '',
    );
    _academicYearCtrl = TextEditingController(text: repo.selectedAcademicYear);

    // Load designation request if available
    if (repo.profile['designationRequest'] is Map) {
      _designationRequest = Map<String, dynamic>.from(
        repo.profile['designationRequest'] as Map,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _empIdCtrl.dispose();
    _deptCtrl.dispose();
    _staffTypeCtrl.dispose();
    _dojCtrl.dispose();
    _designationCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _dobCtrl.dispose();
    _genderCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _emergencyContactCtrl.dispose();

    _qualificationCtrl.dispose();
    _specializationCtrl.dispose();
    _experienceCtrl.dispose();
    _employmentTypeCtrl.dispose();
    _facultyTypeCtrl.dispose();
    _reportingHodCtrl.dispose();

    _assignedSubjectsCtrl.dispose();
    _assignedClassesCtrl.dispose();
    _semesterHandlingCtrl.dispose();
    _sectionHandlingCtrl.dispose();
    _academicYearCtrl.dispose();

    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExecutiveHeader(context),
              const SizedBox(height: 16),
              _buildQuickStatCards(),
              const SizedBox(height: 20),

              // Profile Navigation Tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF64748B),
                  indicator: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.person_outline, size: 16),
                      text: 'Personal Information',
                    ),
                    Tab(
                      icon: Icon(Icons.work_outline, size: 16),
                      text: 'Professional Details',
                    ),
                    Tab(
                      icon: Icon(Icons.school_outlined, size: 16),
                      text: 'Academic Information',
                    ),
                    Tab(
                      icon: Icon(Icons.folder_outlined, size: 16),
                      text: 'Documents',
                    ),
                    Tab(
                      icon: Icon(Icons.security, size: 16),
                      text: 'Account & Security',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  switch (_tabController.index) {
                    case 0:
                      return _buildPersonalTab();
                    case 1:
                      return _buildProfessionalTab();
                    case 2:
                      return _buildAcademicTab();
                    case 3:
                      return _buildDocumentsTab();
                    case 4:
                      return _buildSecurityTab();
                    default:
                      return _buildPersonalTab();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Executive Header Banner ──
  Widget _buildExecutiveHeader(BuildContext context) {
    final String fullName = _nameCtrl.text;
    final String designation =
        repo.profile['designation'] as String? ?? 'Assistant Professor';
    final String department = _deptCtrl.text;
    final String employeeId = _empIdCtrl.text;
    final String officialEmail = _emailCtrl.text;
    final String phone = _phoneCtrl.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B192C), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;
          final isMobile = constraints.maxWidth < 650;

          final avatar = Stack(
            children: [
              Container(
                width: isMobile ? 56 : 68,
                height: isMobile ? 56 : 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF162A45),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: () {
                    final raw = (repo.profile['photoUrl'] as String? ?? '')
                        .trim();
                    final safe =
                        (raw.startsWith('data:image/') ||
                            (raw.startsWith('https://') &&
                                !raw.contains('google.com')))
                        ? raw
                        : '';
                    return safe.isNotEmpty
                        ? Image.network(
                            safe,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Center(
                              child: Text(
                                fullName.isNotEmpty ? fullName[0] : 'F',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 22 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              fullName.isNotEmpty ? fullName[0] : 'F',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 22 : 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                  }(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickAvatarImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );

          final pdfBtn = OutlinedButton.icon(
            onPressed: _downloadProfileTxt,
            icon: const Icon(
              Icons.picture_as_pdf,
              size: 14,
              color: Colors.white70,
            ),
            label: Text(
              'Download Profile (PDF)',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    avatar,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'ACTIVE FACULTY',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF10B981),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$designation • $department',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillBadge(Icons.badge_outlined, 'ID: $employeeId'),
                    _buildPillBadge(Icons.email_outlined, officialEmail),
                    _buildPillBadge(Icons.phone_outlined, phone),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: pdfBtn),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ACTIVE FACULTY',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$designation • $department',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildPillBadge(
                          Icons.badge_outlined,
                          'ID: $employeeId',
                        ),
                        _buildPillBadge(Icons.email_outlined, officialEmail),
                        _buildPillBadge(Icons.phone_outlined, phone),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isNarrow) ...[const SizedBox(width: 16), pdfBtn],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPillBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ── 4 Equal-Sized Summary Cards ──
  Widget _buildQuickStatCards() {
    final exp = (repo.profile['experience'] as String? ?? '').isNotEmpty
        ? repo.profile['experience'].toString()
        : 'No Data';

    final allocSubjs = CourseAllocationService.getAllocatedSubjects();
    final subjs = allocSubjs.isNotEmpty
        ? '${allocSubjs.length} Subjects'
        : 'No Data';

    final allocClasses = CourseAllocationService.getAllocatedClasses();
    final classes = allocClasses.isNotEmpty
        ? '${allocClasses.length} Classes'
        : 'No Data';

    final workloadRaw = (repo.profile['weeklyWorkloadHours'] ?? '').toString();
    final workload = workloadRaw.isNotEmpty && workloadRaw != '0'
        ? '$workloadRaw Hrs / Wk'
        : 'No Data';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final count = constraints.maxWidth < 700 ? 2 : 4;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isMobile ? 2.4 : 3.2,
          children: [
            _buildCompactStatCard(
              'Teaching Experience',
              exp,
              Icons.school_outlined,
              const Color(0xFF2563EB),
            ),
            _buildCompactStatCard(
              'Subjects Assigned',
              subjs,
              Icons.book_outlined,
              const Color(0xFF059669),
            ),
            _buildCompactStatCard(
              'Classes Handling',
              classes,
              Icons.class_outlined,
              const Color(0xFF7C3AED),
            ),
            _buildCompactStatCard(
              'Weekly Workload',
              workload,
              Icons.schedule,
              const Color(0xFFEA580C),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
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
    );
  }

  // ── TAB 1: PERSONAL INFORMATION ──
  Widget _buildPersonalTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Personal Demographics & Contacts',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          // Two Column Information Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _infoTile('Full Legal Name', _nameCtrl.text, icon: Icons.person),
              _infoTile(
                'Employee ID',
                _empIdCtrl.text,
                icon: Icons.badge_outlined,
                isReadOnly: true,
              ),
              _infoTile(
                'Department',
                _deptCtrl.text,
                icon: Icons.business_outlined,
                isReadOnly: true,
              ),
              _infoTile(
                'Designation',
                repo.profile['designation'] as String? ?? 'Assistant Professor',
                icon: Icons.work_outline,
                isReadOnly: true,
              ),
              _infoTile(
                'Official Email',
                _emailCtrl.text,
                icon: Icons.email_outlined,
              ),
              _infoTile(
                'Phone Number',
                _phoneCtrl.text,
                icon: Icons.phone_outlined,
              ),
              _infoTile(
                'Date of Birth',
                _dobCtrl.text,
                icon: Icons.cake_outlined,
              ),
              _infoTile('Gender', _genderCtrl.text, icon: Icons.wc_outlined),
              _infoTile(
                'Blood Group',
                _bloodGroupCtrl.text,
                icon: Icons.bloodtype_outlined,
              ),
              _infoTile(
                'Date of Joining',
                _dojCtrl.text,
                icon: Icons.calendar_today_outlined,
                isReadOnly: true,
              ),
              _infoTile(
                'Emergency Contact',
                _emergencyContactCtrl.text,
                icon: Icons.phone_in_talk_outlined,
              ),
              _infoTile(
                'Residential Address',
                _addressCtrl.text,
                icon: Icons.location_on_outlined,
                isFullWidth: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 2: PROFESSIONAL DETAILS ──
  Widget _buildProfessionalTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.work_outline,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Professional Qualifications & Designation',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _infoTile(
                'Highest Qualification',
                _qualificationCtrl.text,
                icon: Icons.school,
              ),
              _infoTile(
                'Area of Specialization',
                _specializationCtrl.text,
                icon: Icons.psychology_outlined,
              ),
              _infoTile(
                'Teaching Experience',
                _experienceCtrl.text,
                icon: Icons.history_edu,
              ),
              _infoTile(
                'Employment Type',
                _employmentTypeCtrl.text,
                icon: Icons.assignment_ind_outlined,
              ),
              _infoTile(
                'Faculty Type',
                _facultyTypeCtrl.text,
                icon: Icons.badge_outlined,
              ),
              _infoTile(
                'Reporting Authority (HOD)',
                _reportingHodCtrl.text,
                icon: Icons.supervisor_account_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 3: ACADEMIC INFORMATION ──
  Widget _buildAcademicTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Academic & Subject Allocations',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _infoTile(
                'Assigned Subjects',
                _assignedSubjectsCtrl.text,
                icon: Icons.book_outlined,
                isFullWidth: true,
              ),
              _infoTile(
                'Classes Handling',
                _assignedClassesCtrl.text,
                icon: Icons.class_outlined,
              ),
              _infoTile(
                'Semester Handling',
                _semesterHandlingCtrl.text,
                icon: Icons.calendar_view_week_outlined,
              ),
              _infoTile(
                'Section Handling',
                _sectionHandlingCtrl.text,
                icon: Icons.view_headline_outlined,
              ),
              _infoTile(
                'Academic Year',
                _academicYearCtrl.text,
                icon: Icons.event_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TAB 4: DOCUMENTS ──
  Widget _buildDocumentsTab() {
    final docs = [
      {
        'name': 'Faculty Resume / CV',
        'type': 'PDF Document',
        'size': '1.2 MB',
        'status': 'Verified',
      },
      {
        'name': 'Ph.D. / M.E. Degree Certificate',
        'type': 'PDF Document',
        'size': '2.8 MB',
        'status': 'Verified',
      },
      {
        'name': 'Faculty Identity Card Copy',
        'type': 'JPG Image',
        'size': '450 KB',
        'status': 'Verified',
      },
      {
        'name': 'Official Appointment Order',
        'type': 'PDF Document',
        'size': '1.8 MB',
        'status': 'Verified',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 500;
              final uploadBtn = ElevatedButton.icon(
                onPressed: () {
                  repo.triggerNativeUpload((name, size, dataUrl) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Document "$name" uploaded.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.upload_file, size: 14),
                label: Text(
                  'Upload Document',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              );
              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Official Verified Documents',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    uploadBtn,
                  ],
                );
              }
              return Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Official Verified Documents',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  uploadBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          Column(
            children: docs.map((doc) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 380;
                    final statusBadge = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            doc['status']!,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    );
                    final downloadBtn = OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${doc['name']}...'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download, size: 14),
                      label: Text(
                        'Download',
                        style: GoogleFonts.inter(fontSize: 11),
                      ),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                color: Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc['name']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${doc['type']} • ${doc['size']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isNarrow) ...[
                              const SizedBox(width: 8),
                              statusBadge,
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (isNarrow) ...[
                              statusBadge,
                              const SizedBox(width: 8),
                            ],
                            downloadBtn,
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── TAB 5: ACCOUNT & SECURITY ──
  Widget _buildSecurityTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF2563EB), size: 20),
              const SizedBox(width: 8),
              Text(
                'Account Security & Password',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 20),

          // Two Factor Authentication Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.phonelink_lock,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication (2FA)',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Add an extra layer of security to your faculty ERP account using SMS/Email OTP.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _twoFactorEnabled,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) => setState(() => _twoFactorEnabled = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Change Password Section
          Text(
            'Change Account Password',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          _securityField('Current Password *', _currentPwCtrl),
          const SizedBox(height: 12),
          _securityField('New Password *', _newPwCtrl),
          const SizedBox(height: 12),
          _securityField('Confirm New Password *', _confirmPwCtrl),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.vpn_key_outlined, size: 16),
                label: Text(
                  'Update Password',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper Tile Component for Information Cards ──
  Widget _infoTile(
    String label,
    String value, {
    IconData? icon,
    bool isReadOnly = false,
    bool isFullWidth = false,
    Widget? actionWidget,
  }) {
    final displayVal = (value.isNotEmpty && value != '—' && value != 'null')
        ? value
        : 'No Data';
    final isNoData = displayVal == 'No Data';

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = isFullWidth
            ? double.infinity
            : (constraints.maxWidth > 650
                  ? (constraints.maxWidth / 2 - 12)
                  : double.infinity);

        return Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isReadOnly
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: const Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (actionWidget != null) actionWidget,
                ],
              ),
              const SizedBox(height: 6),
              Text(
                displayVal,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isNoData ? FontWeight.normal : FontWeight.w600,
                  color: isNoData
                      ? const Color(0xFF94A3B8)
                      : (isReadOnly
                            ? const Color(0xFF475569)
                            : const Color(0xFF0F172A)),
                  fontStyle: isNoData ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _securityField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  obscureText: true,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF334155),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Designation Approval Workflow Status Banner ──
  Widget _buildDesignationStatusCard() {
    if (_designationRequest == null) return const SizedBox.shrink();

    final status = (_designationRequest!['status'] ?? '').toString();
    final reqDesig = (_designationRequest!['requestedDesignation'] ?? '')
        .toString();
    final reason = (_designationRequest!['reason'] ?? '').toString();
    final remarks = (_designationRequest!['adminRemarks'] ?? '').toString();

    if (status == 'Pending Approval') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top_rounded,
                  size: 16,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                Text(
                  'Designation Change Request: Pending Approval',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Pending Approval',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Requested Designation: "$reqDesig" • Reason: "$reason"',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF78350F),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Workflow Tester: ',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF92400E),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _designationRequest!['status'] = 'Approved';
                      repo.profile['designationRequest'] = _designationRequest;
                      repo.notify();
                    });
                  },
                  child: Text(
                    'Simulate Admin Approval',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _designationRequest!['status'] = 'Rejected';
                      _designationRequest!['adminRemarks'] =
                          'Promotion letter verification pending.';
                      repo.profile['designationRequest'] = _designationRequest;
                      repo.notify();
                    });
                  },
                  child: Text(
                    'Simulate Admin Rejection',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (status == 'Approved') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: Color(0xFF059669),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin/HR approved your designation change to "$reqDesig". You can now edit the field above and save.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF064E3B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'Rejected') {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel_outlined,
              size: 16,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin Remarks: ${remarks.isNotEmpty ? remarks : "Request rejected."}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showDesignationChangeDialog() {
    final reqDesigCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String? attachedFileName;
    int? attachedFileSize;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 480,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Request Designation Change',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Submit an official request to Admin/HR to modify your designation.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Current Designation: ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          repo.profile['designation'] as String? ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Requested Designation *',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reqDesigCtrl,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'e.g. Associate Professor / Senior Professor',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Reason for Change * (Mandatory)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText:
                          'State reason for designation change (e.g. Promotion order / Ph.D. completion)...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Supporting Document (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          repo.triggerNativeUpload((name, size, dataUrl) {
                            setModalState(() {
                              attachedFileName = name;
                              attachedFileSize = size;
                            });
                          });
                        },
                        icon: const Icon(Icons.attach_file, size: 14),
                        label: Text(
                          attachedFileName != null
                              ? 'Change File'
                              : 'Attach File',
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  if (attachedFileName != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              attachedFileName!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (attachedFileSize != null)
                            Text(
                              '${(attachedFileSize! / 1024).toStringAsFixed(1)} KB',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
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
                      ElevatedButton(
                        onPressed: () {
                          final requested = reqDesigCtrl.text.trim();
                          final reason = reasonCtrl.text.trim();

                          if (requested.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter requested designation.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Reason for change is mandatory.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _designationRequest = {
                              'requestedDesignation': requested,
                              'reason': reason,
                              'fileName': attachedFileName,
                              'status': 'Pending Approval',
                              'submittedAt': DateTime.now().toIso8601String(),
                            };
                            repo.profile['designationRequest'] =
                                _designationRequest;
                            repo.notify();
                          });

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Designation change request submitted to Admin/HR for approval.',
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Request',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openEditPersonalModal(BuildContext context) {
    final nameC = TextEditingController(text: _nameCtrl.text);
    final emailC = TextEditingController(text: _emailCtrl.text);
    final phoneC = TextEditingController(text: _phoneCtrl.text);
    final addressC = TextEditingController(text: _addressCtrl.text);
    final dobC = TextEditingController(text: _dobCtrl.text);
    final genderC = TextEditingController(text: _genderCtrl.text);
    final bloodGroupC = TextEditingController(text: _bloodGroupCtrl.text);
    final emergencyC = TextEditingController(text: _emergencyContactCtrl.text);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Personal Details',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                _modalField('Full Name *', nameC),
                const SizedBox(height: 12),
                _modalField('Official Email *', emailC),
                const SizedBox(height: 12),
                _modalField('Phone Number *', phoneC),
                const SizedBox(height: 12),
                _modalField('Date of Birth', dobC),
                const SizedBox(height: 12),
                _modalField('Gender', genderC),
                const SizedBox(height: 12),
                _modalField('Blood Group', bloodGroupC),
                const SizedBox(height: 12),
                _modalField('Emergency Contact', emergencyC),
                const SizedBox(height: 12),
                _modalField('Residential Address', addressC, maxLines: 2),

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
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _nameCtrl.text = nameC.text;
                          _emailCtrl.text = emailC.text;
                          _phoneCtrl.text = phoneC.text;
                          _addressCtrl.text = addressC.text;
                          _dobCtrl.text = dobC.text;
                          _genderCtrl.text = genderC.text;
                          _bloodGroupCtrl.text = bloodGroupC.text;
                          _emergencyContactCtrl.text = emergencyC.text;

                          repo.profile['name'] = nameC.text;
                          repo.profile['email'] = emailC.text;
                          repo.profile['phone'] = phoneC.text;
                          repo.profile['address'] = addressC.text;
                          repo.notify();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Personal profile details updated!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                      child: Text(
                        'Save Changes',
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

  Widget _modalField(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 12),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  void _pickAvatarImage() {
    repo.triggerNativeUpload((name, size, dataUrl) {
      if (size > 2 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo size must not exceed 2 MB.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      setState(() {
        repo.profile['photoUrl'] = dataUrl;
        repo.notify();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated.'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _changePassword() {
    final cur = _currentPwCtrl.text;
    final n = _newPwCtrl.text;
    final conf = _confirmPwCtrl.text;

    if (cur.isEmpty || n.isEmpty || conf.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All password fields are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (n.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (n != conf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    _confirmPwCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadProfileTxt() {
    final sb = StringBuffer();
    sb.writeln('================ FACULTY PROFILE INFORMATION ================');
    sb.writeln('Name: ${_nameCtrl.text}');
    sb.writeln('Employee ID: ${_empIdCtrl.text}');
    sb.writeln('Department: ${_deptCtrl.text}');
    sb.writeln('Designation: ${_designationCtrl.text}');
    sb.writeln('Staff Type: ${_staffTypeCtrl.text}');
    sb.writeln('Date of Joining: ${_dojCtrl.text}');
    sb.writeln('Email: ${_emailCtrl.text}');
    sb.writeln('Phone: ${_phoneCtrl.text}');
    sb.writeln('Address: ${_addressCtrl.text}');
    sb.writeln('Downloaded on: ${DateTime.now().toLocal()}');

    repo.triggerFileDownload(
      'faculty_profile_summary.txt',
      sb.toString(),
      'text/plain',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading profile summary...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
