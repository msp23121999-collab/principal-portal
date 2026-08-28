// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

class SnapshotCard extends StatelessWidget {
  final Function(int)? onNavigate;
  const SnapshotCard({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A), // Darker blue
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Academic Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'OFFICIAL SCHEDULE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  if (onNavigate != null) {
                    onNavigate!(1); // Academic Calendar
                  }
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineItem('24', 'MAY', 'Internal Assessment - II', 'Data Structures', '10:00 AM', const Color(0xFF8B5CF6)),
          const SizedBox(height: 16),
          _buildTimelineItem('28', 'MAY', 'Lab Submission', 'DBMS Lab', '11:59 PM', const Color(0xFF3B82F6)),
          const SizedBox(height: 16),
          _buildTimelineItem('02', 'JUN', 'Mid Semester Exam', 'Operating Systems', '09:30 AM', const Color(0xFF6366F1)),
          const SizedBox(height: 16),
          _buildTimelineItem('10', 'JUN', 'Project Review', 'Minor Project Phase - II', '02:00 PM', const Color(0xFF8B5CF6)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (onNavigate != null) {
                  onNavigate!(1); // Academic Calendar
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF1D4ED8)),
              label: const Text(
                'View Academic Calendar',
                style: TextStyle(
                  color: Color(0xFF1D4ED8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String day, String month, String title, String subtitle, String time, Color dateColor) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 48,
          decoration: BoxDecoration(
            color: dateColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(day, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: dateColor, height: 1.1)),
              Text(month, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: dateColor, letterSpacing: 0.5)),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Text(
            time,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dateColor),
          ),
        ),
      ],
    );
  }
}
