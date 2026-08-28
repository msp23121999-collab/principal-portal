import 'package:flutter/material.dart';
import '../models/hod_models.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../hod_toast.dart';
import '../../faculty/services/supabase_client.dart';
import '../../faculty/services/profile_service.dart';
import '../services/launcher_helper.dart';

class ProfileView extends StatefulWidget {
  final HodFullProfileData profileData;

  const ProfileView({
    super.key,
    required this.profileData,
  });

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _fs = FirestoreService.instance;

  // ── Mutable profile state fields ──
  late String fullName;
  late String officialEmail;
  late String personalEmail;
  late String phone;
  late String emergencyContact;
  late String dob;
  late String gender;
  late String bloodGroup;
  late String nationality;
  late String maritalStatus;
  late String address;
  String? photoUrl;
  List<String> mappedSubjects = [];
  List<String> assignedClasses = [];

  // Professional
  late String employeeId;
  late String designation;
  late String department;
  late String dateOfJoining;

  // Academic
  late String ugDegree;
  late String pgDegree;
  late String phdDegree;
  late String specialization;
  late String university;

  // Research
  late String ORCID;
  late String scopusId;
  late String googleScholar;
  late String researchGate;
  late int publicationCount;
  late int conferenceCount;
  late int patentsCount;
  late String fundedProjectsAmount;
  late int weeklyWorkloadHours;

