import 'package:intl/intl.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/repository.dart';
import '../models/finance.dart';

/// Reads Finance Overview from `principal`.
///
/// `student.fees` exists but records per-student billing, which is a different
/// question from institutional revenue, payroll and expenditure. Aggregating a
/// table built for another purpose would tie the Principal's finance figures to
/// the Student Portal's billing cycle, so these are separate records.
class FinanceRepository extends Repository {
  const FinanceRepository();

  /// The month column is a real date so it sorts and ranges correctly.
  /// The screen wants a short label, which is a presentation concern.
  static final DateFormat _monthLabel = DateFormat('MMM yyyy');

  Future<Sourced<List<FinanceKpi>>> fetchKpis() {
    return load<List<FinanceKpi>>(
      debugLabel: 'principal.kpi_snapshots (finance)',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('kpi_snapshots')
            .select()
            .eq('module', 'finance')
            .order('display_order', ascending: true);

        return [
          for (final raw in rows)
            FinanceKpi(
              label: Map<String, dynamic>.from(raw).strOr('label', ''),
              value: Map<String, dynamic>.from(raw).strOr('value', '—'),
              trend: Map<String, dynamic>.from(raw).strOr('trend', ''),
              isPositive: Map<String, dynamic>.from(
                raw,
              ).boolOr('is_positive', true),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<MonthlyFinance>>> fetchMonthlyPosition() {
    return load<List<MonthlyFinance>>(
      debugLabel: 'principal.monthly_finance',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        // The chart shows a rolling year; the table holds three.
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('monthly_finance')
            .select()
            .order('month', ascending: false)
            .limit(12);

        final months = [
          for (final raw in rows) _toMonthly(Map<String, dynamic>.from(raw)),
        ];

        // Fetched newest-first to get the latest twelve, displayed oldest-first
        // so the line reads left to right.
        return months.reversed.toList();
      },
    );
  }

  Future<Sourced<List<DepartmentFeeStatus>>> fetchDepartmentFees() {
    return load<List<DepartmentFeeStatus>>(
      debugLabel: 'principal.department_fee_status',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(
          DbSchema.principal,
        ).from('department_fee_status').select('*, departments(code, name)');

        return [
          for (final raw in rows) _toFeeStatus(Map<String, dynamic>.from(raw)),
        ];
      },
    );
  }

  Future<Sourced<List<PaymentModeSplit>>> fetchPaymentModes() {
    return load<List<PaymentModeSplit>>(
      debugLabel: 'principal.payment_mode_splits',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('payment_mode_splits')
            .select()
            .order('amount', ascending: false);

        return [
          for (final raw in rows)
            PaymentModeSplit(
              mode: Map<String, dynamic>.from(raw).strOr('mode', ''),
              amount: Map<String, dynamic>.from(raw).doubleOr('amount', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<ScholarshipScheme>>> fetchScholarships() {
    return load<List<ScholarshipScheme>>(
      debugLabel: 'principal.scholarship_schemes',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('scholarship_schemes')
            .select()
            .order('sanctioned', ascending: false);

        return [
          for (final raw in rows)
            ScholarshipScheme(
              name: Map<String, dynamic>.from(raw).strOr('name', ''),
              sponsor: Map<String, dynamic>.from(raw).strOr('sponsor', ''),
              beneficiaries: Map<String, dynamic>.from(
                raw,
              ).intOr('beneficiaries', 0),
              sanctioned: Map<String, dynamic>.from(
                raw,
              ).doubleOr('sanctioned', 0),
              disbursed: Map<String, dynamic>.from(
                raw,
              ).doubleOr('disbursed', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<PayrollLine>>> fetchPayroll() {
    return load<List<PayrollLine>>(
      debugLabel: 'principal.payroll_lines',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('payroll_lines')
            .select()
            .order('monthly_cost', ascending: false);

        return [
          for (final raw in rows)
            PayrollLine(
              category: Map<String, dynamic>.from(raw).strOr('category', ''),
              headcount: Map<String, dynamic>.from(raw).intOr('headcount', 0),
              monthlyCost: Map<String, dynamic>.from(
                raw,
              ).doubleOr('monthly_cost', 0),
            ),
        ];
      },
    );
  }

  Future<Sourced<List<ExpenditureHead>>> fetchExpenditure() {
    return load<List<ExpenditureHead>>(
      debugLabel: 'principal.expenditure_heads',
      isEmpty: (rows) => rows.isEmpty,
      fromSupabase: () async {
        final rows = await ApiClient.schema(DbSchema.principal)
            .from('expenditure_heads')
            .select()
            .order('budgeted', ascending: false);

        return [
          for (final raw in rows)
            ExpenditureHead(
              head: Map<String, dynamic>.from(raw).strOr('head', ''),
              budgeted: Map<String, dynamic>.from(raw).doubleOr('budgeted', 0),
              actual: Map<String, dynamic>.from(raw).doubleOr('actual', 0),
            ),
        ];
      },
    );
  }

  MonthlyFinance _toMonthly(Map<String, dynamic> row) => MonthlyFinance(
    month: _monthLabel.format(row.dateOr('month', DateTime.now())),
    revenue: row.doubleOr('revenue', 0),
    expenditure: row.doubleOr('expenditure', 0),
  );

  DepartmentFeeStatus _toFeeStatus(Map<String, dynamic> row) {
    final dept = row['departments'];
    final map = dept is Map ? Map<String, dynamic>.from(dept) : null;

    return DepartmentFeeStatus(
      departmentCode: map?.strOr('code', '') ?? '',
      departmentName: map?.strOr('name', '') ?? '',
      studentsTotal: row.intOr('students_total', 0),
      studentsPaid: row.intOr('students_paid', 0),
      demand: row.doubleOr('demand', 0),
      collected: row.doubleOr('collected', 0),
    );
  }
}
