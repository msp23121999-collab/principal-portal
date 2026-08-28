import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/finance_repository.dart';
import '../models/finance.dart';

final financeRepositoryProvider = Provider((ref) => const FinanceRepository());

final financeKpisProvider = FutureProvider<List<FinanceKpi>>((ref) async {
  return (await ref.watch(financeRepositoryProvider).fetchKpis()).value;
});

final monthlyPositionProvider = FutureProvider<List<MonthlyFinance>>((
  ref,
) async {
  return (await ref.watch(financeRepositoryProvider).fetchMonthlyPosition())
      .value;
});

final paymentModesProvider = FutureProvider<List<PaymentModeSplit>>((
  ref,
) async {
  return (await ref.watch(financeRepositoryProvider).fetchPaymentModes()).value;
});

final scholarshipsProvider = FutureProvider<List<ScholarshipScheme>>((
  ref,
) async {
  return (await ref.watch(financeRepositoryProvider).fetchScholarships()).value;
});

final payrollProvider = FutureProvider<List<PayrollLine>>((ref) async {
  return (await ref.watch(financeRepositoryProvider).fetchPayroll()).value;
});

final expenditureHeadsProvider = FutureProvider<List<ExpenditureHead>>((
  ref,
) async {
  return (await ref.watch(financeRepositoryProvider).fetchExpenditure()).value;
});

/// Show only departments with money still outstanding.
final onlyOutstandingProvider = StateProvider<bool>((ref) => false);

final _allDepartmentFeesProvider = FutureProvider<List<DepartmentFeeStatus>>((
  ref,
) async {
  return (await ref.watch(financeRepositoryProvider).fetchDepartmentFees())
      .value;
});

final departmentFeesProvider = FutureProvider<List<DepartmentFeeStatus>>((
  ref,
) async {
  final onlyOutstanding = ref.watch(onlyOutstandingProvider);
  final rows = await ref.watch(_allDepartmentFeesProvider.future);
  if (!onlyOutstanding) return rows;
  return rows.where((row) => row.outstanding > 0).toList();
});

/// Institution-wide financial position, for the highlight card and the fee
/// tab's per-student figure.
///
/// Every value is derived from the tables the tabs already show, so a headline
/// figure can never contradict the rows beneath it.
typedef FinanceSummary = ({
  double surplus,
  double totalOutstanding,
  double annualFeePerStudent,
  int scholarshipBeneficiaries,
  int scholarshipSchemes,
  double annualPayroll,
});

final financeSummaryProvider = FutureProvider<FinanceSummary>((ref) async {
  final months = await ref.watch(monthlyPositionProvider.future);
  final fees = await ref.watch(_allDepartmentFeesProvider.future);
  final scholarships = await ref.watch(scholarshipsProvider.future);
  final payroll = await ref.watch(payrollProvider.future);

  final students = fees.fold(0, (sum, f) => sum + f.studentsTotal);
  final demand = fees.fold(0.0, (sum, f) => sum + f.demand);

  return (
    surplus: months.fold(0.0, (sum, m) => sum + m.surplus),
    totalOutstanding: fees.fold(0.0, (sum, f) => sum + f.outstanding),
    // Read back out of the demand rather than stored, so the figure on screen
    // always matches what the departments were actually billed.
    annualFeePerStudent: students == 0 ? 0.0 : demand / students,
    scholarshipBeneficiaries: scholarships.fold(
      0,
      (sum, s) => sum + s.beneficiaries,
    ),
    scholarshipSchemes: scholarships.length,
    annualPayroll: payroll.fold(0.0, (sum, p) => sum + p.annualCost),
  );
});
