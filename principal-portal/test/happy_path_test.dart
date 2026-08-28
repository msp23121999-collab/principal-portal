import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:principal_portal/features/dashboard/models/dashboard_summary.dart';
import 'package:principal_portal/features/dashboard/providers/dashboard_providers.dart';
import 'package:principal_portal/features/dashboard/screens/dashboard_screen.dart';
import 'package:principal_portal/features/profile/models/principal_profile.dart';
import 'package:principal_portal/features/profile/providers/principal_profile_providers.dart';

void main() {
  testWidgets('Happy path UI test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 2000));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith(
            (ref) => Future.value(
              const DashboardSummary(
                institutionOverview: InstitutionOverview(
                  totalStudents: 100,
                  totalFaculty: 10,
                  totalDepartments: 5,
                ),
                departmentRows: [],
                facultySummary: FacultySummary(
                  totalFaculty: 10,
                  averageExperienceYears: 5,
                  averageAttendancePercent: 90,
                  totalResearchPapers: 10,
                ),
                studentSummary: StudentSummary(
                  totalStudents: 100,
                  averageCgpa: 8.5,
                  averageAttendancePercent: 90,
                  topPerformerCount: 10,
                  atRiskCount: 2,
                ),
                todayAttendancePercent: 90,
                resultSummary: ResultSummary(
                  semesterLabel: 'Odd',
                  overallPassPercent: 90,
                  byDepartment: [],
                ),
                placementSummary: PlacementSummary(
                  totalEligible: 100,
                  totalPlaced: 50,
                  placementPercent: 50,
                  averagePackageLpa: 5,
                  highestPackageLpa: 10,
                  topRecruiter: 'TCS',
                ),
              ),
            ),
          ),
          principalProfileProvider.overrideWith(
            (ref) => Future.value(
              PrincipalProfile(
                name: 'Test Principal',
                designation: 'Principal',
                employeeId: '123',
                dateOfBirth: DateTime(1980),
                gender: 'Male',
                experienceYears: 10,
                hodExperienceYears: 5,
                education: [],
                researchPapers: [],
                awards: [],
                documents: [],
                responsibilities: [],
                officeDetails: const OfficeDetails(
                  cabinLocation: 'Main',
                  officeHours: '9-5',
                  extensionNumber: '123',
                ),
                contactInfo: const ContactInfo(
                  email: '',
                  phone: '',
                  address: '',
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: DashboardScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Principal'), findsOneWidget);
  });
}
