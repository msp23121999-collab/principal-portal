import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_badge.dart';

class RolesPermissionsScreen extends StatelessWidget {
  const RolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = [
      {
        'role': 'Super Admin',
        'members': '3 Admins',
        'access': 'Full Global Access (ALL Modules)',
        'status': 'Active',
      },
      {
        'role': 'HOD (Head of Department)',
        'members': '12 Faculty',
        'access': 'Department Management, Approvals, Subject Mapping',
        'status': 'Active',
      },
      {
        'role': 'Dean Academic',
        'members': '2 Deans',
        'access': 'Regulations, Course Outcomes, Examinations',
        'status': 'Active',
      },
      {
        'role': 'Faculty Member',
        'members': '340 Staff',
        'access': 'Attendance, Internal Marks Entry, Circulars',
        'status': 'Active',
      },
      {
        'role': 'Student',
        'members': '4,206 Students',
        'access': 'Timetable, Hall Tickets, Marks, Grievances',
        'status': 'Active',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Roles & Access Control Matrix',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Role Definitions, Permissions, RLS Policies & Access Hierarchy',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  label: 'Create New Custom Role',
                  icon: Icons.security_rounded,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Table(
                border: TableBorder.symmetric(
                  inside: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    children: [
                      _buildHeader('ROLE NAME'),
                      _buildHeader('ASSIGNED USERS'),
                      _buildHeader('PERMISSION SCOPE'),
                      _buildHeader('STATUS'),
                    ],
                  ),
                  ...roles.map(
                    (r) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            r['role'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(r['members'] ?? ''),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(r['access'] ?? ''),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: AppStatusBadge(
                            status: r['status'] ?? 'Active',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
