import 'package:flutter/material.dart';

/// Corner radius scale.
///
/// [sm] and [md] carry the flat enterprise aesthetic used throughout the
/// portal's data surfaces — cards, tables, inputs, dialogs. Keep using those.
///
/// [lg] exists for standalone entrance surfaces only: the sign-in card, which
/// is a single object on an empty page rather than one tile among many. A
/// softer corner reads as welcoming there, and as sloppy on a dense dashboard.
/// If you are reaching for it inside the portal chrome, reach for [md] instead.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
}
