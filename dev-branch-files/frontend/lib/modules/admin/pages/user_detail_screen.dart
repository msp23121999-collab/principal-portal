import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/router/route_names.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_confirmation_dialog.dart';
import '../widgets/app_status_badge.dart';
import '../erp_repository.dart';
class UserDetailScreen extends ConsumerWidget {

  const UserDetailScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    final user = users.firstWhere(
      (u) => u.id == userId,
      orElse: () => const UserModel(
          id: '',
          name: 'Unknown User',
          email: '',
          role: '',
          department: '',
          node: '',
          status: ''),
    );

    if (user.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 48, color: AppColors.warning),
              AppSpacing.gapMd,
              const Text('User profile not found.'),
              AppSpacing.gapMd,
              AppButton(
                label: 'Back to List',
                onPressed: () => context.go(RouteNames.users),
              ),
            ],
          ),
        ),
      );
    }

    final avatarColor = user.isStudent
        ? AppColors.info
        : user.role == 'Department HOD'
            ? AppColors.primary
            : user.role == 'Faculty'
                ? AppColors.success
                : AppColors.warning;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(user.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.users),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () =>
                context.go('${RouteNames.users}/${user.id}/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar + name card
              AppCard(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: avatarColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: avatarColor.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.name.length >= 2
                            ? user.name.substring(0, 2).toUpperCase()
                            : user.name.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 28),
                      ),
                    ),
                    AppSpacing.gapMd,
                    Text(user.name, style: AppTypography.h2),
                    AppSpacing.gapXs,
                    Text(user.email,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    AppSpacing.gapMd,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppStatusBadge(status: user.status),
                        AppSpacing.gapSm,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role,
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (user.isStudent && user.rollNumber != null) ...[
                      AppSpacing.gapSm,
                      Text(
                        'Roll No: ${user.rollNumber}  •  ${user.batch ?? ""}  •  Sec ${user.section ?? ""}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ] else if (!user.isStudent) ...[
                      AppSpacing.gapSm,
                      Text(
                        '${user.designation ?? user.role}  •  ID: ${user.employeeId ?? user.id}  •  Dept: ${user.department}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // ----- ROLE SPECIFIC SECTIONS -----
              if (user.isStudent) ...[
                _buildSectionTitle('Admission Details', Icons.badge_rounded, AppColors.primary),
                AppSpacing.gapSm,
                AppCard(
                  child: Column(
                    children: [
                      _detailRow('Admission No', user.admissionNumber ?? '—'),
                      const Divider(),
                      _detailRow('Admission Date', user.admissionDate ?? '—'),
                      const Divider(),
                      _detailRow('Batch', user.batch ?? '—'),
                      const Divider(),
                      _detailRow('Section', user.section ?? '—'),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
              ] else ...[
                _buildSectionTitle('Employment Details', Icons.work_rounded, AppColors.primary),
                AppSpacing.gapSm,
                AppCard(
                  child: Column(
                    children: [
                      _detailRow('Employee ID', user.employeeId ?? user.id),
                      const Divider(),
                      _detailRow('Designation', user.designation ?? user.role),
                      const Divider(),
                      _detailRow('Qualification', user.qualification ?? 'Master / Higher Ed'),
                      const Divider(),
                      _detailRow('Date of Joining', user.joiningDate ?? '—'),
                    ],
                  ),
                ),
                AppSpacing.gapLg,
              ],

              _buildSectionTitle('Personal Profile', Icons.person_rounded, AppColors.info),
              AppSpacing.gapSm,
              AppCard(
                child: Column(
                  children: [
                    _detailRow('Gender', user.gender ?? 'Male'),
                    const Divider(),
                    _detailRow('Date of Birth', user.dateOfBirth ?? '—'),
                    const Divider(),
                    _detailRow('Community / Category', user.community ?? 'OC'),
                    const Divider(),
                    _detailRow('Blood Group', user.bloodGroup ?? 'O+'),
                    const Divider(),
                    _detailRow('Contact Phone', user.contactNumber ?? '—'),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              _buildSectionTitle('Institutional IDs & Accounts', Icons.fingerprint_rounded, AppColors.warning),
              AppSpacing.gapSm,
              AppCard(
                child: Column(
                  children: [
                    if (user.isStudent) ...[
                      _detailRow('Roll Number', user.rollNumber ?? '—'),
                      const Divider(),
                      _detailRow('Registration No', user.registrationNumber ?? '—'),
                      const Divider(),
                    ],
                    _detailRow('Domain Email', user.domainEmail ?? user.email),
                    const Divider(),
                    _detailRow('Primary Email', user.email),
                    const Divider(),
                    _detailRow('Department', user.department),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // ----- COMMON SECTION -----
              _buildSectionTitle('Account Controls & Node', Icons.manage_accounts_rounded, AppColors.textSecondary),
              AppSpacing.gapSm,
              AppCard(
                child: Column(
                  children: [
                    _detailRow('System User ID', user.id),
                    const Divider(),
                    _detailRow('System Role', user.role),
                    const Divider(),
                    _detailRow('Department Unit', user.department),
                    const Divider(),
                    _detailRow('Campus Node', user.node),
                    const Divider(),
                    _detailRow('Account Status', user.status),
                  ],
                ),
              ),
              AppSpacing.gapLg,

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Edit Record',
                      type: AppButtonType.secondary,
                      icon: Icons.edit_rounded,
                      onPressed: () =>
                          context.go('${RouteNames.users}/${user.id}/edit'),
                    ),
                  ),
                  AppSpacing.gapMd,
                  Expanded(
                    child: AppButton(
                      label: user.status == 'Inactive'
                          ? 'Activate Account'
                          : 'Deactivate Account',
                      type: AppButtonType.destructive,
                      icon: user.status == 'Inactive'
                          ? Icons.check_circle_rounded
                          : Icons.block_rounded,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AppConfirmationDialog(
                            title: user.status == 'Inactive'
                                ? 'Activate Account'
                                : 'Deactivate Account',
                            content: user.status == 'Inactive'
                                ? 'Are you sure you want to activate "${user.name}"?'
                                : 'Are you sure you want to deactivate "${user.name}"?',
                            confirmLabel: 'Yes, Confirm',
                            cancelLabel: 'No, Cancel',
                            type: ConfirmationType.edit,
                            onConfirm: () {
                              final newStatus = user.status == 'Inactive'
                                  ? 'Active'
                                  : 'Inactive';
                              ref.read(usersProvider.notifier).updateUser(
                                    user.copyWith(
                                      status: newStatus,
                                      node: newStatus == 'Active'
                                          ? 'Active Node'
                                          : 'Inactive Node',
                                    ),
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Account status updated to $newStatus.'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        );
                      },
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

  Widget _buildSectionTitle(String title, IconData icon, Color color) => Row(
      children: [
        Icon(icon, color: color, size: 18),
        AppSpacing.gapSm,
        Text(title,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
      ],
    );

  Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
}
