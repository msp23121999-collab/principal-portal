import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/router/route_names.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/app_text_field.dart';
import '../erp_repository.dart';

class UserEditForm extends ConsumerStatefulWidget {

  const UserEditForm({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  ConsumerState<UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends ConsumerState<UserEditForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Basic fields
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _role;
  late String _department;
  late String _status;

  // Extended Student & Staff fields
  late TextEditingController _admissionNumberController;
  late TextEditingController _admissionDateController;
  late TextEditingController _rollNumberController;
  late TextEditingController _registrationNumberController;
  late TextEditingController _domainEmailController;
  late TextEditingController _contactController;
  late TextEditingController _dobController;
  late TextEditingController _batchController;
  late TextEditingController _designationController;
  late TextEditingController _joiningDateController;
  late TextEditingController _qualificationController;
  late TextEditingController _employeeIdController;
  late String _gender;
  late String _community;
  late String _section;
  late String _bloodGroup;

  bool _initialized = false;

  static const List<String> _roles = ['Student', 'Faculty', 'Department HOD', 'Registrar', 'Admin'];
  static const List<String> _departments = ['CSE', 'ECE', 'MECH', 'EEE', 'CIVIL', 'IT', 'Computer Science', 'Information Technology', 'Mechanical Engineering', 'Civil Engineering', 'Administration', 'ALL'];
  static const List<String> _statuses = ['Active', 'Pending', 'Inactive'];
  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _communities = ['OC', 'BC', 'MBC', 'SC', 'ST'];
  static const List<String> _sections = ['A', 'B', 'C', 'D', 'E'];
  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _admissionNumberController = TextEditingController();
    _admissionDateController = TextEditingController();
    _rollNumberController = TextEditingController();
    _registrationNumberController = TextEditingController();
    _domainEmailController = TextEditingController();
    _contactController = TextEditingController();
    _dobController = TextEditingController();
    _batchController = TextEditingController();
    _designationController = TextEditingController();
    _joiningDateController = TextEditingController();
    _qualificationController = TextEditingController();
    _employeeIdController = TextEditingController();
    _role = 'Student';
    _department = 'CSE';
    _status = 'Active';
    _gender = 'Male';
    _community = 'OC';
    _section = 'A';
    _bloodGroup = 'O+';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _admissionNumberController.dispose();
    _admissionDateController.dispose();
    _rollNumberController.dispose();
    _registrationNumberController.dispose();
    _domainEmailController.dispose();
    _contactController.dispose();
    _dobController.dispose();
    _batchController.dispose();
    _designationController.dispose();
    _joiningDateController.dispose();
    _qualificationController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  void _initFromUser(UserModel user) {
    if (_initialized) return;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _role = user.role;
    _department = user.department;
    _status = user.status;
    _admissionNumberController.text = user.admissionNumber ?? '';
    _admissionDateController.text = user.admissionDate ?? '';
    _rollNumberController.text = user.rollNumber ?? '';
    _registrationNumberController.text = user.registrationNumber ?? '';
    _domainEmailController.text = user.domainEmail ?? (user.email.isNotEmpty ? user.email : '');
    _contactController.text = user.contactNumber ?? '';
    _dobController.text = user.dateOfBirth ?? '';
    _batchController.text = user.batch ?? '';
    _designationController.text = user.designation ?? (user.role == 'Faculty' ? 'Assistant Professor' : user.role == 'Department HOD' ? 'Professor & HOD' : user.role);
    _joiningDateController.text = user.joiningDate ?? '2021-06-01';
    _qualificationController.text = user.qualification ?? (user.isFacultyOrHod ? 'Ph.D in ${user.department}' : 'Higher Education');
    _employeeIdController.text = user.employeeId ?? user.id;
    _gender = user.gender ?? 'Male';
    _community = user.community ?? 'OC';
    _section = user.section ?? 'A';
    _bloodGroup = user.bloodGroup ?? 'O+';
    _initialized = true;
  }

  void _saveUser(UserModel user) {
    if (_formKey.currentState!.validate()) {
      final updatedUser = user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        department: _department,
        status: _status,
        node: _status == 'Active' ? 'Active Node' : 'Inactive Node',
        admissionNumber: _admissionNumberController.text.trim(),
        admissionDate: _admissionDateController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        domainEmail: _domainEmailController.text.trim(),
        contactNumber: _contactController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
        batch: _batchController.text.trim(),
        gender: _gender,
        community: _community,
        section: _section,
        bloodGroup: _bloodGroup,
        designation: _designationController.text.trim(),
        joiningDate: _joiningDateController.text.trim(),
        qualification: _qualificationController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
      );

      showDialog(
        context: context,
        builder: (ctx) => AppConfirmationDialog(
          title: 'Save Changes — ${user.name}',
          content: 'Are you sure you want to update this user record?\n\nName: ${_nameController.text}\nRole: $_role | Dept: $_department | Status: $_status',
          confirmLabel: 'Yes, Save Changes',
          cancelLabel: 'No, Cancel',
          type: ConfirmationType.edit,
          onConfirm: () {
            ref.read(usersProvider.notifier).updateUser(updatedUser);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User "${updatedUser.name}" details updated successfully.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go(RouteNames.users);
          },
        ),
      );
    }
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final effectiveItems = items.contains(value) ? items : [value, ...items];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
        AppSpacing.gapXs,
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: effectiveItems.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAcademicOrEmployeeTab() {
    final isStudentRole = _role == 'Student';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapSm,
          _buildSectionHeader(
            isStudentRole ? Icons.badge_rounded : Icons.work_rounded,
            isStudentRole ? 'Admission & Student Record' : 'Employment & Staff Record',
            AppColors.primary,
          ),
          AppSpacing.gapMd,
          if (isStudentRole) ...[
            AppTextField(
              label: 'Admission Number',
              hintText: 'e.g. ADM2022001',
              controller: _admissionNumberController,
              validator: (v) => v == null || v.isEmpty ? 'Admission number required' : null,
            ),
            AppSpacing.gapMd,
            AppTextField(
              label: 'Admission Date',
              hintText: 'YYYY-MM-DD',
              controller: _admissionDateController,
            ),
            AppSpacing.gapMd,
            AppTextField(
              label: 'Batch / Academic Session',
              hintText: 'e.g. 2022-2026',
              controller: _batchController,
              validator: (v) => v == null || v.isEmpty ? 'Batch required' : null,
            ),
            AppSpacing.gapMd,
            _buildDropdown(
              label: 'Section Class',
              value: _section,
              items: _sections,
              onChanged: (v) => setState(() => _section = v!),
            ),
          ] else ...[
            AppTextField(
              label: 'Employee / Staff ID',
              hintText: 'e.g. EMP-1042',
              controller: _employeeIdController,
              validator: (v) => v == null || v.isEmpty ? 'Employee ID required' : null,
            ),
            AppSpacing.gapMd,
            AppTextField(
              label: 'Designation / Post',
              hintText: 'e.g. Professor & HOD / Associate Professor',
              controller: _designationController,
              validator: (v) => v == null || v.isEmpty ? 'Designation required' : null,
            ),
            AppSpacing.gapMd,
            AppTextField(
              label: 'Academic Qualification',
              hintText: 'e.g. Ph.D (CSE), M.E',
              controller: _qualificationController,
            ),
            AppSpacing.gapMd,
            AppTextField(
              label: 'Date of Joining Service',
              hintText: 'YYYY-MM-DD',
              controller: _joiningDateController,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileTab() => SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapSm,
          _buildSectionHeader(Icons.person_rounded, 'Personal Profile', AppColors.info),
          AppSpacing.gapMd,
          AppTextField(
            label: 'Full Name',
            controller: _nameController,
            validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
          ),
          AppSpacing.gapMd,
          _buildDropdown(
            label: 'Gender',
            value: _gender,
            items: _genders,
            onChanged: (v) => setState(() => _gender = v!),
          ),
          AppSpacing.gapMd,
          AppTextField(
            label: 'Date of Birth',
            hintText: 'YYYY-MM-DD',
            controller: _dobController,
          ),
          AppSpacing.gapMd,
          _buildDropdown(
            label: 'Community / Category',
            value: _community,
            items: _communities,
            onChanged: (v) => setState(() => _community = v!),
          ),
          AppSpacing.gapMd,
          _buildDropdown(
            label: 'Blood Group',
            value: _bloodGroup,
            items: _bloodGroups,
            onChanged: (v) => setState(() => _bloodGroup = v!),
          ),
          AppSpacing.gapMd,
          AppTextField(
            label: 'Contact Number',
            hintText: 'e.g. 9876543210',
            controller: _contactController,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );

  Widget _buildAcademicIdTab() {
    final isStudentRole = _role == 'Student';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapSm,
          _buildSectionHeader(Icons.fingerprint_rounded, 'Institutional IDs & Credentials', AppColors.warning),
          AppSpacing.gapMd,
          if (isStudentRole) ...[
            AppTextField(
              label: 'Roll Number',
              hintText: 'e.g. 22CS001',
              controller: _rollNumberController,
            ),
            AppSpacing.gapMd,
            AppTextField(
              label: 'Registration Number',
              hintText: 'e.g. REG/CSE/2022/001',
              controller: _registrationNumberController,
            ),
            AppSpacing.gapMd,
          ],
          AppTextField(
            label: 'Domain Email (Institutional ID)',
            hintText: 'e.g. user@campus.edu.in',
            controller: _domainEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(18),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              border: Border.all(color: AppColors.warning.withAlpha(64)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    'Domain Email changes will update official institutional login & single sign-on credentials.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab() => SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.gapSm,
          _buildSectionHeader(Icons.manage_accounts_rounded, 'Account & System Role Settings', AppColors.error),
          AppSpacing.gapMd,
          AppTextField(
            label: 'Email Address',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          AppSpacing.gapMd,
          _buildDropdown(
            label: 'Department',
            value: _department,
            items: _departments,
            onChanged: (v) => setState(() => _department = v!),
          ),
          AppSpacing.gapMd,
          _buildDropdown(
            label: 'System Role',
            value: _role,
            items: _roles,
            onChanged: (v) => setState(() => _role = v!),
          ),
          AppSpacing.gapMd,
          _buildDropdown(
            label: 'Account Status',
            value: _status,
            items: _statuses,
            onChanged: (v) => setState(() => _status = v!),
          ),
        ],
      ),
    );

  Widget _buildSectionHeader(IconData icon, String title, Color color) => Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          AppSpacing.gapSm,
          Text(title, style: AppTypography.labelLarge.copyWith(color: color)),
        ],
      ),
    );

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final user = users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => const UserModel(
        id: '',
        name: '',
        email: '',
        role: '',
        department: '',
        node: '',
        status: '',
      ),
    );

    if (user.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit User Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              AppSpacing.gapMd,
              const Text('User profile not found.'),
              AppSpacing.gapMd,
              AppButton(
                label: 'Back to User Directory',
                onPressed: () => context.go(RouteNames.users),
              ),
            ],
          ),
        ),
      );
    }

    _initFromUser(user);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit User Profile — ${user.name} (${user.role})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.users),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(
              icon: Icon(_role == 'Student' ? Icons.badge_rounded : Icons.work_rounded),
              text: _role == 'Student' ? 'Admission' : 'Employment',
            ),
            const Tab(icon: Icon(Icons.person_rounded), text: 'Profile'),
            const Tab(icon: Icon(Icons.fingerprint_rounded), text: 'Institutional ID'),
            const Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Account & Role'),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAcademicOrEmployeeTab(),
                    _buildProfileTab(),
                    _buildAcademicIdTab(),
                    _buildAccountTab(),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        type: AppButtonType.secondary,
                        onPressed: () => context.go(RouteNames.users),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Expanded(
                      child: AppButton(
                        label: 'Save User Record',
                        onPressed: () => _saveUser(user),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
