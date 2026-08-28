import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../models/models.dart';
import '../../services/download_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _selectedCategory = 'All';
  String? _downloadingDocId;

  @override
  Widget build(BuildContext context) {
    final docs = MockData.mockDocuments;
    final categories = ['All', 'Academic Marksheets', 'Fee Receipts', 'Identity & Certificates', 'Hall Tickets'];

    final filteredDocs = docs.where((d) {
      if (_selectedCategory == 'All') return true;
      return d.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Official Document Vault'),
            const SizedBox(height: 12),

            // ── Category Pills ────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryColor,
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

            // ── Documents Grid / List ─────────────────────────────────────
            filteredDocs.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.folder_open_outlined,
                    title: 'No documents in this category',
                    description: 'Select another category to view academic and financial transcripts.',
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      return CustomCard(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor, size: 28),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentColor.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          doc.category.toUpperCase(),
                                          style: const TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Uploaded: ${doc.date.day}/${doc.date.month}/${doc.date.year}',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SecondaryButton(
                              text: 'Preview',
                              icon: Icons.visibility_outlined,
                              onPressed: () {
                                if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) {
                                  _previewDocument(doc);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Document is not available for preview.')),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: IconButton(
                                icon: _downloadingDocId == doc.id
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download_for_offline_rounded, color: AppTheme.accentColor, size: 28),
                                onPressed: doc.fileUrl != null && doc.fileUrl!.isNotEmpty && _downloadingDocId != doc.id
                                    ? () => _downloadDocument(doc)
                                    : null,
                                tooltip: doc.fileUrl != null && doc.fileUrl!.isNotEmpty ? 'Download document' : 'Document not available',
                              ),
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

  void _previewDocument(AppDocument doc) {
    if (doc.fileUrl == null || doc.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document is not available for preview.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(doc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_rounded, size: 64, color: AppTheme.primaryColor),
                      const SizedBox(height: 12),
                      Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Official Verified College Document', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Preview in Browser',
                      icon: Icons.open_in_new_rounded,
                      onPressed: () {
                        Navigator.pop(ctx);
                        DownloadService.previewFile(doc.fileUrl!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Download',
                      icon: Icons.file_download_rounded,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _downloadDocument(doc);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadDocument(AppDocument doc) async {
    if (doc.fileUrl == null || doc.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document is currently unavailable.')),
      );
      return;
    }

    setState(() => _downloadingDocId = doc.id);

    try {
      final fileName = '${doc.name.replaceAll(' ', '_')}.pdf';
      final sanitized = DownloadService.sanitizeFilename(fileName);
      final success = await DownloadService.downloadFromUrl(doc.fileUrl!, sanitized);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started: $sanitized')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download failed. Please try again.')),
          );
        }
        setState(() => _downloadingDocId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download document. Please try again.')),
        );
        setState(() => _downloadingDocId = null);
      }
    }
  }
}
