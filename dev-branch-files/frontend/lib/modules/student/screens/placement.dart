import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';

class PlacementScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const PlacementScreen({super.key, this.onNavigate});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  bool _showAllDrives = false;

  void _downloadJobDescription(PlacementDriveModel drive) {
    try {
      final jdText = '''
==================================================
              JOB DESCRIPTION
==================================================
Company: ${drive.company}
Role: ${drive.role}
CTC / Package: ${drive.ctc}
Registration Deadline: ${drive.deadline}
Minimum CGPA Required: ${drive.minCgpa}

Eligibility Criteria:
- B.E / B.Tech (All Branches / Specified Branches)
- Minimum CGPA: ${drive.minCgpa}
- No Active Backlogs

Job Description Summary:
We are looking for exceptional student engineers to join our engineering and product teams. You will work on building, scale, and deployment of cloud applications, algorithms, and system integrations.

How to Apply:
Please register using the "Register" button on the placement portal. Your profile and digital resume will be instantly dispatched to the HR team.
==================================================
''';
      final bytes = utf8.encode(jdText);
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final filename = 'JD_${drive.company.replaceAll(' ', '_')}.pdf';
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$filename downloaded successfully!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading JD for ${drive.company}'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _applyPlacementDrive(PlacementDriveModel drive, AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Apply for ${drive.company}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Role: ${drive.role}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              Text('Package: ${drive.ctc}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text('Drive Date: ${drive.date}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              Text('Minimum CGPA Required: ${drive.minCgpa} (Your CGPA: )'),
              const SizedBox(height: 8),
              const Text('Are you sure you want to submit your profile & resume to this company?', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                appState.applyPlacement(drive.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Applied for ${drive.company} successfully! Resume dispatched to HR.'), backgroundColor: const Color(0xFF16A34A)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Confirm Application', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showInterviewRoundModal(String roundName, String status) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('$roundName Details', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: $status', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              const SizedBox(height: 8),
              const Text('Venue: Placement Cell Room 102'),
              const Text('Time: 10:00 AM - 12:00 PM'),
              const SizedBox(height: 8),
              const Text('Panel Members: HR Director & Tech Lead'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final drives = appState.placements;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isTablet = MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Top Info Row (Readiness, Interview, Resources)
          if (isDesktop)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _buildPlacementReadiness(true)),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: _buildInterviewStatus()),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: _buildPlacementResources()),
                ],
              ),
            )
          else if (isTablet)
            Column(
              children: [
                _buildPlacementReadiness(false),
                const SizedBox(height: 20),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildInterviewStatus()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildPlacementResources()),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildPlacementReadiness(false),
                const SizedBox(height: 20),
                _buildInterviewStatus(),
                const SizedBox(height: 20),
                _buildPlacementResources(),
              ],
            ),
          const SizedBox(height: 24),

          // Access Placement Portal Card
          InkWell(
            onTap: () {
              html.window.open('https://placement--portal.vercel.app', '_blank');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final content = Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.launch, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Access Placement Portal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Visit the full placement portal for job listings, applications & more',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBFDBFE),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom drives list
          _buildDrivesSection(drives, appState),
        ],
      ),
    );
  }

  Widget _buildPlacementReadiness(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: circular indicator & text details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular progress
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 0,
                        strokeWidth: 9,
                        backgroundColor: const Color(0xFFEFF6FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Placement Readiness',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.trending_up, color: Color(0xFF2563EB), size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Based on CGPA, achievements and course completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal progress bar under the description
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.78,
              minHeight: 6,
              backgroundColor: Color(0xFFEFF6FF),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 20),
          // Horizontal row (or stacked on mobile) of 4 Metrics cards
          Builder(
            builder: (context) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final double cardSpacing = 12.0;

              Widget buildCard(int index) {
                if (index == 0) {
                  return _buildReadinessGridCard(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                    label: 'CGPA',
                    value: '',
                    suffix: ' /10',
                    subtitle: '',
                  );
                } else if (index == 1) {
                  return _buildReadinessGridCard(
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
                    label: 'Backlogs',
                    value: '',
                    subtitle: '',
                  );
                } else if (index == 2) {
                  return _buildReadinessGridCard(
                    icon: Icons.work_outline,
                    iconColor: const Color(0xFF9333EA),
                    bgColor: const Color(0xFFF3E8FF),
                    label: 'Eligible Drives',
                    value: '',
                    subtitle: '',
                  );
                } else {
                  return _buildReadinessGridCard(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFFEA580C),
                    bgColor: const Color(0xFFFFF7ED),
                    label: 'Placed Status',
                    value: '',
                    subtitle: '',
                  );
                }
              }

              if (screenWidth >= 1200) {
                // Desktop: nesting inside IntrinsicHeight limits card width. Display as 2x2 grid.
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: buildCard(0)),
                        SizedBox(width: cardSpacing),
                        Expanded(child: buildCard(1)),
                      ],
                    ),
                    SizedBox(height: cardSpacing),
                    Row(
                      children: [
                        Expanded(child: buildCard(2)),
                        SizedBox(width: cardSpacing),
                        Expanded(child: buildCard(3)),
                      ],
                    ),
                  ],
                );
              } else if (screenWidth >= 768) {
                // Tablet: full screen width available. Display single row of 4.
                return Row(
                  children: [
                    Expanded(child: buildCard(0)),
                    SizedBox(width: cardSpacing),
                    Expanded(child: buildCard(1)),
                    SizedBox(width: cardSpacing),
                    Expanded(child: buildCard(2)),
                    SizedBox(width: cardSpacing),
                    Expanded(child: buildCard(3)),
                  ],
                );
              } else if (screenWidth > 480) {
                // Large Mobile: 2x2 grid.
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: buildCard(0)),
                        SizedBox(width: cardSpacing),
                        Expanded(child: buildCard(1)),
                      ],
                    ),
                    SizedBox(height: cardSpacing),
                    Row(
                      children: [
                        Expanded(child: buildCard(2)),
                        SizedBox(width: cardSpacing),
                        Expanded(child: buildCard(3)),
                      ],
                    ),
                  ],
                );
              } else {
                // Small Mobile: Single vertical list.
                return Column(
                  children: [
                    buildCard(0),
                    SizedBox(height: cardSpacing),
                    buildCard(1),
                    SizedBox(height: cardSpacing),
                    buildCard(2),
                    SizedBox(height: cardSpacing),
                    buildCard(3),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadinessGridCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    String? suffix,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: iconColor),
                    children: suffix != null
                        ? [
                            TextSpan(
                              text: suffix,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                            ),
                          ]
                        : [],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewStatus() {
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Placement Tracker on left, Update Profile on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Placement Tracker',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Update Profile',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Four circular progress indicators row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTrackerCircle('', 'Dream\nCompanies', const Color(0xFF8B5CF6)),
              _buildTrackerCircle('', 'Applied\nRoles', const Color(0xFF3B82F6)),
              _buildTrackerCircle('', 'Shortlisted', const Color(0xFFFBBF24)),
              _buildTrackerCircle('', 'Interview', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 20),
          // Blue info alert box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.4,
                      color: const Color(0xFF1E40AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Detailed TCS email container
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: Color(0xFF475569)),
                          SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 4),
                    Text('Today, 10:30 AM', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
                  ],
                ),
                const Divider(height: 16),
                const Text(
                  'Subject: Interview Schedule - ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.3),
                ),
                const SizedBox(height: 8),
                buildEmailDetailRow('Date', ''),
                buildEmailDetailRow('Time', ''),
                buildEmailDetailRow('Mode', ''),
                buildEmailDetailRow('Round', ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerCircle(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPlacementResources() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                child: const Icon(Icons.library_books_outlined, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Placement Resources',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResourceRow(Icons.description_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'Resume Builder', 'Create & improve your resume'),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildResourceRow(Icons.lightbulb_outline, const Color(0xFF16A34A), const Color(0xFFF0FDF4), 'Aptitude Preparation', 'Practice aptitude questions'),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildResourceRow(Icons.people_outline, const Color(0xFF16A34A), const Color(0xFFF0FDF4), 'Mock Interviews', 'Improve your interview skills'),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildResourceRow(Icons.gavel_outlined, const Color(0xFFDC2626), const Color(0xFFFEF2F2), 'Placement Guidelines', 'Tips & preparation strategy'),
        ],
      ),
    );
  }

  Widget _buildResourceRow(IconData icon, Color color, Color bgColor, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
      ],
    );
  }

  Widget _buildCompanyLogo(String company) {
    if (company.contains('Google')) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'G',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFFDB4437), // Google Red
          ),
        ),
      );
    } else if (company.contains('Microsoft')) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.all(6),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(color: const Color(0xFFF25022)),
            Container(color: const Color(0xFF7FBA00)),
            Container(color: const Color(0xFF00A4EF)),
            Container(color: const Color(0xFFFFB900)),
          ],
        ),
      );
    } else {
      // Build initials from company name
      final words = company.trim().split(RegExp(r'\s+'));
      final initials = words.length >= 2
          ? '${words[0][0]}${words[1][0]}'.toUpperCase()
          : company.substring(0, company.length.clamp(0, 3)).toUpperCase();
      // Pick a color based on company name hash
      final colors = [
        const Color(0xFF1D4ED8), const Color(0xFF16A34A), const Color(0xFF9333EA),
        const Color(0xFFDC2626), const Color(0xFFEA580C), const Color(0xFF0891B2),
      ];
      final col = colors[company.codeUnits.fold(0, (a, b) => a + b) % colors.length];
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: col.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: col,
          ),
        ),
      );
    }
  }


  Widget _buildDrivesSection(List<PlacementDriveModel> drives, AppState appState) {
    final displayList = List<PlacementDriveModel>.from(drives);
    final displayedDrives = _showAllDrives ? displayList : displayList.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Upcoming Placement Drives',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showAllDrives = !_showAllDrives;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_showAllDrives ? 'Show Less' : 'View All Drives', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Scrollable Table for responsiveness
          LayoutBuilder(
            builder: (context, constraints) {
              final tableContent = Column(
                children: [
                  // Table Headers
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Company', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 4, child: Text('Eligibility', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 2, child: Text('CTC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 3, child: Text('Registration Deadline', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        Expanded(flex: 3, child: Text('Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      ],
                    ),
                  ),
                  // Table Rows
                  if (displayedDrives.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      child: const Text(
                        'No placement drives found in database.',
                        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    ...displayedDrives.map((drive) {
                    // Customize deadline text colors to RED exactly matching the image
                    Color deadlineColor = const Color(0xFFDC2626); 

                    // Map custom text details
                    String branches = 'B.E / B.Tech - CSE, IT, ECE';
                    if (drive.company.contains('Microsoft')) {
                      branches = 'B.E / B.Tech - CSE, IT, ECE, EEE';
                    } else if (drive.company.contains('TCS') || drive.company.contains('Wipro') || drive.company.contains('Infosys') || drive.company.contains('Cognizant') || drive.company.contains('Accenture')) {
                      branches = 'B.E / B.Tech - All Branches';
                    }

                    String driveDate = drive.deadline; // visit_date
                    // Format status from drive.status (stage)
                    final stageRaw = drive.status.toLowerCase();
                    String driveDay;
                    if (stageRaw == 'completed') {
                      driveDay = 'Completed';
                      deadlineColor = const Color(0xFF16A34A);
                    } else if (stageRaw == 'scheduled') {
                      driveDay = 'Scheduled';
                      deadlineColor = const Color(0xFF2563EB);
                    } else if (stageRaw == 'ongoing') {
                      driveDay = 'Ongoing';
                      deadlineColor = const Color(0xFFEA580C);
                    } else if (stageRaw == 'cancelled') {
                      driveDay = 'Cancelled';
                      deadlineColor = const Color(0xFF94A3B8);
                    } else {
                      driveDay = drive.status;
                    }

                    String deadlineDate = drive.deadline;
                    String deadlineDaysLeft = '(${drive.status})';


                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Company column
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                _buildCompanyLogo(drive.company),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(drive.company, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Text(drive.role, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Eligibility
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(branches, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                                const SizedBox(height: 2),
                                Text(
                                  'CGPA >= ${drive.minCgpa} | No Active Backlogs',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          // Date
                          Expanded(
                            flex: 3,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF2563EB)),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      driveDate,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      driveDay,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // CTC
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  drive.ctc.isNotEmpty ? drive.ctc : 'N/A',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                const Text('Annual Package', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          // Deadline
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  deadlineDate,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: deadlineColor),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  deadlineDaysLeft,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: deadlineColor),
                                ),
                              ],
                            ),
                          ),
                          // Action
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: drive.isApplied ? null : () => _applyPlacementDrive(drive, appState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      drive.isApplied ? 'Applied' : 'Register',
                                      style: TextStyle(
                                        color: drive.isApplied ? const Color(0xFF94A3B8) : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: IconButton(
                                    onPressed: () => _downloadJobDescription(drive),
                                    icon: const Icon(Icons.download, size: 14, color: Color(0xFF2563EB)),
                                    tooltip: 'Download Job Description',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
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

              if (constraints.maxWidth < 950) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 950,
                    child: tableContent,
                  ),
                );
              } else {
                return tableContent;
              }
            },
          ),
        ],
      ),
    );
  }
}
