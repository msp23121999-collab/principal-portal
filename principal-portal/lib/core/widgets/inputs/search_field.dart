import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';

/// Standard search input used in the top bar and list screens (faculty,
/// students, notifications).
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.hintText = 'Search...',
    this.onChanged,
    this.controller,
    this.width,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
          prefixIcon: Icon(
            AppIcons.search,
            size: 20,
            color: Theme.of(context).iconTheme.color ?? AppColors.secondaryText,
          ),
          filled: true,
          fillColor:
              Theme.of(context).inputDecorationTheme.fillColor ??
              AppColors.background,
          border:
              Theme.of(context).inputDecorationTheme.border ??
              OutlineInputBorder(
                borderRadius: AppRadius.smRadius,
                borderSide: const BorderSide(color: AppColors.border),
              ),
          enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
          focusedBorder: Theme.of(context).inputDecorationTheme.focusedBorder,
        ),
      ),
    );
  }
}
