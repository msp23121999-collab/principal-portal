import 'package:flutter_test/flutter_test.dart';
import 'package:principal_portal/core/constants/nav_destinations.dart';
import 'package:principal_portal/core/utils/number_formatter.dart';
import 'package:principal_portal/features/audit/models/audit.dart';
import 'package:principal_portal/features/department/models/department_admin.dart';
import 'package:principal_portal/features/examinations/models/examination.dart';
import 'package:principal_portal/features/finance/models/finance.dart';
import 'package:principal_portal/features/students/models/student_achievement.dart';

/// Guards the arithmetic every screen relies on.
///
/// This file used to assert that the mock-data arrays agreed with each other.
/// Those arrays are gone: the figures now come from the database, and the
/// cross-table invariants they pinned are enforced where the data lives —
/// `CHECK` constraints on the tables, and views (`v_department_rollup`,
/// `v_dashboard_summary`, `v_department_placement_summary`) that compute
/// totals from the rolls rather than storing them, so they cannot disagree.
///
/// What is left in Dart, and therefore still worth testing here, is the derived
/// arithmetic on the models. Every KPI card reads a figure through one of these
/// getters, so a mistake here is wrong on screen.
///
/// The zero cases matter most. A department with no students, a semester with
/// nobody sitting, a policy with no scores — these are real states in a fresh
/// or partly-filled database, and each one is a division by zero waiting to
/// happen.
void main() {
  group('Fee arithmetic', () {
    test(
      'outstanding is demand less collected, and dues never go negative',
      () {
        const status = DepartmentFeeStatus(
          departmentCode: 'CSE',
          departmentName: 'Computer Science & Engineering',
          studentsTotal: 400,
          studentsPaid: 360,
          demand: 40000000,
          collected: 36000000,
        );

        expect(status.outstanding, 4000000);
        expect(status.collectionPercent, closeTo(90, 0.001));
        expect(status.studentsPending, 40);
      },
    );

    test('a department with no demand reports 0%, not a crash', () {
      const empty = DepartmentFeeStatus(
        departmentCode: 'NEW',
        departmentName: 'Newly Created Department',
        studentsTotal: 0,
        studentsPaid: 0,
        demand: 0,
        collected: 0,
      );

      expect(empty.collectionPercent, 0);
      expect(empty.outstanding, 0);
    });

    test('a scholarship cannot show more disbursed than pending allows', () {
      const scheme = ScholarshipScheme(
        name: 'First Graduate Scholarship',
        sponsor: 'Government of Tamil Nadu',
        beneficiaries: 210,
        sanctioned: 4200000,
        disbursed: 3150000,
      );

      expect(scheme.pending, 1050000);
      expect(scheme.disbursedPercent, closeTo(75, 0.001));
    });

    test(
      'surplus and annual payroll derive from the month, not a constant',
      () {
        const month = MonthlyFinance(
          month: 'March',
          revenue: 12000000,
          expenditure: 9500000,
        );
        const payroll = PayrollLine(
          category: 'Teaching',
          headcount: 180,
          monthlyCost: 7200000,
        );

        expect(month.surplus, 2500000);
        expect(payroll.annualCost, 86400000);
      },
    );

    test('a loss-making month reports a negative surplus rather than zero', () {
      // Hiding a deficit behind a floor at zero would be the worst possible
      // rounding for a Principal reading the finance page.
      const month = MonthlyFinance(
        month: 'June',
        revenue: 3000000,
        expenditure: 8000000,
      );

      expect(month.surplus, -5000000);
    });
  });

  group('Departmental administration', () {
    DepartmentAdminMetrics metrics({
      required int sanctioned,
      required int filled,
      required int students,
    }) => DepartmentAdminMetrics(
      departmentCode: 'MECH',
      departmentName: 'Mechanical Engineering',
      budgetAllocated: 8000000,
      budgetUtilised: 6400000,
      classrooms: 12,
      laboratories: 6,
      sanctionedPosts: sanctioned,
      filledPosts: filled,
      studentCount: students,
      infrastructureScore: 82,
    );

    test('vacancies and utilisation are derived from the row', () {
      final row = metrics(sanctioned: 30, filled: 24, students: 420);

      expect(row.vacantPosts, 6);
      expect(row.staffingPercent, closeTo(80, 0.001));
      expect(row.budgetUtilisationPercent, closeTo(80, 0.001));
    });

    test('the 20:1 norm is applied at the boundary, not near it', () {
      // 20:1 exactly meets the AICTE norm; 20.05:1 does not. The card counting
      // breaches and the per-row status chip both read this getter, so the
      // boundary has to be the same for both.
      expect(
        metrics(sanctioned: 30, filled: 20, students: 400).meetsRatioNorm,
        isTrue,
      );
      expect(
        metrics(sanctioned: 30, filled: 20, students: 401).meetsRatioNorm,
        isFalse,
      );
    });

    test('a department with no staff reports a zero ratio, not infinity', () {
      final unstaffed = metrics(sanctioned: 8, filled: 0, students: 60);

      expect(unstaffed.facultyStudentRatio, 0);
      expect(unstaffed.staffingPercent, 0);
      // Zero staff reads as "meets the norm" only because there is no ratio to
      // breach. The vacancy count is what surfaces the problem.
      expect(unstaffed.vacantPosts, 8);
    });
  });

  group('Placement arithmetic', () {
    test('percentage and unplaced count agree with each other', () {
      const summary = DepartmentPlacementSummary(
        departmentCode: 'CSE',
        departmentName: 'Computer Science & Engineering',
        eligible: 120,
        placed: 96,
        highestPackageLpa: 42,
        averagePackageLpa: 8.5,
      );

      expect(summary.unplaced, 24);
      expect(summary.hasEligibleRoll, isTrue);
      expect(summary.placementPercent, closeTo(80, 0.001));
    });

    test('a department with no roll reports no rate at all', () {
      const none = DepartmentPlacementSummary(
        departmentCode: 'SCI',
        departmentName: 'Science & Humanities',
        eligible: 0,
        placed: 0,
        highestPackageLpa: 0,
        averagePackageLpa: 0,
      );

      // Undefined, not zero: 'no students recorded' and 'nobody was placed'
      // are different facts and must not render the same.
      expect(none.hasEligibleRoll, isFalse);
      expect(none.placementPercent, isNull);
      expect(none.unplaced, 0);
    });
  });

  group('Examination arithmetic', () {
    test('hall ticket figures account for every eligible candidate', () {
      const status = HallTicketStatus(
        departmentCode: 'ECE',
        departmentName: 'Electronics & Communication Engineering',
        eligible: 300,
        issued: 280,
        withheld: 12,
      );

      expect(status.pending, 8);
      expect(status.issuedPercent, closeTo(93.333, 0.001));
      expect(status.pending + status.issued + status.withheld, status.eligible);
    });

    test('CIA entry progress handles a department yet to start', () {
      const notStarted = CiaProgress(
        departmentCode: 'MCA',
        departmentName: 'Master of Computer Applications',
        cia1Percent: 0,
        cia2Percent: 0,
        cia3Percent: 0,
        marksEntered: 0,
        marksExpected: 0,
      );

      expect(notStarted.entryPercent, 0);
      expect(notStarted.averagePercent, 0);
    });
  });

  group('Compliance and policy arithmetic', () {
    test('an area is scored against its own maximum', () {
      // Areas are scored out of different maximums, so a raw score cannot be
      // compared across them — only the percentage can.
      final outOfTen = ComplianceArea(
        name: 'Fire Safety Certification',
        category: 'Statutory',
        owner: 'Estate Office',
        score: 8,
        maximumScore: 10,
        lastReviewed: DateTime(2026, 3, 1),
        state: ComplianceState.compliant,
      );

      expect(outOfTen.scorePercent, closeTo(80, 0.001));
    });

    test('an unscored area reports 0%, not a crash', () {
      final unscored = ComplianceArea(
        name: 'Newly Added Area',
        category: 'Internal',
        owner: 'IQAC',
        score: 0,
        maximumScore: 0,
        lastReviewed: DateTime(2026, 1, 15),
        state: ComplianceState.partial,
      );

      expect(unscored.scorePercent, 0);
    });

    test('a review is overdue against the date asked about', () {
      final policy = PolicyAdherence(
        policy: 'Anti-Ragging Policy',
        owner: 'Dean of Students',
        lastReviewed: DateTime(2024, 6, 1),
        nextReview: DateTime(2026, 6, 1),
        adherencePercent: 94,
        openIssues: 2,
      );

      // Judged against the date passed in, so the same policy becomes overdue
      // as time passes rather than staying frozen against a fixed reference.
      expect(policy.isReviewOverdue(DateTime(2026, 5, 31)), isFalse);
      expect(policy.isReviewOverdue(DateTime(2026, 6, 2)), isTrue);
    });

    test('open findings only count inspections still open', () {
      final open = InspectionReport(
        title: 'AICTE Extension of Approval',
        authority: 'AICTE',
        inspectedOn: DateTime(2026, 2, 10),
        inspector: 'Regional Officer',
        majorFindings: 2,
        minorFindings: 5,
        observations: 3,
        outcome: InspectionOutcome.actionRequired,
        closedOn: null,
      );
      final closed = InspectionReport(
        title: 'NAAC Peer Team Visit',
        authority: 'NAAC',
        inspectedOn: DateTime(2025, 9, 4),
        inspector: 'Peer Team Chair',
        majorFindings: 1,
        minorFindings: 3,
        observations: 2,
        outcome: InspectionOutcome.cleared,
        closedOn: DateTime(2025, 12, 1),
      );

      // Observations are not findings — only major and minor count.
      expect(open.totalFindings, 7);
      expect(closed.totalFindings, 4);

      final stillOpen = [open, closed]
          .where((i) => i.closedOn == null)
          .fold(0, (sum, i) => sum + i.totalFindings);

      expect(
        stillOpen,
        7,
        reason:
            'A closed inspection is settled. Counting its findings would keep '
            'reporting problems the institution has already resolved.',
      );
    });
  });

  group('Navigation wiring', () {
    test('Every destination has a unique label and path', () {
      final labels = kNavDestinations.map((d) => d.label).toSet();
      final paths = kNavDestinations.map((d) => d.path).toSet();

      expect(labels.length, kNavDestinations.length);
      expect(paths.length, kNavDestinations.length);
    });

    test('Every path is a well-formed root-level route', () {
      for (final destination in kNavDestinations) {
        expect(destination.path, startsWith('/'), reason: destination.label);
        expect(
          destination.path,
          isNot(endsWith('/')),
          reason: destination.label,
        );
        expect(
          destination.path.split('/').length,
          2,
          reason: '${destination.label} is not a root-level path',
        );
      }
    });
  });

  group('Number formatting', () {
    test('Rupees render in the expected Indian units', () {
      expect(NumberFormatter.rupees(48750000), '₹4.88 Cr');
      expect(NumberFormatter.rupees(4850000), '₹48.50 L');
      expect(NumberFormatter.rupees(9500), '₹9,500');
      expect(NumberFormatter.rupees(-4850000), '-₹48.50 L');
    });

    test('Thousands group correctly at every magnitude', () {
      expect(NumberFormatter.thousands(0), '0');
      expect(NumberFormatter.thousands(999), '999');
      expect(NumberFormatter.thousands(4740), '4,740');
      expect(NumberFormatter.thousands(1234567), '1,234,567');
    });

    test('Storage sizes step through KB, MB, and GB', () {
      expect(NumberFormatter.kilobytes(512), '512 KB');
      expect(NumberFormatter.kilobytes(2048), '2.0 MB');
      expect(NumberFormatter.kilobytes(2097152), '2.00 GB');
    });
  });
}
