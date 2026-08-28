import 'package:flutter/material.dart';

/// Corner radius scale. Two sizes only, matching the flat enterprise
/// aesthetic — nothing above [md] should ever be used.
class AppRadius {
  AppRadius._();

  static const double sm = 12;
  static const double md = 16;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
}
