import 'package:flutter/material.dart';

/// Sugar getters so widgets read `context.textTheme.titleLarge` instead of
/// the more verbose `Theme.of(context).textTheme.titleLarge` everywhere.
extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  Size get screenSize => MediaQuery.sizeOf(this);
}
