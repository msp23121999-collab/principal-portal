import 'dart:convert';
import 'dart:html' as html;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class DigitalRepositoryScreen extends StatefulWidget {
  const DigitalRepositoryScreen({super.key});

  @override
  State<DigitalRepositoryScreen> createState() => _DigitalRepositoryScreenState();
}

class _DigitalRepositoryScreenState extends State<DigitalRepositoryScreen> {
  bool _isUploading = false;

  Future<void> _loadRepositoryData(DeanAppState appState) async {
    if (appState.repositoryDocumentsData.isEmpty) {
      final items = await DeanSupabaseService.instance.getDeanRepositoryDocuments();
      if (items.isNotEmpty) {
        appState.repositoryDocumentsData = items;
        if (mounted) setState(() {});
      }
    }
  }

  Future<void> _uploadFile() async {
    final appState = DeanAppStateProvider.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes ?? await Future.value(null);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to read selected file bytes.')));
        }
        return;
      }

      setState(() => _isUploading = true);
      final safeName = (file.name).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storagePath = 'dean_repository/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final upload = await DeanSupabaseService.instance.uploadRepositoryFile(
        bucket: 'dean_repository',
        path: storagePath,
        bytes: bytes,
        contentType: file.extension != null ? 'application/${file.extension}' : 'application/octet-stream',
      );

      if (upload == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repository upload failed.')));
        }
        return;
      }

      final payload = {
        'title': file.name,
        'file_name': file.name,
        'file_url': storagePath,
        'storage_path': storagePath,
        'category': 'Academic Document',
        'department': 'Dean Office',
        'uploaded_by': 'Dean Office',
        'version': 'v1',
        'visibility': 'Dean Office',
        'status': 'ACTIVE',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final saved = await DeanSupabaseService.instance.addRepositoryMetadata(payload);
      if (saved != null) {
        appState.repositoryDocumentsData.insert(0, Map<String, dynamic>.from(saved));
      } else {
        appState.repositoryDocumentsData.insert(0, Map<String, dynamic>.from(payload));
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploaded ${file.name} to the Dean repository.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteDocument(String id, String? storagePath, String fileName) async {
    final appState = DeanAppStateProvider.of(context);
    try {
      if (storagePath != null && storagePath.isNotEmpty) {
        await DeanSupabaseService.instance.deleteRepositoryFile(bucket: 'dean_repository', path: storagePath);
      }
      final deleted = await DeanSupabaseService.instance.deleteRepositoryDocument(id);
      if (deleted) {
        appState.repositoryDocumentsData.removeWhere((doc) => doc['id'] == id);
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $fileName from the repository.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Future<void> _previewOrDownload(Map<String, dynamic> row, {bool asDownload = false}) async {
    final fileName = (row['file_name'] ?? row['title'] ?? 'document').toString();
    final storagePath = (row['storage_path'] ?? row['file_url'] ?? '').toString();
    final signedUrl = await DeanSupabaseService.instance.getRepositorySignedUrl(bucket: 'dean_repository', path: storagePath);
    final resolvedUrl = signedUrl ?? (storagePath.isNotEmpty ? 'https://jnpvzmbisqzbmhkexhwr.supabase.co/storage/v1/object/public/dean_repository/$storagePath' : null);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No preview URL available for this file.')));
      }
      return;
    }

    final anchor = html.AnchorElement(href: resolvedUrl)
      ..setAttribute('download', asDownload ? fileName : '')
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    if (asDownload) {
      anchor.click();
    } else {
      anchor.target = '_blank';
      anchor.click();
    }
    anchor.remove();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(asDownload ? 'Downloading $fileName...' : 'Opening $fileName...')),
      );
    }
  }

  Widget _buildFolderCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: DeanTheme.cardBorder)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                Text(count, style: const TextStyle(fontSize: 10, color: DeanTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildFileRow(BuildContext context, Map<String, dynamic> row) {
    final name = (row['file_name'] ?? row['title'] ?? 'Document').toString();
    final category = (row['category'] ?? 'Academic Document').toString();
    final dept = (row['department'] ?? 'Dean Office').toString();
    final size = (row['file_size'] ?? '—').toString();
    final author = (row['uploaded_by'] ?? 'Dean Office').toString();
    final storagePath = (row['storage_path'] ?? row['file_url'] ?? '').toString();
    final isPdf = name.toLowerCase().contains('.pdf') || name.toLowerCase().contains('.doc') || name.toLowerCase().contains('.docx');

    return DataRow(
      cells: [
        DataCell(Row(
          children: [
            Icon(isPdf ? Icons.picture_as_pdf : Icons.description, color: isPdf ? Colors.red : DeanTheme.primaryBlue, size: 16),
            const SizedBox(width: 8),
            Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        )),
        DataCell(Text(category)),
        DataCell(Text(dept)),
        DataCell(Text(size)),
        DataCell(Text(author)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _previewOrDownload(row),
              icon: const Icon(Icons.open_in_new, color: DeanTheme.primaryBlue, size: 18),
              tooltip: 'Preview',
            ),
            IconButton(
              onPressed: () => _previewOrDownload(row, asDownload: true),
              icon: const Icon(Icons.download, color: DeanTheme.successGreen, size: 18),
              tooltip: 'Download',
            ),
            IconButton(
              onPressed: () => _deleteDocument(row['id']?.toString() ?? '', storagePath, name),
              icon: const Icon(Icons.delete_outline, color: DeanTheme.dangerRose, size: 18),
              tooltip: 'Delete',
            ),
          ],
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = DeanAppStateProvider.of(context);
    _loadRepositoryData(appState);
    final repoItems = appState.repositoryDocumentsData;

    if (appState.hasLoaded && repoItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'No repository records are available yet. Upload a file or wait for live Supabase metadata to appear.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: DeanTheme.textMuted),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildFolderCard('Dean Repository', '${repoItems.length} files', Icons.folder, DeanTheme.primaryBlue)),
              const SizedBox(width: 14),
              Expanded(child: _buildFolderCard('Active Regulations', '${repoItems.where((r) => (r['category'] ?? '').toString().toLowerCase().contains('regulation')).length}', Icons.rule_folder, DeanTheme.successGreen)),
              const SizedBox(width: 14),
              Expanded(child: _buildFolderCard('Question Bank', '${repoItems.where((r) => (r['category'] ?? '').toString().toLowerCase().contains('question')).length}', Icons.quiz, DeanTheme.warningAmber)),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _uploadFile,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload File'),
                  style: ElevatedButton.styleFrom(backgroundColor: DeanTheme.primaryBlue, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BentoCard(
            title: 'Central Digital Repository File Explorer',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('File Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Department', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('File Size', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Uploaded By', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: repoItems.map((row) => _buildFileRow(context, row)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
