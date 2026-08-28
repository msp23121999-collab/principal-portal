import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Counts a figure up to its final value when it first appears.
///
/// KPI cards previously snapped straight to their number. Counting up is the
/// cue that separates a dashboard from a spreadsheet: it draws the eye to the
/// figure that changed, and it makes the page feel like it is reporting rather
/// than simply existing.
///
/// The value handed in is already formatted — `'1,240'`, `'87.6%'`, `'₹42.5L'`,
/// `'—'`. This splits off any prefix and suffix, animates only the numeric core,
/// and reassembles the string each frame, so grouping separators, currency
/// marks and units all survive.
///
/// Anything that does not contain a number is rendered unchanged and never
/// animates. An em dash means "not recorded", and counting up to a dash would
/// be nonsense.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.duration,
  });

  /// The formatted figure, exactly as it should read when the animation ends.
  final String value;
  final TextStyle? style;
  final Duration? duration;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration ?? AppMotion.slow,
  );

  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  /// Everything before the digits — a currency symbol, a sign.
  String _prefix = '';

  /// Everything after — `%`, `L`, `Cr`, ` LPA`.
  String _suffix = '';

  /// The numeric core, or null when the value carries no number at all.
  double? _target;

  /// Decimal places in the original, so `87.6%` does not animate to `88%`.
  int _decimals = 0;

  /// Whether the original grouped its thousands, so `1,240` stays grouped.
  bool _grouped = false;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _parse(widget.value);
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    // A filter changed and the figure with it. Re-run from zero rather than
    // leaving the previous number frozen on screen.
    _parse(widget.value);
    _controller
      ..reset()
      ..forward();
  }

  void _parse(String raw) {
    final match = RegExp(r'-?[\d,]*\.?\d+').firstMatch(raw);
    if (match == null) {
      _target = null;
      return;
    }

    final numeric = match.group(0)!;
    _prefix = raw.substring(0, match.start);
    _suffix = raw.substring(match.end);
    _grouped = numeric.contains(',');

    final plain = numeric.replaceAll(',', '');
    _target = double.tryParse(plain);

    final dot = plain.indexOf('.');
    _decimals = dot == -1 ? 0 : plain.length - dot - 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (_target == null || AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reinstates the thousands separators the original had.
  String _group(String digits) {
    if (!_grouped) return digits;
    final negative = digits.startsWith('-');
    final body = negative ? digits.substring(1) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      if (i > 0 && (body.length - i) % 3 == 0) buffer.write(',');
      buffer.write(body[i]);
    }
    return '${negative ? '-' : ''}$buffer';
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    if (target == null) {
      return Text(widget.value, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        final current = target * _progress.value;
        final text = current.toStringAsFixed(_decimals);
        final parts = text.split('.');
        final whole = _group(parts.first);
        final shown = parts.length > 1 ? '$whole.${parts[1]}' : whole;

        return Text(
          '$_prefix$shown$_suffix',
          style: widget.style,
          // The width changes as digits fill in; without this the card's
          // layout would nudge on every frame.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
