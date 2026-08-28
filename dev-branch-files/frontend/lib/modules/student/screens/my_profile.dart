// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/app_state.dart';
import '../widgets/student_loading_widget.dart';

class MyProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const MyProfileScreen({super.key, this.onNavigate});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  int _selectedTab = 0;
  bool _settingsAssignmentAlerts = true;
  bool _settingsExamAlerts = true;
  bool _settingsFeeReminders = false;
  bool _settingsBiometricLogin = true;

  @override
  void initState() {
    super.initState();
    if (!AppState.instance.isDataFetched) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppState.instance.fetchAllData();
      });
    }
  }

  final List<String> _tabs = [
    'Overview',
    'Personal',
    'Academic',
    'Family',
    'Documents',
    'Financial',
    'Settings',
  ];

  final List<IconData> _tabIcons = [
    Icons.dashboard_outlined,
    Icons.person_outline,
    Icons.school_outlined,
    Icons.family_restroom_outlined,
    Icons.folder_open_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.settings_outlined,
  ];

  void _showAddressDialog(String address) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Student Address', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            address.isEmpty ? 'No address provided.' : address,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
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

    // Determine missing items dynamic list
    final List<Map<String, String>> missingItems = [];
    if (appState.mobileNumber.isEmpty) {
      missingItems.add({'title': 'Emergency Contact', 'action': 'Add Now'});
    }
    if (appState.personalEmail.isEmpty) {
      missingItems.add({'title': 'Upload Aadhaar', 'action': 'Upload'});
    }
    if (appState.address.isEmpty) {
      missingItems.add({'title': 'Digital Signature', 'action': 'Upload'});
    }

    final bool isProfileComplete = missingItems.isEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 // 2. Profile Summary Banner (2 Cards Layout)
                _buildProfileBanner(appState, isDesktop, isProfileComplete, missingItems),
                SizedBox(height: isDesktop ? 20.0 : 10.0),
 
                // 3. Sub-Navigation Tabs Bar
                _buildTabNavigation(),
                SizedBox(height: isDesktop ? 20.0 : 10.0),
 
                // 4. Tab Content Body
                _buildTabContent(appState, isDesktop, isTablet),
              ],
            ),
          ),

          // 5. Footer
          _buildFooter(),
        ],
      ),
    );
  }

  // --- 1. HEADER ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Manage your personal, academic and admission information.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: const [
            Text(
              'Student Portal',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
            Text(
              'Profile',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
            Text(
              'Overview',
              style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // --- 2. PROFILE BANNER CARD ---
  Widget _buildProfileBanner(AppState appState, bool isDesktop, bool isProfileComplete, List<Map<String, String>> missingItems) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLeftMainProfileCard(appState),
              if (!isProfileComplete) ...[
                const SizedBox(height: 16),
                _buildRightProfileCompletionCard(appState, missingItems),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT MAIN CARD
            Expanded(
              flex: 3,
              child: _buildLeftMainProfileCard(appState),
            ),
            if (!isProfileComplete) ...[
              const SizedBox(width: 16),
              // RIGHT SIDE CARD: Profile Completion (Only shown when not complete)
              Expanded(
                flex: 1,
                child: _buildRightProfileCompletionCard(appState, missingItems),
              ),
            ],
          ],
        );
      },
    );
  }

  // Left Main Profile Card
  Widget _buildLeftMainProfileCard(AppState appState) {
    final photoUrl = appState.getProfileField('photo_url');

    final avatarWidget = Stack(
      children: [
        Builder(builder: (ctx) {
          final name = appState.getProfileField('name', defaultValue: appState.studentName);
          final raw = photoUrl.isNotEmpty
              ? photoUrl
              : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
          final isValid = raw.isNotEmpty &&
              (raw.startsWith('https://') || raw.startsWith('http://')) &&
              !raw.contains('google.com/imgres') &&
              !raw.contains('google.com/search') &&
              (raw.contains('.jpg') || raw.contains('.jpeg') || raw.contains('.png') ||
                  raw.contains('.webp') || raw.contains('unsplash.com') ||
                  raw.contains('supabase') || raw.contains('cloudinary.com'));
          final effectiveUrl = isValid
              ? raw
              : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80';
          return ClipOval(
            child: Image.network(
              effectiveUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                final initials = name.trim().split(' ')
                    .where((p) => p.isNotEmpty)
                    .take(2)
                    .map((p) => p[0].toUpperCase())
                    .join();
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          );
        }),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
            ),
          ),
        ),
      ],
    );

    final detailsWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appState.getProfileField('full_name').isEmpty ? appState.studentName : appState.getProfileField('full_name'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${appState.getProfileField('year_of_study')} Year • ${appState.getProfileField('department')}',
          style: const TextStyle( 
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text('Student ID: ${appState.studentId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const Text('•', style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
            Text('Batch: ${appState.getProfileField('batch')}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ],
    );

    final statsBoxWidget = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 550;
          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildStatColumn('CGPA', appState.getProfileField('cgpa'), const Color(0xFF2563EB))),
                _buildVerticalDivider(),
                Expanded(child: _buildStatColumn('Attendance', '${appState.getProfileField('attendance_percentage')}%', const Color(0xFF16A34A))),
                _buildVerticalDivider(),
                Expanded(child: _buildStatColumn('University Rank', appState.getProfileField('university_rank').isNotEmpty ? appState.getProfileField('university_rank') : '#12', const Color(0xFF8B5CF6))),
                _buildVerticalDivider(),
                Expanded(child: _buildStatColumn('Credits', '${appState.getProfileField('credits_earned').isEmpty ? appState.getProfileField('earned_credits') : appState.getProfileField('credits_earned')} / ${appState.getProfileField('total_credits')}', const Color(0xFF1E293B))),
                _buildVerticalDivider(),
                Expanded(child: _buildStatColumn('Fees Pending', '₹${appState.getProfileField('pending_fees').isEmpty ? appState.getProfileField('pending_fees_total') : appState.getProfileField('pending_fees')}', const Color(0xFFDC2626))),
              ],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatColumn('CGPA', appState.getProfileField('cgpa'), const Color(0xFF2563EB)),
                _buildVerticalDivider(),
                _buildStatColumn('Attendance', '${appState.getProfileField('attendance_percentage')}%', const Color(0xFF16A34A)),
                _buildVerticalDivider(),
                _buildStatColumn('University Rank', appState.getProfileField('university_rank').isNotEmpty ? appState.getProfileField('university_rank') : '#12', const Color(0xFF8B5CF6)),
                _buildVerticalDivider(),
                _buildStatColumn('Credits', '${appState.getProfileField('credits_earned').isEmpty ? appState.getProfileField('earned_credits') : appState.getProfileField('credits_earned')} / ${appState.getProfileField('total_credits')}', const Color(0xFF1E293B)),
                _buildVerticalDivider(),
                _buildStatColumn('Fees Pending', '₹${appState.getProfileField('pending_fees').isEmpty ? appState.getProfileField('pending_fees_total') : appState.getProfileField('pending_fees')}', const Color(0xFFDC2626)),
              ],
            ),
          );
        },
      ),
    );

    final barcodeBoxWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Text('Student Barcode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(24, (index) {
              final isWide = (index % 3 == 0 || index % 7 == 0);
              return Container(
                width: isWide ? 3.5 : 1.5,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                color: const Color(0xFF0F172A),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text('ID: ${appState.getProfileField('qr_code_id')}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobileCard = constraints.maxWidth < 750;
        if (isMobileCard) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  avatarWidget,
                  const SizedBox(width: 14),
                  Expanded(child: detailsWidget),
                ],
              ),
              const SizedBox(height: 16),
              statsBoxWidget,
              const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      barcodeBoxWidget,
                      _buildOutlinedActionButton(Icons.download_outlined, 'Download ID Card'),
                    ],
                  ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatarWidget,
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detailsWidget,
                  const SizedBox(height: 16),
                  statsBoxWidget,
                ],
              ),
            ),
            const SizedBox(width: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                barcodeBoxWidget,
                const SizedBox(width: 12),
                _buildOutlinedActionButton(Icons.download_outlined, 'Download ID Card'),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildOutlinedActionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return SizedBox(
      width: 150,
      child: OutlinedButton.icon(
        onPressed: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloading Student ID Card PDF...')),
          );
        },
        icon: Icon(icon, size: 14, color: const Color(0xFF2563EB)),
        label: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          side: const BorderSide(color: Color(0xFFBFDBFE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  // Right Side Card: Profile Completion Card
  Widget _buildRightProfileCompletionCard(AppState appState, List<Map<String, String>> missingItems) {
    final double completePct = 1.0 - (missingItems.length / 3.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      value: completePct,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      strokeWidth: 4.5,
                    ),
                  ),
                  Text(
                    '${(completePct * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Completion',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completePct,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Missing Fields',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          ...missingItems.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['title']!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => _showEditProfileModal(context, appState),
                      child: Text(
                        item['action']!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // --- 3. SUB-NAVIGATION TABS BAR ---
  Widget _buildTabNavigation() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final spacing = isMobile ? 12.0 : 44.0;
    final horizontalPad = isMobile ? 8.0 : 16.0;
    final verticalPad = isMobile ? 10.0 : 14.0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            final isLast = index == _tabs.length - 1;
            return Padding(
              padding: EdgeInsets.only(right: isLast ? 0.0 : spacing),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _tabIcons[index],
                        size: 19,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _tabs[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- 4. TAB CONTENT BODY ---
  Widget _buildTabContent(AppState appState, bool isDesktop, bool isTablet) {
    if (_selectedTab == 1) {
      final rawAddress = appState.address;
      final addressParts = rawAddress.split(',');
      final formattedAddress = addressParts.length >= 3
          ? '${addressParts[0].trim()},\n${addressParts[1].trim()},\n${addressParts.sublist(2).join(', ').trim()}'
          : rawAddress.replaceAll(', ', ',\n');

      final leftList = [
        _buildTabInfoRow('Student Name', appState.getProfileField('full_name').isEmpty ? appState.studentName : appState.getProfileField('full_name')),
        _buildTabInfoRow('Student ID', appState.studentId),
        _buildTabInfoRow('Register No.', appState.getProfileField('register_no')),
        _buildTabInfoRow('Address', formattedAddress),
        _buildTabInfoRow('Date of Birth & Age', '${appState.getProfileField('dob')} (${appState.getProfileField('age')})'),
        _buildTabInfoRow('Gender', appState.getProfileField('gender')),
        _buildTabInfoRow('Blood Group', appState.getProfileField('blood_group')),
        _buildTabInfoRow('Mobile No.', appState.mobileNumber),
      ];

      final rightList = [
        _buildTabInfoRow('Institute Mail ID', appState.getProfileField('institute_email')),
        _buildTabInfoRow('Personal Email ID', appState.personalEmail),
        _buildTabInfoRow('Community', appState.getProfileField('community')),
        _buildTabInfoRow('Religion', appState.getProfileField('religion')),
        _buildTabInfoRow('Caste', appState.getProfileField('caste')),
        _buildTabInfoRow('Aadhaar No.', appState.getProfileField('aadhaar_no')),
        _buildTabInfoRow('Nationality', appState.getProfileField('nationality')),
        _buildTabInfoRow('Mother Tongue', appState.getProfileField('mother_tongue'), icon: Icons.translate_outlined),
        _buildTabInfoRow('Scholar', appState.getProfileField('scholar_type')),
      ];

      final showTwoColumns = isDesktop || isTablet;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.person, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Personal Profile Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const Divider(height: 24),
            showTwoColumns
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: leftList)),
                      const SizedBox(width: 32),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rightList)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [...leftList, ...rightList],
                  ),
          ],
        ),
      );
    }

    if (_selectedTab == 2) {
      final leftList = [
        _buildTabInfoRow('Application Number', appState.getProfileField('application_no')),
        _buildTabInfoRow('Degree', appState.getProfileField('degree')),
        _buildTabInfoRow('Department', appState.getProfileField('department')),
        _buildTabInfoRow('Batch', appState.getProfileField('batch')),
        _buildTabInfoRow('Date of Admission', appState.getProfileField('date_of_admission')),
        _buildTabInfoRow('Year of Study', appState.getProfileField('year_of_study')),
      ];

      final rightList = [
        _buildTabInfoRow('Sem of Study', appState.getProfileField('semester')),
        _buildTabInfoRow('Section', appState.getProfileField('section')),
        _buildTabInfoRow('Status', appState.getProfileField('status')),
        _buildTabInfoRow('Academic Year', appState.getProfileField('academic_year')),
        _buildTabInfoRow('Semester', appState.getProfileField('semester_type')),
        _buildTabInfoRow('Class Advisor', appState.getProfileField('class_advisor')),
      ];

      final showTwoColumns = isDesktop || isTablet;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.school, color: Color(0xFF2563EB)),
                    SizedBox(width: 10),
                    Text('Academic & Admission Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                const Divider(height: 24),
                showTwoColumns
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: leftList)),
                          const SizedBox(width: 32),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rightList)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [...leftList, ...rightList],
                      ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildEducationDetailsCard(appState),
        ],
      );
    }

    if (_selectedTab == 3) {
      // FAMILY TAB DETAILS (Requested detail layout)
      final familyRows = appState.studentFamilyList.isNotEmpty
          ? appState.studentFamilyList.map((f) => DataRow(cells: [
              DataCell(Text(f['relation']?.toString() ?? '-', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              DataCell(Text(f['full_name']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
              DataCell(Text(f['dob']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
              DataCell(Text(f['mobile_number']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
              DataCell(Text(f['email']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
              DataCell(Text(f['occupation']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
              DataCell(Text(f['annual_income']?.toString() ?? '-', style: const TextStyle(fontSize: 11))),
            ])).toList()
          : const <DataRow>[];

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.family_restroom, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Family & Guardian Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const Divider(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 34,
                dataRowHeight: 40,
                headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Relation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('DOB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Mobile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Occupation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Income', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                rows: familyRows,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTab == 4) {
      // DOCUMENTS TAB DETAILS - Uploaded by Faculty
      final docs = appState.studentDocList.map((d) => {
        'name': d['document_name']?.toString() ?? 'Document',
        'filename': d['file_name']?.toString() ?? 'document.pdf',
        'status': d['verification_status']?.toString() ?? 'Verified',
        'url': d['file_url']?.toString() ?? '',
        'col': (d['verification_status'] == 'Verified' || d['verification_status'] == null) ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
      }).toList();

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: const [
                      Icon(Icons.folder_open_outlined, color: Color(0xFF2563EB)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Educational & Personal Documents',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF1E40AF)),
                      SizedBox(width: 5),
                      Text('Managed by Faculty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (docs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Column(
                    children: const [
                      Icon(Icons.folder_open, size: 48, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text('No documents uploaded by faculty yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('Your verified certificates and documents uploaded by the faculty will appear here.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, idx) => const Divider(),
                itemBuilder: (context, idx) {
                  final d = docs[idx];
                  final nameStr = d['name'] as String;
                  final fileStr = d['filename'] as String;
                  final statusStr = d['status'] as String;
                  final colorVal = d['col'] as Color;
                  final urlStr = d['url'] as String;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nameStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              Text(fileStr, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorVal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusStr,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorVal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.download, size: 18, color: Color(0xFF2563EB)),
                          tooltip: 'Download Document',
                          onPressed: () {
                            if (urlStr.isNotEmpty && (urlStr.startsWith('http://') || urlStr.startsWith('https://'))) {
                              html.AnchorElement(href: urlStr)
                                ..target = '_blank'
                                ..download = fileStr
                                ..click();
                            } else {
                              final content = 'K.S.R. COLLEGE OF ENGINEERING\nOfficial Student Document\nDocument: $nameStr\nFile: $fileStr\nStudent: ${appState.studentName} (${appState.studentId})\nVerification Status: $statusStr';
                              final blob = html.Blob([content], 'text/plain');
                              final blobUrl = html.Url.createObjectUrlFromBlob(blob);
                              html.AnchorElement(href: blobUrl)
                                ..download = fileStr.endsWith('.pdf') ? fileStr.replaceAll('.pdf', '.txt') : '$fileStr.txt'
                                ..click();
                              Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(blobUrl));
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading $fileStr...'),
                                backgroundColor: const Color(0xFF16A34A),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    if (_selectedTab == 5) {
      // FINANCIAL TAB DETAILS
      final ledger = appState.studentFinancialList.isNotEmpty
          ? appState.studentFinancialList
              .where((f) => f['academic_year']?.toString() == appState.selectedAcademicYear)
              .map((f) {
                final status = f['payment_status']?.toString() ?? 'Unpaid';
                final col = status == 'Paid'
                    ? const Color(0xFF16A34A)
                    : status == 'Partially Paid'
                        ? const Color(0xFFEA580C)
                        : const Color(0xFFDC2626);
                return {
                  'name': f['fee_head']?.toString() ?? 'Fee Item',
                  'amount': 'Rs. ${f['total_amount'] ?? 0}',
                  'paid': 'Rs. ${f['paid_amount'] ?? 0}',
                  'bal': 'Rs. ${f['balance_amount'] ?? 0}',
                  'status': status,
                  'col': col,
                };
              }).toList()
          : [];

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Fee Payments & Financial Ledgers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const Divider(height: 24),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 34,
                dataRowHeight: 44,
                headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Fee Head / Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Total Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Balance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                ],
                 rows: ledger.map((item) {
                  final nameVal = item['name'] as String;
                  final amountVal = item['amount'] as String;
                  final paidVal = item['paid'] as String;
                  final balVal = item['bal'] as String;
                  final statusVal = item['status'] as String;
                  final colorVal = item['col'] as Color;
                  return DataRow(cells: [
                    DataCell(Text(nameVal, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                    DataCell(Text(amountVal, style: const TextStyle(fontSize: 11))),
                    DataCell(Text(paidVal, style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A)))),
                    DataCell(Text(balVal, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626)))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorVal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusVal,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorVal),
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedTab == 6) {
      // SETTINGS TAB DETAILS
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.settings_outlined, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Account & Notification Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Assignment Deadlines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Receive push alerts 24 hours before assignment submission deadlines.', style: TextStyle(fontSize: 10)),
              value: _settingsAssignmentAlerts,
              activeColor: const Color(0xFF2563EB),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _settingsAssignmentAlerts = v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Exam Circular Notifications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Receive SMS / email warnings when exam schedules are announced.', style: TextStyle(fontSize: 10)),
              value: _settingsExamAlerts,
              activeColor: const Color(0xFF2563EB),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _settingsExamAlerts = v),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Fee Reminders', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              subtitle: const Text('Receive auto reminders when fee deadlines approach.', style: TextStyle(fontSize: 10)),
              value: _settingsFeeReminders,
              activeColor: const Color(0xFF2563EB),
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _settingsFeeReminders = v),
            ),
          ],
        ),
      );
    }

    if (_selectedTab != 0) {
      // General Tab fallbacks
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(_tabIcons[_selectedTab], size: 56, color: const Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              Text(
                '${_tabs[_selectedTab]} Details',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text('Connected live to Supabase database tables.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Row 1: Personal Info, Academic Summary, Contact Info
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            if (width >= 1000) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildPersonalInfoCard(appState)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAcademicSummaryCard(appState)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildContactInfoCard(appState)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                _buildPersonalInfoCard(appState),
                const SizedBox(height: 16),
                _buildAcademicSummaryCard(appState),
                const SizedBox(height: 16),
                _buildContactInfoCard(appState),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Row 2: Admission Details, Financial Summary, Attendance Summary
        LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            if (width >= 1000) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildAdmissionDetailsCard(appState)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFinancialSummaryCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildAttendanceSummaryCard(appState)),
                  ],
                ),
              );
            }
            return Column(
              children: [
                _buildAdmissionDetailsCard(appState),
                const SizedBox(height: 16),
                _buildFinancialSummaryCard(),
                const SizedBox(height: 16),
                _buildAttendanceSummaryCard(appState),
              ],
            );
          },
        ),
        const SizedBox(height: 16),

        // Row 3: Education Details
        _buildEducationDetailsCard(appState),
      ],
    );
  }

  Widget _buildTabInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // --- CARDS HELPERS ---

  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildGridRow(IconData icon, String label, String value, {Widget? badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: badge ??
                  Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Personal Information
  Widget _buildPersonalInfoCard(AppState appState) {
    return _buildCardContainer(
      title: 'Personal Information',
      child: Column(
        children: [
          _buildGridRow(Icons.person_outline, 'Gender', appState.getProfileField('gender')),
          _buildGridRow(Icons.cake_outlined, 'Date of Birth', appState.getProfileField('dob')),
          _buildGridRow(Icons.bloodtype_outlined, 'Blood Group', appState.getProfileField('blood_group')),
          _buildGridRow(Icons.flag_outlined, 'Nationality', appState.getProfileField('nationality')),
          _buildGridRow(Icons.temple_hindu_outlined, 'Religion', appState.getProfileField('religion')),
          _buildGridRow(Icons.people_outline, 'Community', appState.getProfileField('community')),
          _buildGridRow(Icons.translate_outlined, 'Mother Tongue', appState.getProfileField('mother_tongue')),
        ],
      ),
    );
  }

  // 2. Academic Summary
  Widget _buildAcademicSummaryCard(AppState appState) {
    final cgpa = appState.getProfileField('cgpa');
    final att = '${appState.getProfileField('attendance_percentage')}%';
    return _buildCardContainer(
      title: 'Academic Summary',
      child: Column(
        children: [
          _buildGridRow(Icons.class_outlined, 'Current Semester', appState.getProfileField('semester')),
          _buildGridRow(Icons.business_outlined, 'Department', appState.getProfileField('department')),
          _buildGridRow(Icons.grid_view_outlined, 'Section', appState.getProfileField('section')),
          _buildGridRow(Icons.credit_card_outlined, 'Credits Earned', appState.getProfileField('credits_earned').isEmpty ? appState.getProfileField('earned_credits') : appState.getProfileField('credits_earned')),
          _buildGridRow(
            Icons.grade_outlined,
            'CGPA',
            cgpa,
            badge: Text(cgpa, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
          ),
          _buildGridRow(
            Icons.rule_outlined,
            'Attendance',
            att,
            badge: Text(att, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
          ),
          _buildGridRow(Icons.person_pin_outlined, 'Class Advisor', appState.getProfileField('class_advisor')),
        ],
      ),
    );
  }

  // 3. Admission Details
  Widget _buildAdmissionDetailsCard(AppState appState) {
    final admType = appState.getProfileField('admission_type');
    return _buildCardContainer(
      title: 'Admission Details',
      child: Column(
        children: [
          _buildGridRow(
            Icons.assignment_ind_outlined,
            'Admission Type',
            admType,
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
              child: Text(admType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
            ),
          ),
          _buildGridRow(Icons.how_to_reg_outlined, 'Admission Mode', 'TNEA Counselling'),
          _buildGridRow(Icons.workspace_premium_outlined, 'Application No', appState.getProfileField('application_no')),
          _buildGridRow(Icons.event_available_outlined, 'Admission Date', appState.getProfileField('date_of_admission')),
        ],
      ),
    );
  }


  // 4. Contact Information
  Widget _buildContactInfoCard(AppState appState) {
    final contactNum = appState.mobileNumber;
    final emailAddress = appState.personalEmail;

    final rawAddress = appState.address;
    final addressParts = rawAddress.split(',');
    final formattedAddress = addressParts.length >= 3
        ? '${addressParts[0].trim()},\n${addressParts[1].trim()},\n${addressParts.sublist(2).join(', ').trim()}'
        : rawAddress.replaceAll(', ', ',\n');

    return _buildCardContainer(
      title: 'Contact Information',
      child: Column(
        children: [
          _buildGridRow(Icons.phone_outlined, 'Contact Number', contactNum),
          _buildGridRow(Icons.email_outlined, 'Institute Email', 'durai.b@ksrce.ac.in'),
          _buildGridRow(Icons.mail_outline, 'Personal Email', emailAddress),
          _buildGridRow(
            Icons.location_on_outlined,
            'Current Address',
            formattedAddress,
          ),
          _buildGridRow(
            Icons.contact_emergency_outlined,
            'Emergency Contact',
            'Mr. Balan (Father)',
            badge: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
              child: const Text('Primary Contact', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Financial Summary
  Widget _buildFinancialSummaryCard() {
    final appState = AppStateProvider.of(context);
    final paid = appState.fees
        .where((f) => f.academicYear == appState.selectedAcademicYear && f.isPaid == true)
        .fold<double>(0.0, (sum, f) => sum + f.amount);
    final pending = appState.fees
        .where((f) => f.academicYear == appState.selectedAcademicYear && f.isPaid == false)
        .fold<double>(0.0, (sum, f) => sum + f.amount);

    final hasPendingHostel = appState.fees.any((f) =>
        f.academicYear == appState.selectedAcademicYear &&
        f.category.toLowerCase().contains('hostel') == true &&
        f.isPaid == false);
    final hasPendingBus = appState.fees.any((f) =>
        f.academicYear == appState.selectedAcademicYear &&
        f.category.toLowerCase().contains('transport') == true &&
        f.isPaid == false);

    final hostelStatus = hasPendingHostel ? 'Pending' : 'Paid';
    final busStatus = hasPendingBus ? 'Pending' : 'Paid';

    final pendingFees = appState.fees.where((f) =>
        f.academicYear == appState.selectedAcademicYear &&
        f.isPaid == false).toList();
    pendingFees.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final nextDue = pendingFees.isNotEmpty ? pendingFees.first.dueDate : '-';

    final scholarship = appState.getProfileField('scholarship').isEmpty ? '0' : appState.getProfileField('scholarship');

    return _buildCardContainer(
      title: 'Financial Summary',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildFinancialTile('Fees Paid', '₹${paid.toInt()}', Colors.green[50]!, const Color(0xFF15803D))),
              const SizedBox(width: 6),
              Expanded(child: _buildFinancialTile('Remaining', '₹${pending.toInt()}', Colors.red[50]!, const Color(0xFFB91C1C))),
              const SizedBox(width: 6),
              Expanded(child: _buildFinancialTile('Scholarship', '₹$scholarship', Colors.blue[50]!, const Color(0xFF1D4ED8))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hostel Fee: $hostelStatus', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
              Text('Bus Fee: $busStatus', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
              Text('Next Due: $nextDue', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    html.window.open('https://erp.ksrei.org/PrimeERP_KSR/Login.aspx', '_blank');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text('Pay Fees', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onNavigate?.call(9), // moves to Fees screen
                  child: const Text('View Fee History', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTile(String title, String val, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  // 6. Attendance Summary (tapping navigates to Attendance screen)
  Widget _buildAttendanceSummaryCard(AppState appState) {
    final attStr = appState.getProfileField('attendance_percentage', defaultValue: '91');
    final double attPct = double.tryParse(attStr) ?? 91.0;
    final double progressVal = (attPct / 100.0).clamp(0.0, 1.0);
    final String pctDisplay = '${attPct.toStringAsFixed(attPct.truncateToDouble() == attPct ? 0 : 1)}%';

    // Calculate attendance metrics
    final totalDays = appState.attendanceRecords.isNotEmpty ? appState.attendanceRecords.length : 100;
    int presentDays = 0;
    int absentDays = 0;
    int odDays = 0;

    if (appState.attendanceRecords.isNotEmpty) {
      for (var r in appState.attendanceRecords) {
        final p1 = r['p1']?.toString() ?? '';
        final remarks = r['remarks']?.toString().toUpperCase() ?? '';
        if (remarks.contains('OD') || remarks.contains('MEDICAL')) {
          odDays++;
        } else if (p1 == 'A' || remarks == 'ABSENT') {
          absentDays++;
        } else {
          presentDays++;
        }
      }
    } else {
      presentDays = (totalDays * (attPct / 100.0)).round();
      absentDays = totalDays - presentDays;
    }

    final theoryClasses = (presentDays * 0.8).round();
    final labClasses = presentDays - theoryClasses;

    return InkWell(
      onTap: () => widget.onNavigate?.call(4), // moves to Attendance screen
      borderRadius: BorderRadius.circular(16),
      child: _buildCardContainer(
        title: 'Attendance Summary',
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progressVal,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      attPct >= 75 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    strokeWidth: 7,
                  ),
                ),
                Text(
                  pctDisplay,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAttendanceDetailRow('Theory Classes', '$theoryClasses Days'),
                  _buildAttendanceDetailRow('Lab Classes', '$labClasses Days'),
                  _buildAttendanceDetailRow('Present Days', '$presentDays Days'),
                  _buildAttendanceDetailRow('Absent Days', '$absentDays Days'),
                  _buildAttendanceDetailRow('OD / Medical', '$odDays Days'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceDetailRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Text(val, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  // 7. Education Details Table   
  Widget _buildEducationDetailsCard(AppState appState) {
    final List<Map<String, dynamic>> dbEducation = appState.studentEducationList;
    final rawProfileHistory = appState.studentProfileData?['education_history'];
    final List<dynamic> profileHistory = (rawProfileHistory is List) ? rawProfileHistory : [];

    final List<Map<String, dynamic>> educationList = (dbEducation.isNotEmpty
        ? List<Map<String, dynamic>>.from(dbEducation)
        : profileHistory.map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)).toList());

    bool hasQual(String q) {
      return educationList.any((e) => (e['qualification']?.toString() ?? e['qual']?.toString() ?? '').toLowerCase().contains(q.toLowerCase()));
    }
    if (!hasQual('6th')) {
      educationList.add({
        'qualification': '6th Standard',
        'institution': 'Government Higher Secondary School',
        'board_university': 'State Board',
        'year_of_passing': '2016',
        'percentage_marks': '91%',
      });
    }
    if (!hasQual('7th')) {
      educationList.add({
        'qualification': '7th Standard',
        'institution': 'Government Higher Secondary School',
        'board_university': 'State Board',
        'year_of_passing': '2017',
        'percentage_marks': '92%',
      });
    }
    if (!hasQual('8th')) {
      educationList.add({
        'qualification': '8th Standard',
        'institution': 'Government Higher Secondary School',
        'board_university': 'State Board',
        'year_of_passing': '2018',
        'percentage_marks': '93%',
      });
    }
    if (!hasQual('9th')) {
      educationList.add({
        'qualification': '9th Standard',
        'institution': 'Government Higher Secondary School',
        'board_university': 'State Board',
        'year_of_passing': '2019',
        'percentage_marks': '94%',
      });
    }

    educationList.sort((a, b) {
      int getRank(Map<String, dynamic> item) {
        final q = (item['qualification']?.toString() ?? item['qual']?.toString() ?? '').toLowerCase();
        if (q.contains('6th') || q.contains('6 th')) return 1;
        if (q.contains('7th') || q.contains('7 th')) return 2;
        if (q.contains('8th') || q.contains('8 th')) return 3;
        if (q.contains('9th') || q.contains('9 th')) return 4;
        if (q.contains('10') || q.contains('sslc')) return 5;
        if (q.contains('12') || q.contains('hsc') || q.contains('diploma') || q.contains('secondary')) return 6;
        if (q.contains('b.e') || q.contains('b.tech') || q.contains('college') || q.contains('engineering') || q.contains('degree') || q.contains('m.e') || q.contains('m.tech')) return 7;
        return 8;
      }

      final rankA = getRank(a);
      final rankB = getRank(b);
      if (rankA != rankB) return rankA.compareTo(rankB);

      final yopA = int.tryParse(a['year_of_passing']?.toString() ?? a['yop']?.toString() ?? '') ?? 0;
      final yopB = int.tryParse(b['year_of_passing']?.toString() ?? b['yop']?.toString() ?? '') ?? 0;
      return yopA.compareTo(yopB);
    });

    return _buildCardContainer(
      title: 'Education Details',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 36,
                dataRowHeight: 44,
                columnSpacing: 32,
                headingRowColor: WidgetStateProperty.resolveWith((states) => const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Qualification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
                  DataColumn(label: Text('Institution', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
                  DataColumn(label: Text('Board / University', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
                  DataColumn(label: Text('Year of Passing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
                  DataColumn(label: Text('Percentage / Marks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
                ],
                rows: educationList.map((item) {
                  final qual = item['qualification']?.toString() ?? item['qual']?.toString() ?? '';
                  final inst = item['institution']?.toString() ?? item['school']?.toString() ?? '';
                  final board = item['board_university']?.toString() ?? item['board']?.toString() ?? '';
                  final yop = item['year_of_passing']?.toString() ?? item['yop']?.toString() ?? '';
                  final scoreVal = item['percentage_marks']?.toString() ?? item['score']?.toString() ?? '';

                  final isCompleted = scoreVal == 'Completed' || scoreVal.contains('%') || scoreVal.contains('CGPA');

                  return DataRow(cells: [
                    DataCell(Text(qual, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
                    DataCell(Text(inst, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                    DataCell(Text(board, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                    DataCell(Text(yop, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                    DataCell(
                      scoreVal.isEmpty
                          ? const SizedBox.shrink()
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                scoreVal,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? const Color(0xFF166534) : const Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // 8. Performance Summary
  Widget _buildPerformanceSummaryCard(AppState appState) {
    final cgpa = appState.getProfileField('cgpa');
    final credits = appState.getProfileField('credits_earned');
    return _buildCardContainer(
      title: 'Performance Summary',
      child: Row(
        children: [
          Expanded(child: _buildMetricBox('CGPA', cgpa, Colors.blue[50]!, const Color(0xFF2563EB))),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricBox('University Rank', '14', Colors.purple[50]!, const Color(0xFF7E22CE))),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricBox('Credits Earned', credits, Colors.teal[50]!, const Color(0xFF0D9488))),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricBox('Backlogs', '0', Colors.green[50]!, const Color(0xFF15803D))),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String title, String val, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  // --- 5. FOOTER ---
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF0F172A),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: const [
          Text(
            '© 2026 KSR College of Engineering, Tiruchengode. All Rights Reserved.',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          Text(
            'KSRCE ERP  •  Student Information System  •  Version 3.0.0  •  Help Desk  •  Privacy Policy',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
