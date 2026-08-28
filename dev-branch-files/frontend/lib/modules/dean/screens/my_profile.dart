import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/supabase_service.dart';
import '../theme.dart';
import '../widgets/bento_card.dart';

class DeanProfileScreen extends StatefulWidget {
  const DeanProfileScreen({super.key});

  @override
  State<DeanProfileScreen> createState() => _DeanProfileScreenState();
}

class _DeanProfileScreenState extends State<DeanProfileScreen> {
  PlatformFile? _selectedSignatureFile;

  Future<void> _pickSignatureFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final selectedFile = result.files.first;
      final bytes = selectedFile.bytes;
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to read signature file bytes.')));
        return;
      }

      setState(() {
        _selectedSignatureFile = selectedFile;
      });

      final safeName = selectedFile.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final path = 'signatures/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      print('[DEAN TRACE] UPLOAD Supabase Storage bucket: dean_signatures path: $path');
      final res = await DeanSupabaseService.instance.uploadRepositoryFile(
        bucket: 'dean_signatures',
        path: path,
        bytes: bytes,
        contentType: selectedFile.extension != null ? 'image/${selectedFile.extension}' : 'image/png',
      );
      print('[DEAN TRACE] UPLOAD Supabase Storage success: ${res != null}');

      final filePath = res != null ? path : (selectedFile.path ?? selectedFile.name);
      if (mounted) {
        DeanAppStateProvider.of(context).updateDigitalSignature(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res != null ? 'Uploaded signature to Supabase Storage: ${selectedFile.name}' : 'Signature selected (Storage upload failed).'),
            backgroundColor: res != null ? DeanTheme.successGreen : DeanTheme.warningAmber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting signature: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoCard(
            title: 'Official Executive Profile',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(color: DeanTheme.primaryBlue, borderRadius: BorderRadius.circular(20)),
                  child: const Center(
                    child: Text('RK', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dr. R. K. Sharma', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                      const SizedBox(height: 4),
                      const Text('Dean Academics • K.S.R. College of Engineering (Autonomous)', style: TextStyle(fontSize: 13, color: DeanTheme.textMuted)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: DeanTheme.primaryBlue),
                          const SizedBox(width: 6),
                          const Text('dean.academics@ksrce.ac.in', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                          const SizedBox(width: 20),
                          const Icon(Icons.phone_outlined, size: 16, color: DeanTheme.primaryBlue),
                          const SizedBox(width: 6),
                          const Text('+91 94432 10987', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DeanTheme.textDark)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          BentoCard(
            title: 'Digital Signature & Official Stamp for Result Sign-Offs',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload your verified PNG digital signature with transparent background. This will be applied to signed mark sheets and BoS degree approvals.', style: TextStyle(fontSize: 11, color: DeanTheme.textMuted)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 220,
                      height: 80,
                      decoration: BoxDecoration(
                        color: DeanTheme.bgCanvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DeanTheme.cardBorder),
                      ),
                      child: Center(
                        child: Text(
                          _selectedSignatureFile != null
                              ? _selectedSignatureFile!.name
                              : '[ Signed: Dr. R. K. Sharma ]',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: DeanTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _pickSignatureFile,
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: Text(_selectedSignatureFile == null ? 'Select file to upload' : 'Change file'),
                    ),
                  ],
                ),
                if (_selectedSignatureFile != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Selected file: ${_selectedSignatureFile!.name}',
                    style: const TextStyle(fontSize: 12, color: DeanTheme.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
