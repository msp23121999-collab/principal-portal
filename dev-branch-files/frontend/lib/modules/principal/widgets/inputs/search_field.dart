import 'package:flutter/material.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';
import '../../core/principal_compat.dart';

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
          prefixIcon: const Icon(
            AppIcons.search,
            size: 20,
            color: AppColors.secondaryText,
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: AppRadius.smRadius,
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