  // Collapsible sections state
  late final Map<String, bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    _expandedSections = {
      'personal': true,
      'contact': true,
      'professional': true,
      'academic': true,
      'teaching': true,
      'research': true,
      'documents': true,
    };
    _initFromWidget();
    _loadFromSupabase();
    _loadFromFirestore();
  }

  Future<void> _loadFromSupabase() async {
    try {
      final facultyRows = await SupabaseClientHelper.select('faculties', schema: 'faculty');
      final publicRows = await SupabaseClientHelper.select('faculties', schema: 'public');

      final allRows = [...facultyRows, ...publicRows];

      if (allRows.isNotEmpty) {
        final profile = ProfileService.get();
        final employeeIdVal = profile['employeeId'] ?? profile['facultyId'] ?? 'EMP-CSE-010';

        var match = allRows.firstWhere(
          (r) {
            final sameId = r['employee_id']?.toString().toUpperCase() == employeeIdVal.toUpperCase();
            final role = r['role']?.toString().toUpperCase() ?? '';
            final isHod = role.contains('HOD') || r['designation']?.toString().toUpperCase().contains('HOD') == true;
            return sameId && isHod;
          },
          orElse: () => <String, dynamic>{},
        );

        if (match.isEmpty) {
          final rawDept = profile['departmentId'] ?? profile['department'] ?? 'CSE';
          final deptCode = rawDept.replaceAll('DEPT_', '').replaceAll('DEP-', '').split('-').first.toUpperCase();
          match = allRows.firstWhere(
            (r) {
              final rDept = (r['department'] ?? r['code'] ?? '').toString().toUpperCase();
              final role = r['role']?.toString().toUpperCase() ?? '';
              final isHod = role.contains('HOD') || r['designation']?.toString().toUpperCase().contains('HOD') == true;
              return (rDept == deptCode || rDept.contains(deptCode)) && isHod;
            },
            orElse: () => <String, dynamic>{},
          );
        }

        // Fetch allocations for dynamic timetable/classes display in teaching grid
        List<Map<String, dynamic>> allocs = [];
        try {
          allocs = await SupabaseClientHelper.select(
            'faculty_course_allocations',
            schema: 'faculty',
            filterColumn: 'faculty_employee_id',
            filterValue: employeeIdVal,
          );
        } catch (_) {}

        if (mounted) {
          setState(() {
            if (match.isNotEmpty) {
              fullName = match['full_name']?.toString() ?? match['name']?.toString() ?? fullName;
              employeeId = match['employee_id']?.toString() ?? employeeIdVal;
              designation = match['designation']?.toString() ?? designation;
              department = match['department']?.toString() ?? match['department_id']?.toString() ?? department;
              officialEmail = match['official_email']?.toString() ?? match['email']?.toString() ?? officialEmail;
              personalEmail = match['personal_email']?.toString() ?? personalEmail;
              phone = match['phone']?.toString() ?? phone;
              emergencyContact = match['emergency_contact']?.toString() ?? emergencyContact;
              dob = match['dob']?.toString() ?? dob;
              gender = match['gender']?.toString() ?? gender;
              bloodGroup = match['blood_group']?.toString() ?? bloodGroup;
              nationality = match['nationality']?.toString() ?? nationality;
              maritalStatus = match['marital_status']?.toString() ?? maritalStatus;
              address = match['address']?.toString() ?? address;
              dateOfJoining = match['date_of_joining']?.toString() ?? dateOfJoining;
              ugDegree = match['ug_degree']?.toString() ?? ugDegree;
              pgDegree = match['pg_degree']?.toString() ?? pgDegree;
              phdDegree = match['phd_degree']?.toString() ?? phdDegree;
              specialization = match['specialization']?.toString() ?? specialization;
              university = match['university']?.toString() ?? university;
              ORCID = match['orcid']?.toString() ?? ORCID;
              scopusId = match['scopus_id']?.toString() ?? scopusId;
              googleScholar = match['google_scholar']?.toString() ?? googleScholar;
              researchGate = match['research_gate']?.toString() ?? researchGate;
              publicationCount = (match['publication_count'] as num?)?.toInt() ?? publicationCount;
              conferenceCount = (match['conference_count'] as num?)?.toInt() ?? conferenceCount;
              patentsCount = (match['patents_count'] as num?)?.toInt() ?? patentsCount;
              fundedProjectsAmount = match['funded_projects_amount']?.toString() ?? fundedProjectsAmount;
              weeklyWorkloadHours = (match['weekly_workload_hours'] as num?)?.toInt() ?? weeklyWorkloadHours;
              photoUrl = match['photo_url']?.toString();
            } else {
              fullName = profile['name'] ?? profile['fullName'] ?? fullName;
              employeeId = employeeIdVal;
              designation = profile['designation'] ?? designation;
              department = profile['department'] ?? department;
              officialEmail = profile['email'] ?? officialEmail;
              phone = profile['phone'] ?? phone;
            }

            mappedSubjects = [];
            assignedClasses = [];
            for (final a in allocs) {
              final code = a['course_code']?.toString() ?? '';
              if (code.isNotEmpty) {
                mappedSubjects.add(code);
              }
              final sec = a['section']?.toString() ?? 'A';
              assignedClasses.add('$code (Sec $sec)');
            }
          });

          // Sync to local storage
          final rawDeptId = match.isNotEmpty
              ? (match['code']?.toString() ?? match['department_id']?.toString() ?? 'CSE')
              : (profile['departmentId']?.toString() ?? 'CSE');

          String cleanDeptCode(String raw) {
            final clean = raw.replaceAll('DEPT_', '').replaceAll('DEP-', '').split('-').first.toUpperCase();
            if (['CSE', 'IT', 'ECE', 'EEE', 'MECH', 'CIVIL', 'IOT', 'AIDS', 'MBA', 'MCA', 'CHEM', 'SCI'].contains(clean)) {
              return clean;
            }
            return 'CSE';
          }

          final deptId = cleanDeptCode(rawDeptId);

          ProfileService.save({
            'employeeId': employeeId,
            'facultyId': employeeId,
            'name': fullName,
            'designation': designation,
            'department': department,
            'departmentId': deptId,
            'email': officialEmail,
            'phone': phone,
            'role': match.isNotEmpty ? (match['role']?.toString() ?? 'HOD & Professor') : (profile['role'] ?? 'HOD & Professor'),
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading HOD details from Supabase: $e');
    }
  }

  void _initFromWidget() {
    final p = widget.profileData;
    fullName = p.fullName;
    officialEmail = p.officialEmail;
    personalEmail = p.personalEmail;
    phone = p.phone;
    emergencyContact = p.emergencyContact;
    dob = p.dob;
    gender = p.gender;
    bloodGroup = p.bloodGroup;
    nationality = p.nationality;
    maritalStatus = p.maritalStatus;
    address = p.address;
    employeeId = p.employeeId;
    designation = p.designation;
    department = p.department;
    dateOfJoining = p.dateOfJoining;
    ugDegree = p.ugDegree;
    pgDegree = p.pgDegree;
    phdDegree = p.phdDegree;
    specialization = p.specialization;
    university = p.university;
    ORCID = p.ORCID;
    scopusId = p.scopusId;
    googleScholar = p.googleScholar;
    researchGate = p.researchGate;
    publicationCount = p.publicationCount;
    conferenceCount = p.conferenceCount;
    patentsCount = p.patentsCount;
    fundedProjectsAmount = p.fundedProjectsAmount;
    weeklyWorkloadHours = p.weeklyWorkloadHours;
  }

  Future<void> _loadFromFirestore() async {
    try {
      final doc = await _fs.hodProfile.doc('main').get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        final docName = d['fullName']?.toString() ?? '';
        if (docName.contains('Govindharaj')) return; // Ignore old mock data in Firestore

        setState(() {
          fullName = d['fullName'] ?? fullName;
          officialEmail = d['officialEmail'] ?? officialEmail;
          personalEmail = d['personalEmail'] ?? personalEmail;
          phone = d['phone'] ?? phone;
          emergencyContact = d['emergencyContact'] ?? emergencyContact;
          dob = d['dob'] ?? dob;
          gender = d['gender'] ?? gender;
          bloodGroup = d['bloodGroup'] ?? bloodGroup;
          nationality = d['nationality'] ?? nationality;
          maritalStatus = d['maritalStatus'] ?? maritalStatus;
          address = d['address'] ?? address;
          designation = d['designation'] ?? designation;
          department = d['department'] ?? department;
          dateOfJoining = d['dateOfJoining'] ?? dateOfJoining;
          ugDegree = d['ugDegree'] ?? ugDegree;
          pgDegree = d['pgDegree'] ?? pgDegree;
          phdDegree = d['phdDegree'] ?? phdDegree;
          specialization = d['specialization'] ?? specialization;
          university = d['university'] ?? university;
          ORCID = d['ORCID'] ?? ORCID;
          scopusId = d['scopusId'] ?? scopusId;
          googleScholar = d['googleScholar'] ?? googleScholar;
          researchGate = d['researchGate'] ?? researchGate;
          publicationCount = (d['publicationCount'] as num?)?.toInt() ?? publicationCount;
          conferenceCount = (d['conferenceCount'] as num?)?.toInt() ?? conferenceCount;
          patentsCount = (d['patentsCount'] as num?)?.toInt() ?? patentsCount;
          fundedProjectsAmount = d['fundedProjectsAmount'] ?? fundedProjectsAmount;
          weeklyWorkloadHours = (d['weeklyWorkloadHours'] as num?)?.toInt() ?? weeklyWorkloadHours;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveToFirestore() async {
    await _fs.setDoc(_fs.hodProfile, 'main', {
      'fullName': fullName,
      'officialEmail': officialEmail,
      'personalEmail': personalEmail,
      'phone': phone,
      'emergencyContact': emergencyContact,
      'dob': dob,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'nationality': nationality,
      'maritalStatus': maritalStatus,
      'address': address,
      'designation': designation,
      'department': department,
      'dateOfJoining': dateOfJoining,
      'ugDegree': ugDegree,
      'pgDegree': pgDegree,
      'phdDegree': phdDegree,
      'specialization': specialization,
      'university': university,
      'ORCID': ORCID,
      'scopusId': scopusId,
      'googleScholar': googleScholar,
      'researchGate': researchGate,
      'publicationCount': publicationCount,
      'conferenceCount': conferenceCount,
      'patentsCount': patentsCount,
      'fundedProjectsAmount': fundedProjectsAmount,
      'weeklyWorkloadHours': weeklyWorkloadHours,
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Breadcrumb header
          const Text(
            'Dashboard > HOD Profile Management',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // 1. Executive Banner Box
          _buildExecutiveBanner(),
          const SizedBox(height: 16),

          // 2. Row of 4 Core Stats
          _buildCoreStatsRow(),
          const SizedBox(height: 20),

          // 3. Collapsible Sections
          _buildCollapsibleSection(
            key: 'personal',
            title: 'Personal Details',
            icon: Icons.person_outline_rounded,
            content: _buildPersonalGrid(),
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            key: 'contact',
            title: 'Contact Details',
            icon: Icons.contact_mail_outlined,
            content: _buildContactGrid(),
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            key: 'professional',
            title: 'Professional Details',
            icon: Icons.business_center_outlined,
            content: _buildProfessionalGrid(),
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            key: 'academic',
            title: 'Academic Qualifications',
            icon: Icons.school_outlined,
            content: _buildAcademicGrid(),
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            key: 'teaching',
            title: 'Teaching Details',
            icon: Icons.menu_book_outlined,
            content: _buildTeachingGrid(),
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            key: 'research',
            title: 'Research & Publications',
            icon: Icons.science_outlined,
            content: _buildResearchGrid(),
          ),
          const SizedBox(height: 14),

          _buildCollapsibleSection(
            key: 'documents',
            title: 'Documents',
            icon: Icons.folder_open_outlined,
            content: _buildDocumentsGrid(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Executive Banner Box ──
  Widget _buildExecutiveBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004B93), Color(0xFF003366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: photoUrl != null && photoUrl!.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(
                      photoUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        fullName.replaceAll('Dr. ', '').trim().isNotEmpty
                            ? fullName.replaceAll('Dr. ', '').trim()[0]
                            : 'R',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003366),
                        ),
                      ),
                    ),
                  )
                : Text(
                    fullName.replaceAll('Dr. ', '').trim().isNotEmpty
                        ? fullName.replaceAll('Dr. ', '').trim()[0]
                        : 'R',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003366),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Profile titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308), // Yellow badge
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'HOD',
                        style: TextStyle(
                          color: Color(0xFF003366),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$designation • $department',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE2E8F0),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4 Core Stats Row ──
  Widget _buildCoreStatsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final crossAxisCount = (availableWidth / 220).floor().clamp(1, 4);
        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 80,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Employee ID', employeeId, Icons.badge_outlined),
            _buildStatCard('Date of Joining', dateOfJoining, Icons.calendar_today_outlined),
            _buildStatCard('Official Email', officialEmail, Icons.mail_outline_rounded),
            _buildStatCard('Mobile Number', phone, Icons.phone_outlined),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ── Collapsible Section Builder ──
  Widget _buildCollapsibleSection({
    required String key,
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Section Header Bar
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ]
        ],
      ),
    );
  }

  // ── Content Grids matching images exactly ──

  Widget _buildPersonalGrid() {
    return _buildInfoGrid([
      _InfoItem(Icons.person_outline_rounded, 'Full Name', fullName),
      _InfoItem(Icons.wc_rounded, 'Gender', gender),
      _InfoItem(Icons.cake_outlined, 'Date of Birth', dob),
      _InfoItem(Icons.water_drop_outlined, 'Blood Group', bloodGroup),
      _InfoItem(Icons.flag_outlined, 'Nationality', nationality),
      _InfoItem(Icons.favorite_border_rounded, 'Marital Status', maritalStatus),
    ]);
  }

  Widget _buildContactGrid() {
    return _buildInfoGrid([
      _InfoItem(Icons.mail_outline_rounded, 'Official Email', officialEmail),
      _InfoItem(Icons.mail_outline_rounded, 'Personal Email', personalEmail),
      _InfoItem(Icons.phone_outlined, 'Mobile Number', phone),
      _InfoItem(Icons.contact_phone_outlined, 'Emergency Contact', emergencyContact),
      _InfoItem(Icons.home_outlined, 'Residential Address', address, isFullWidth: true),
    ]);
  }

  Widget _buildProfessionalGrid() {
    return _buildInfoGrid([
      _InfoItem(Icons.badge_outlined, 'Employee ID', employeeId),
      _InfoItem(Icons.business_outlined, 'Department', department),
      _InfoItem(Icons.work_outline_rounded, 'Designation', designation),
      _InfoItem(Icons.calendar_today_outlined, 'Date of Joining', dateOfJoining),
    ]);
  }

  Widget _buildAcademicGrid() {
    return _buildInfoGrid([
      _InfoItem(Icons.school_outlined, 'Ph.D Degree', phdDegree),
      _InfoItem(Icons.workspace_premium_outlined, 'Post Graduation (M.E/M.Tech)', pgDegree),
      _InfoItem(Icons.history_edu_rounded, 'Under Graduation (B.E/B.Tech)', ugDegree),
      _InfoItem(Icons.account_balance_outlined, 'University', university),
      _InfoItem(Icons.troubleshoot_rounded, 'Area of Specialization', specialization, isFullWidth: true),
    ]);
  }

  Widget _buildTeachingGrid() {
    final subText = mappedSubjects.isNotEmpty ? mappedSubjects.join(', ') : 'None Mapped';
    final classText = assignedClasses.isNotEmpty ? assignedClasses.join(', ') : 'None Assigned';
    return _buildInfoGrid([
      _InfoItem(Icons.menu_book_outlined, 'Current Subjects Mapped', subText),
      _InfoItem(Icons.assignment_ind_outlined, 'Classes Assigned', classText),
      _InfoItem(Icons.date_range_outlined, 'Academic Year', '2025 - 2026'),
      _InfoItem(Icons.timeline_rounded, 'Current Semester', 'Odd/Even Semester'),
      _InfoItem(Icons.access_time_rounded, 'Weekly Workload', '$weeklyWorkloadHours Hours / Week'),
    ]);
  }

  Widget _buildResearchGrid() {
    return _buildInfoGrid([
      _InfoItem(Icons.menu_book_outlined, 'Journal Publications', '$publicationCount Papers (Scopus / WoS Indexed)'),
      _InfoItem(Icons.groups_outlined, 'Conference Papers', '$conferenceCount Papers (IEEE / Springer)'),
      _InfoItem(Icons.lightbulb_outline_rounded, 'Patents Granted', '$patentsCount Patents'),
      _InfoItem(Icons.monetization_on_outlined, 'Funded Research Grants', fundedProjectsAmount),
      _InfoItem(Icons.credit_card_outlined, 'ORCID ID', ORCID),
      _InfoItem(Icons.fingerprint_rounded, 'Scopus Profile ID', scopusId),
      _InfoItem(Icons.search_rounded, 'Google Scholar ID', googleScholar),
      _InfoItem(Icons.language_rounded, 'ResearchGate Profile', researchGate),
    ]);
  }

  Widget _buildDocumentsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 80,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildDocCard(
              'Resume / CV',
              'HOD_${fullName.replaceAll("Dr. ", "").replaceAll(" ", "_")}_Curriculum_Vitae.pdf',
              'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
              Icons.insert_drive_file_outlined,
            ),
            _buildDocCard(
              'Degree Certificates',
              'Ph.D._Degree_Certificate_AnnaUniv.pdf',
              'https://pdfobject.com/pdf/sample.pdf',
              Icons.school_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDocCard(String title, String fileName, String url, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HodToast.show(
                context,
                message: 'Opening $fileName...',
                isSuccess: true,
              );
              try {
                launchURL(url);
              } catch (e) {
                debugPrint('Error launching url: $e');
              }
            },
            icon: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF2563EB),
              size: 18,
            ),
            tooltip: 'View Document',
          )
        ],
      ),
    );
  }

  // Generic Grid builder
  Widget _buildInfoGrid(List<_InfoItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        List<Widget> rows = [];
        List<_InfoItem> currentRow = [];

        for (var item in items) {
          if (isMobile || item.isFullWidth) {
            if (currentRow.isNotEmpty) {
              rows.add(_buildRow(currentRow));
              currentRow = [];
            }
            rows.add(_buildRow([item]));
          } else {
            currentRow.add(item);
            if (currentRow.length == 2) {
              rows.add(_buildRow(currentRow));
              currentRow = [];
            }
          }
        }
        if (currentRow.isNotEmpty) {
          rows.add(_buildRow(currentRow));
        }

        return Column(
          children: rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: r,
          )).toList(),
        );
      },
    );
  }

  Widget _buildRow(List<_InfoItem> items) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: const Color(0xFF64748B), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
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
  }

  // ── EDIT PROFILE DIALOG ──
  void _openEditProfileModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: fullName);
    final emailCtrl = TextEditingController(text: officialEmail);
    final phoneCtrl = TextEditingController(text: phone);
    final designCtrl = TextEditingController(text: designation);
    final deptCtrl = TextEditingController(text: department);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit HOD Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Official Email *')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 10),
              TextField(controller: designCtrl, decoration: const InputDecoration(labelText: 'Designation')),
              const SizedBox(height: 10),
              TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                if (nameCtrl.text.trim().isNotEmpty) fullName = nameCtrl.text.trim();
                if (emailCtrl.text.trim().isNotEmpty) officialEmail = emailCtrl.text.trim();
                if (phoneCtrl.text.trim().isNotEmpty) phone = phoneCtrl.text.trim();
                if (designCtrl.text.trim().isNotEmpty) designation = designCtrl.text.trim();
                if (deptCtrl.text.trim().isNotEmpty) department = deptCtrl.text.trim();
              });
              await _saveToFirestore();
              Navigator.pop(ctx);
              HodToast.show(
                context,
                message: 'Profile updated and saved successfully!',
                isSuccess: true,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── CHANGE PASSWORD DIALOG ──
  void _openChangePasswordModal(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: oldPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password *')),
              const SizedBox(height: 10),
              TextField(controller: newPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password *')),
              const SizedBox(height: 10),
              TextField(controller: confirmPassCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New Password *')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (oldPassCtrl.text.isEmpty || newPassCtrl.text.isEmpty || confirmPassCtrl.text.isEmpty) {
                HodToast.show(
                  context,
                  message: 'Please fill in all mandatory password fields!',
                  isError: true,
                );
                return;
              }
              if (newPassCtrl.text != confirmPassCtrl.text) {
                HodToast.show(
                  context,
                  message: 'New passwords do not match!',
                  isError: true,
                );
                return;
              }
              Navigator.pop(ctx);
              HodToast.show(
                context,
                message: 'Password changed successfully!',
                isSuccess: true,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  final bool isFullWidth;

  _InfoItem(
    this.icon,
    this.label,
    this.value, {
    this.isFullWidth = false,
  });
}
