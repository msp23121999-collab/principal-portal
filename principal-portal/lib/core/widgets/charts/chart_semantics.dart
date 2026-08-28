import 'package:flutter/widgets.dart';

/// Turns a chart into something a screen reader can read out.
///
/// fl_chart paints to a canvas. To assistive technology that is one unlabelled
/// rectangle, so every chart in the portal — which is where most of the meaning
/// on an analytics screen lives — was silent. A Principal using a screen reader
/// could reach the page and learn nothing from it.
///
/// The summary is generated from the chart's own data rather than written by
/// each call site. A hand-written label is a second copy of the figures that
/// drifts the moment the query behind it changes; this one cannot disagree with
/// what is drawn, because it is built from the same list.
///
/// Values are spoken, not the pixels. "Pass rate by department. 6 values. CSE
/// 92.4, ECE 88.1, …" is what a sighted reader takes from the chart at a
/// glance, and it is what this says.
class ChartSemantics {
  ChartSemantics._();

  /// How many points are read out before the summary stops.
  ///
  /// A twelve-department bar chart is useful read in full; a sixty-point trend
  /// line is not, and a screen reader cannot skim. Past this the summary gives
  /// the range and the count instead of every value.
  static const int maxSpokenPoints = 12;

  /// Wraps [child] so it announces [label] and hides its own painted internals.
  ///
  /// [ExcludeSemantics] matters: fl_chart emits semantics nodes for axis text,
  /// so without it a screen reader reads the summary and then every axis tick
  /// again as loose numbers.
  static Widget wrap({required String label, required Widget child}) {
    return Semantics(
      label: label,
      container: true,
      // Charts here are read-only; none is a control.
      readOnly: true,
      child: ExcludeSemantics(child: child),
    );
  }

  /// Builds `Pass rate. 3 values. CSE 92.4, ECE 88.1, MECH 79.` from a single
  /// series.
  static String describe(
    String kind,
    List<({String label, double value})> points, {
    String unit = '',
  }) {
    if (points.isEmpty) return '$kind. No data.';

    final suffix = unit.isEmpty ? '' : ' $unit';

    if (points.length > maxSpokenPoints) {
      final values = points.map((p) => p.value).toList()..sort();
      return '$kind. ${points.length} values, '
          'from ${_number(values.first)}$suffix '
          'to ${_number(values.last)}$suffix.';
    }

    final spoken = points
        .map((p) => '${p.label} ${_number(p.value)}$suffix')
        .join(', ');
    return '$kind. ${points.length} values. $spoken.';
  }

  /// Same, for a chart carrying more than one series.
  static String describeSeries(
    String kind,
    List<String> xLabels,
    List<({String label, List<double> values})> series, {
    String unit = '',
  }) {
    if (series.isEmpty || xLabels.isEmpty) return '$kind. No data.';

    final suffix = unit.isEmpty ? '' : ' $unit';
    final parts = <String>[];

    for (final s in series) {
      if (s.values.isEmpty) {
        parts.add('${s.label}: no data');
        continue;
      }
      // A trend is heard as a direction and a range far better than as a list
      // of forty numbers.
      final sorted = [...s.values]..sort();
      parts.add(
        '${s.label} from ${_number(s.values.first)}$suffix '
        'to ${_number(s.values.last)}$suffix, '
        'lowest ${_number(sorted.first)}$suffix, '
        'highest ${_number(sorted.last)}$suffix',
      );
    }

    return '$kind. ${xLabels.first} to ${xLabels.last}. ${parts.join('. ')}.';
  }

  /// Trims a trailing `.0` so a whole number is not read as "ninety two point
  /// zero", while a genuine fraction keeps one decimal.
  static String _number(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
