import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';

/// Fades a widget in, optionally drifting it up a few pixels as it arrives.
///
/// Used for content that appears after a wait — a section resolving, an empty
/// or error state replacing a skeleton. A panel that simply blinks into
/// existence reads as a glitch; the same panel easing in over a fifth of a
/// second reads as the page finishing its work.
///
/// The movement is deliberately small. This is an administrator's daily tool,
/// so motion should confirm a change happened and then get out of the way.
///
/// Honours the platform's reduce-motion setting: when that is on, the child is
/// returned as-is with no animation and no delay. Nothing here carries
/// information, so skipping it costs the reader nothing.
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration,
    this.offsetY = 8,
  });

  final Widget child;

  /// Stagger offset. Use [AppMotion.stagger] for lists so items arrive in
  /// sequence rather than all at once.
  final Duration delay;

  /// Defaults to [AppMotion.normal].
  final Duration? duration;

  /// Pixels to travel upward while fading in. Zero fades in place.
  final double offsetY;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  Duration get _duration => widget.duration ?? AppMotion.normal;

  /// The delay is folded into the controller's own span rather than scheduled
  /// on a timer.
  ///
  /// An earlier version waited with `Future.delayed`, which cannot be
  /// cancelled: a staggered page torn down mid-entrance left one uncancellable
  /// timer per band still pending, and a widget test that pumped without
  /// settling failed with "Pending timers". Running the controller over
  /// delay + duration and holding the animation at zero for the delay's share
  /// via an [Interval] produces the same staggered arrival with no timer at
  /// all, and disposing the controller cleans up everything.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.delay + _duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: _curve,
  );

  Curve get _curve {
    final total = (widget.delay + _duration).inMicroseconds;
    if (total <= 0) return AppMotion.enter;
    final start = widget.delay.inMicroseconds / total;
    if (start <= 0) return AppMotion.enter;
    return Interval(start, 1, curve: AppMotion.enter);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AppMotion.reduced(context)) {
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

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;

    return FadeTransition(
      opacity: _fade,
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _fade.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
