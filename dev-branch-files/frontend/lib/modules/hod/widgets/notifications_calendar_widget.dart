import 'package:flutter/material.dart';
import '../models/hod_models.dart';

class NotificationsCalendarWidget extends StatelessWidget {
  final List<NoticeItem> notices;

  const NotificationsCalendarWidget({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAcademicCalendarCard(context)),
              const SizedBox(width: 20),
              Expanded(child: _buildAcademicEventsCard(context)),
            ],
          );
        }

        return Column(
          children: [
            _buildAcademicCalendarCard(context),
            const SizedBox(height: 20),
            _buildAcademicEventsCard(context),
          ],
        );
      },
    );
  }

  // ── LEFT CARD: ACADEMIC CALENDAR ──
  Widget _buildAcademicCalendarCard(BuildContext context) {
    final daysOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final eventDates = notices
        .map((notice) => DateTime.tryParse(notice.date))
        .whereType<DateTime>()
        .toSet();
    final currentMonth = DateTime.now();
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Academic Calendar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'View Calendar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Month Navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 16),
              Text(
                '${_monthName(currentMonth.month)} ${currentMonth.year}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Days of Week Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((day) {
              return SizedBox(
                width: 34,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Grid of calendar dates with event markers from PostgreSQL.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 42,
            ),
            itemBuilder: (context, index) {
              final dateNum = index - firstDay.weekday % 7;
              if (dateNum < 1 || dateNum > daysInMonth) {
                // Dimmed next/prev month date
                final textVal = dateNum < 1
                    ? (DateTime(currentMonth.year, currentMonth.month, 0).day +
                              dateNum)
                          .toString()
                    : (dateNum - daysInMonth).toString();
                return Center(
                  child: Text(
                    textVal,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                );
              }

              final date = DateTime(
                currentMonth.year,
                currentMonth.month,
                dateNum,
              );
              final isToday =
                  date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final hasEventDot = eventDates.contains(date);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$dateNum',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  if (hasEventDot)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Footer Legend (Purple: Events, Green: Exams, Red: Holidays, Blue: Important)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(const Color(0xFF9333EA), 'Events'),
              _buildLegendItem(const Color(0xFF16A34A), 'Exams'),
              _buildLegendItem(const Color(0xFFDC2626), 'Holidays'),
              _buildLegendItem(const Color(0xFF2563EB), 'Important'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // ── RIGHT CARD: ACADEMIC EVENTS ──
  Widget _buildAcademicEventsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Academic Events',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {},
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (notices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No academic events available'),
              ),
            )
          else
            ...notices.take(4).map(_buildNoticeEventRow),
        ],
      ),
    );
  }

  Widget _buildNoticeEventRow(NoticeItem notice) {
    final date = DateTime.tryParse(notice.date);
    final dateColor = _categoryColor(notice.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildEventRow(
        month: date == null
            ? '---'
            : _monthName(date.month).substring(0, 3).toUpperCase(),
        day: date == null ? '0' : date.day.toString().padLeft(2, '0'),
        dayOfWeek: date == null ? '---' : _weekdayName(date.weekday),
        dateColor: dateColor,
        dateBg: dateColor.withValues(alpha: .08),
        title: notice.title.isEmpty ? 'null' : notice.title,
        time: notice.date.isEmpty ? 'null' : notice.date,
        badgeLabel: notice.category.isEmpty ? 'Event' : notice.category,
        badgeBg: dateColor.withValues(alpha: .08),
        badgeText: dateColor,
      ),
    );
  }

  String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  String _weekdayName(int weekday) =>
      const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][weekday - 1];

  Color _categoryColor(String category) {
    final value = category.toLowerCase();
    if (value.contains('exam') || value.contains('deadline'))
      return const Color(0xFFDC2626);
    if (value.contains('workshop') || value.contains('seminar'))
      return const Color(0xFF2563EB);
    if (value.contains('review')) return const Color(0xFF16A34A);
    return const Color(0xFF9333EA);
  }

  Widget _buildEventRow({
    required String month,
    required String day,
    required String dayOfWeek,
    required Color dateColor,
    required Color dateBg,
    required String title,
    required String time,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeText,
  }) {
    return Row(
      children: [
        // Date Box
        Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: dateBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                month,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: dateColor,
                ),
              ),
              Text(
                day,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: dateColor,
                  height: 1.1,
                ),
              ),
              Text(
                dayOfWeek,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: dateColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Title & Time Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Event Type Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeText,
            ),
          ),
        ),
      ],
    );
  }
}
