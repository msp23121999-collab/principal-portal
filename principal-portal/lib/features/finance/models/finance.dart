/// A headline financial figure with its movement against last year.
class FinanceKpi {
  const FinanceKpi({
    required this.label,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  final String label;
  final String value;
  final String trend;
  final bool isPositive;
}

/// Revenue against expenditure for one month of the financial year.
class MonthlyFinance {
  const MonthlyFinance({
    required this.month,
    required this.revenue,
    required this.expenditure,
  });

  final String month;

  /// Rupees received in the month.
  final double revenue;

  /// Rupees spent in the month.
  final double expenditure;

  double get surplus => revenue - expenditure;
}

/// Fee demand and collection position for one department.
class DepartmentFeeStatus {
  const DepartmentFeeStatus({
    required this.departmentCode,
    required this.departmentName,
    required this.studentsTotal,
    required this.studentsPaid,
    required this.demand,
    required this.collected,
  });

  final String departmentCode;
  final String departmentName;
  final int studentsTotal;
  final int studentsPaid;

  /// Total fee raised for the year.
  final double demand;

  /// Of that, how much has been received.
  final double collected;

  double get outstanding => demand - collected;

  double get collectionPercent => demand == 0 ? 0 : collected / demand * 100;

  int get studentsPending => studentsTotal - studentsPaid;
}

/// How fees arrived, by payment channel.
class PaymentModeSplit {
  const PaymentModeSplit({required this.mode, required this.amount});

  final String mode;
  final double amount;
}

/// A scholarship or fee-waiver scheme and what it has disbursed.
class ScholarshipScheme {
  const ScholarshipScheme({
    required this.name,
    required this.sponsor,
    required this.beneficiaries,
    required this.sanctioned,
    required this.disbursed,
  });

  final String name;

  /// Government body, trust, or the institution itself.
  final String sponsor;

  final int beneficiaries;
  final double sanctioned;
  final double disbursed;

  double get pending => sanctioned - disbursed;

  double get disbursedPercent =>
      sanctioned == 0 ? 0 : disbursed / sanctioned * 100;
}

/// Monthly payroll cost for one staff category.
class PayrollLine {
  const PayrollLine({
    required this.category,
    required this.headcount,
    required this.monthlyCost,
  });

  final String category;
  final int headcount;
  final double monthlyCost;

  double get annualCost => monthlyCost * 12;
}

/// Budget against actual spend for one expenditure head.
class ExpenditureHead {
  const ExpenditureHead({
    required this.head,
    required this.budgeted,
    required this.actual,
  });

  final String head;
  final double budgeted;
  final double actual;

  double get variance => budgeted - actual;

  double get utilisationPercent => budgeted == 0 ? 0 : actual / budgeted * 100;

  bool get isOverspent => actual > budgeted;
}
