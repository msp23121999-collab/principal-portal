import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';

class HostelScreen extends StatelessWidget {
  const HostelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = MockData.selectedStudent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Hostel Accommodation & Facilities'),
            const SizedBox(height: 16),

            if (student.hostelName != null && student.hostelName!.isNotEmpty) ...[
              // ── Main Hostel Details Card ─────────────────────────────────
              CustomCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.domain_rounded, color: AppTheme.primaryColor, size: 32),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.hostelName!,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Room Number: ${student.roomNumber}',
                                style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(status: 'ACTIVE RESIDENT'),
                      ],
                    ),
                    const Divider(height: 32),

                    Row(
                      children: [
                        Expanded(child: _buildInfoBox('Warden Name', student.wardenName ?? 'Dr. P. Murugan', Icons.person_outline_rounded)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoBox('Room Type', '3-Sharing AC Room', Icons.bed_rounded)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInfoBox('Rent & Mess Fee', 'Paid & Verified', Icons.verified_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Mess Schedule Card ───────────────────────────────────────
              const SectionHeader(title: "Daily Mess Menu & Timings"),
              CustomCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _messRow('Breakfast', '07:30 AM - 08:45 AM', 'Idli, Sambar, Chutney, Poori & Tea/Coffee'),
                    const Divider(),
                    _messRow('Lunch', '12:30 PM - 02:00 PM', 'South Indian Meals, Rice, Rasam, Curd, Kootu & Poriyal'),
                    const Divider(),
                    _messRow('Evening Snacks', '04:30 PM - 05:30 PM', 'Tea / Coffee & Sundal / Samosa'),
                    const Divider(),
                    _messRow('Dinner', '07:30 PM - 08:45 PM', 'Chapathi, Veg Kurma, Special Rice & Milk'),
                  ],
                ),
              ),
            ] else
              const EmptyStateWidget(
                icon: Icons.domain_disabled_rounded,
                title: 'No Hostel Details Registered',
                description: 'This student is registered as a Day Scholar.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messRow(String meal, String time, String menu) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor)),
                Text(time, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Expanded(
            child: Text(menu, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class TransportScreen extends StatelessWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = MockData.selectedStudent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Transport & Bus Pass Details'),
            const SizedBox(height: 16),

            if (student.busNumber != null && student.busNumber!.isNotEmpty) ...[
              CustomCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: AppTheme.accentColor, size: 32),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.busNumber!,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Route: ${student.route}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const StatusBadge(status: 'PASS ACTIVE'),
                      ],
                    ),
                    const Divider(height: 32),

                    Row(
                      children: [
                        Expanded(child: _infoTile('Pickup Point', student.pickupPoint ?? 'N/A', Icons.place_outlined)),
                        const SizedBox(width: 16),
                        Expanded(child: _infoTile('Pickup Time', student.pickupTime ?? 'N/A', Icons.access_time_rounded)),
                        const SizedBox(width: 16),
                        Expanded(child: _infoTile('Driver Name', 'Mr. G. Periasamy', Icons.person_pin_rounded)),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              EmptyStateWidget(
                icon: Icons.no_transfer_rounded,
                title: 'No Transport Details Registered',
                description: 'This student does not use college bus transportation.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
