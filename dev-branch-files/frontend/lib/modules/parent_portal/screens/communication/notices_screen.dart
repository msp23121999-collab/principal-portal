import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../models/models.dart';
import '../../services/download_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String? _downloadingNoticeId;

  @override
  Widget build(BuildContext context) {
    final notices = MockData.mockNotices;
    final categories = ['All', 'College Fest', 'Placement', 'Academic', 'Fees'];

    final filteredNotices = notices.where((n) {
      final matchesCategory = _selectedCategory == 'All' || n.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          n.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Notices & Circular Announcements'),
            const SizedBox(height: 12),

            // ── Search & Filter Bar ───────────────────────────────────────
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search notices by title, keywords or category...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accentColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() => _searchQuery = ''))
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // ── Category Pills ────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      onSelected: (val) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Notices List ──────────────────────────────────────────────
            filteredNotices.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.campaign_outlined,
                    title: 'No notices found',
                    description: 'No announcements match the selected filter criteria.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredNotices.length,
                    itemBuilder: (context, index) {
                      final notice = filteredNotices[index];
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        onTap: () => _showNoticeDetailDialog(notice),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    notice.category.toUpperCase(),
                                    style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, size: 14, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${notice.date.day}/${notice.date.month}/${notice.date.year}',
                                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notice.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notice.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 14),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Published by Principal Office / Dean', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                const Text('Read Full Circular →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showNoticeDetailDialog(Notice notice) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 550),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      notice.category.toUpperCase(),
                      style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Text(notice.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Published on: ${notice.date.day}/${notice.date.month}/${notice.date.year} • KSRCE Office',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const Divider(height: 24),
              Text(notice.description, style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              PrimaryButton(
                text: 'Download Official PDF Circular',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () {
                  if (notice.pdfUrl != null && notice.pdfUrl!.isNotEmpty) {
                    _downloadCircular(notice);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Official PDF is not available.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCircular(Notice notice) async {
    if (notice.pdfUrl == null || notice.pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Official PDF is not available.')),
      );
      return;
    }

    try {
      final fileName = '${notice.title.replaceAll(' ', '_')}.pdf';
      final sanitized = DownloadService.sanitizeFilename(fileName);
      final success = await DownloadService.downloadFromUrl(notice.pdfUrl!, sanitized);

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started: $sanitized')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download circular. Please try again.')),
        );
      }
    }
  }
}
