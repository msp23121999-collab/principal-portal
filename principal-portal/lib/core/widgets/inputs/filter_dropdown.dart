import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_icons.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Generic labeled dropdown filter (department, semester, status, ...)
/// used across analytics and list screens.
class FilterDropdown<T> extends StatefulWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.label,
    this.width,
  });

  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final String? label;
  final double? width;

  @override
  State<FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final safeValue = widget.items.contains(widget.value)
        ? widget.value
        : (widget.items.isEmpty ? null : widget.items.first);

    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.border;
    Color textColor = AppColors.primaryText;
    Color iconColor = AppColors.accentBlue;

    if (_isFocused) {
      bgColor = AppColors.accentBlue.withValues(alpha: 0.08);
      borderColor = AppColors.accentBlue;
      textColor = AppColors.primaryText;
      iconColor = AppColors.accentBlue;
    } else if (_isHovered) {
      bgColor = AppColors.accentBlue.withValues(alpha: 0.04);
      borderColor = AppColors.accentBlue.withValues(alpha: 0.4);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _isFocused = hasFocus),
        child: SizedBox(
          width: widget.width,
          child: Container(
            // 48 is the minimum tap target both Material and the iOS HIG ask
            // for, and `meetsGuideline(androidTapTargetGuideline)` enforces.
            // These rendered at 25.7px — `isDense: true` plus 4px of padding —
            // so every filter on every analytics screen was under half the
            // required height. It is the whole filter bar, and it is the first
            // thing on the page.
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryText.withValues(alpha: 0.02),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                hoverColor: const Color(0xFFF0F7FF),
                focusColor: const Color(
                  0xFFF0F7FF,
                ), // Same for keyboard focus in menu
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  value: safeValue,
                  // Not dense. `isDense: true` collapses the button's own hit
                  // box to 25.7px, and it is the button — not the container
                  // around it — that carries the tap semantics, so padding the
                  // parent did not fix the target. False falls back to
                  // kMinInteractiveDimension (48).
                  isDense: false,
                  isExpanded: widget.width != null,
                  dropdownColor: const Color(0xFFFFFFFF),
                  elevation: 3,
                  icon: Icon(AppIcons.chevronDown, size: 20, color: iconColor),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: textColor),
                  selectedItemBuilder: (BuildContext context) {
                    return widget.items.map<Widget>((T item) {
                      return Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.label == null
                              ? widget.itemLabel(item)
                              : '${widget.label}: ${widget.itemLabel(item)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: textColor),
                        ),
                      );
                    }).toList();
                  },
                  items: [
                    for (final item in widget.items)
                      DropdownMenuItem<T>(
                        value: item,
                        child: _DropdownMenuItemWidget(
                          label: widget.label == null
                              ? widget.itemLabel(item)
                              : '${widget.label}: ${widget.itemLabel(item)}',
                          isSelected: item == safeValue,
                        ),
                      ),
                  ],
                  onChanged: (val) {
                    // Remove focus from the dropdown when an item is selected
                    FocusScope.of(context).unfocus();
                    widget.onChanged(val);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownMenuItemWidget extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _DropdownMenuItemWidget({
    required this.label,
    required this.isSelected,
  });

  @override
  State<_DropdownMenuItemWidget> createState() =>
      _DropdownMenuItemWidgetState();
}

class _DropdownMenuItemWidgetState extends State<_DropdownMenuItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor = widget.isSelected
        ? AppColors.softBlue
        : Colors.transparent;
    Color textColor = widget.isSelected
        ? AppColors.accentBlue
        : AppColors.primaryText;

    if (_isHovered && !widget.isSelected) {
      bgColor = AppColors.softBlue;
      textColor = AppColors.accentBlue;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
