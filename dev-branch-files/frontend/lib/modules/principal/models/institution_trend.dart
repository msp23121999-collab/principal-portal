/// A single year's value in a multi-year trend series (admissions,
/// academic growth, faculty growth, student growth).
class YearlyMetric {
  const YearlyMetric({required this.year, required this.value});

  final String year;
  final double value;
}

/// One institution-wide KPI card (total students, total faculty, overall
/// pass %, NAAC/accreditation-style figures) shown on Institution Analytics.
class InstitutionKpi {
  const InstitutionKpi({
    required this.label,
    required this.value,
    required this.trendPercent,
    required this.isPositive,
  });

  final String label;
  final String value;
  final String trendPercent;
  final bool isPositive;
}
