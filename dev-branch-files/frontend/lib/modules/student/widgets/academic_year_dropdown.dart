import 'package:flutter/material.dart';
import '../models/app_state.dart';

class AcademicYearDropdown extends StatelessWidget {
  const AcademicYearDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    var value = appState.selectedAcademicYear;

    // Use live list from Supabase if available; otherwise fall back to defaults
    final List<String> years = appState.availableAcademicYears.isNotEmpty
        ? appState.availableAcademicYears
        : ['2023-24', '2024-25', '2025-26', '2026-27'];

    // Safety guard: if selected value is not in the list, pick the last item
    if (!years.contains(value)) {
      value = years.last;
    }

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
          alignment: Alignment.center,
          onChanged: (String? newValue) {
            if (newValue != null) {
              appState.setAcademicYear(newValue);
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return years.map<Widget>((String val) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'AY $val',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: years.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'AY $val',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
