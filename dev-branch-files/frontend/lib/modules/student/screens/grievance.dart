// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'dart:html' as html;

class GrievanceScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const GrievanceScreen({super.key, this.onNavigate});

  @override
  State<GrievanceScreen> createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends State<GrievanceScreen> {
  String _selectedRecipient = 'Faculty';
  final _customRecipientController = TextEditingController();
  String _selectedCategory = 'Academic';
  String _selectedPriority = 'Medium';
  final _subjectController = TextEditingController();
  final _descController = TextEditingController();
  String? _attachedFileName;
  bool _isRefreshingGrievances = false;
  int _currentGrievancePage = 1;

  @override
  void dispose() {
    _subjectController.dispose();
    _descController.dispose();
    _customRecipientController.dispose();
    super.dispose();
  }

  void _pickAttachment() {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*,application/pdf';
    input.click();
    input.onChange.listen((event) {
      if (input.files != null && input.files!.isNotEmpty) {
        final file = input.files![0];
        setState(() {
          _attachedFileName = file.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File "${file.name}" attached successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    });
  }

  void _submitGrievance(AppState appState) {
    final subjectText = _subjectController.text.trim();
    final descText = _descController.text.trim();

    if (subjectText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a short subject for your grievance!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (descText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter grievance description!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (RegExp(r'^\d+$').hasMatch(descText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grievance description cannot contain only numbers! Please enter a detailed description.'), backgroundColor: Colors.red),
      );
      return;
    }

    final recipientName = (_selectedRecipient == 'Others' && _customRecipientController.text.trim().isNotEmpty)
        ? _customRecipientController.text.trim()
        : _selectedRecipient;

    appState.addGrievance(
      _selectedCategory,
      subjectText,
      descText,
      DateTime.now().toString().split(' ')[0],
      recipientName,
      _selectedPriority,
    );

    _subjectController.clear();
    _descController.clear();
    _customRecipientController.clear();
    setState(() {
      _attachedFileName = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Grievance submitted successfully! Auto-routed to target authority.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _showGrievanceDetailModal(GrievanceModel item) {
    final replyTextController = TextEditingController();
    final bool isResolvedOrRejected = item.status.toLowerCase() == 'resolved' || item.status.toLowerCase() == 'rejected';

    Color statusColor;
    switch (item.status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'in review':
      case 'in progress':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusColor = const Color(0xFFD97706);
    }

    Color priorityColor;
    switch (item.priority.toLowerCase()) {
      case 'high':
        priorityColor = const Color(0xFFDC2626);
        break;
      case 'low':
        priorityColor = const Color(0xFF16A34A);
        break;
      default:
        priorityColor = const Color(0xFFD97706);
    }

    showDialog(
      context: context,
      builder: (modalContext) {
        final appState = AppStateProvider.of(modalContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 12),
              Expanded(child: Text(item.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1D4ED8), size: 20),
                tooltip: 'Reload latest response from authority',
                onPressed: () async {
                  await appState.refreshGrievances();
                  if (modalContext.mounted) {
                    Navigator.pop(modalContext);
                    final updatedItem = appState.grievances.firstWhere((g) => g.id == item.id, orElse: () => item);
                    _showGrievanceDetailModal(updatedItem);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Grievance response refreshed!'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                      child: Text('Category: ${item.category}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1D4ED8))),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text('Priority: ${item.priority}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: priorityColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Target Recipient: ${item.recipient}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                Text('Filed Date: ${item.date}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 14),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Text(item.description, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Current Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.status, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.response.isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: item.response.isNotEmpty ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.response.isNotEmpty ? Icons.forum_outlined : Icons.hourglass_empty_outlined, size: 16, color: item.response.isNotEmpty ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Text(
                            item.response.isNotEmpty ? 'Official Response / Resolution' : 'Official Response Pending',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: item.response.isNotEmpty ? const Color(0xFF15803D) : const Color(0xFFB45309)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.response.isNotEmpty ? item.response : 'Your grievance is currently under review by the recipient authority.',
                        style: TextStyle(fontSize: 12, color: item.response.isNotEmpty ? const Color(0xFF166534) : const Color(0xFF92400E), height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (!isResolvedOrRejected) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.reply_rounded, size: 16, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 6),
                            Text(
                              'Reply to Authority Response',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D4ED8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: replyTextController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Type your reply or follow-up clarification...',
                            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFBFDBFE))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFBFDBFE))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final replyMsg = replyTextController.text.trim();
                              if (replyMsg.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a reply message before sending!'), backgroundColor: Colors.red),
                                );
                                return;
                              }
                              appState.replyToGrievance(item.id, replyMsg);
                              Navigator.pop(modalContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reply sent successfully to assigned authority!'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            },
                            icon: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                            label: const Text('Send Reply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(modalContext), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isMobile = screenWidth < 900;
        final double paddingValue = isMobile ? 12.0 : 24.0;
        final double formPadding = isMobile ? 16.0 : 24.0;

        Widget buildLeftForm() {
          return Container(
            padding: EdgeInsets.all(formPadding),
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
                Row(
                  children: const [
                    Icon(Icons.assignment_outlined, color: Color(0xFF1D4ED8), size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'File a Grievance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLabel('Target Authority / Recipient', required: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRecipient,
                      items: const [
                        DropdownMenuItem(value: 'Faculty', child: Text('Faculty / Mentor')),
                        DropdownMenuItem(value: 'HOD', child: Text('Department HOD')),
                        DropdownMenuItem(value: 'Dean', child: Text('Dean')),
                        DropdownMenuItem(value: 'Principal', child: Text('Principal')),
                        DropdownMenuItem(value: 'Student Affairs', child: Text('Student Affairs')),
                        DropdownMenuItem(value: 'Others', child: Text('Others (Custom Recipient)')),
                      ],
                      onChanged: (val) => setState(() => _selectedRecipient = val!),
                    ),
                  ),
                ),
                if (_selectedRecipient == 'Others') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customRecipientController,
                    decoration: InputDecoration(
                      hintText: 'Enter Authority / Recipient Keyword...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Category', required: true),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedCategory,
                                items: const [
                                  DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                                  DropdownMenuItem(value: 'Infrastructure', child: Text('Infrastructure')),
                                  DropdownMenuItem(value: 'Hostel', child: Text('Hostel')),
                                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                  DropdownMenuItem(value: 'Fee', child: Text('Fee')),
                                  DropdownMenuItem(value: 'General', child: Text('General')),
                                ],
                                onChanged: (val) => setState(() => _selectedCategory = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Priority', required: true),
                          const SizedBox(height: 8),
                           Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedPriority,
                                items: [
                                  DropdownMenuItem(
                                    value: 'High',
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('High', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 11.5)),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Medium',
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Medium', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 11.5)),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Low',
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Low', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11.5)),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() => _selectedPriority = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLabel('Subject / Short Summary', required: true),
                const SizedBox(height: 8),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Lab Wi-Fi Connectivity Issue, Marks Discrepancy',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.short_text, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel('Detailed Description', required: true),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 5,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Describe your grievance in full detail...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 70),
                      child: Icon(Icons.article_outlined, color: Color(0xFF94A3B8)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_descController.text.length} / 1000',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLabel('Attachments', required: false, suffix: '(Optional)'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickAttachment,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: _attachedFileName != null
                          ? [
                              const Icon(Icons.insert_drive_file, color: Color(0xFF1D4ED8), size: 32),
                              const SizedBox(height: 8),
                              Text(_attachedFileName!, style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('File size: 1.2 MB', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _attachedFileName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ]
                          : [
                              const Icon(Icons.cloud_upload_outlined, color: Color(0xFF1D4ED8), size: 24),
                              const SizedBox(height: 4),
                              const Text('Drag & drop files here or browse', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 14)),
                              const Text('PDF, JPG, PNG (Max. 5MB each)', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: isMobile ? double.infinity : null,
                  child: ElevatedButton.icon(
                    onPressed: () => _submitGrievance(appState),
                    icon: const Icon(Icons.send, color: Colors.white, size: 16),
                    label: const Text(
                      'Submit Grievance',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        Widget buildRightSidebar() {
          final orderedGrievances = appState.grievances.toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          final totalItems = orderedGrievances.length;
          const pageSize = 4;
          final totalPages = (totalItems / pageSize).ceil().clamp(1, 999);

          if (_currentGrievancePage > totalPages) {
            _currentGrievancePage = totalPages;
          }

          final startIndex = (totalItems == 0) ? 0 : (_currentGrievancePage - 1) * pageSize;
          final endIndex = (startIndex + pageSize).clamp(0, totalItems);
          final pagedGrievances = totalItems == 0 ? <GrievanceModel>[] : orderedGrievances.sublist(startIndex, endIndex);

          final startDisplay = totalItems == 0 ? 0 : startIndex + 1;
          final endDisplay = endIndex;

          return Column(
            children: [
              // Recent Grievances
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.forum_outlined, color: Color(0xFF7C3AED), size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Recent Grievances',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _isRefreshingGrievances
                              ? null
                              : () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  setState(() => _isRefreshingGrievances = true);
                                  await appState.refreshGrievances();
                                  if (!mounted) return;
                                  setState(() => _isRefreshingGrievances = false);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Refreshed latest grievance responses from authority!'),
                                      backgroundColor: Color(0xFF10B981),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                          borderRadius: BorderRadius.circular(8),
                           child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD8B4FE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isRefreshingGrievances
                                    ? const SizedBox(
                                        width: 11,
                                        height: 11,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF7C3AED)),
                                      )
                                    : const Icon(Icons.refresh, size: 11, color: Color(0xFF7C3AED)),
                                const SizedBox(width: 5),
                                const Text(
                                    'Reload Responses',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (orderedGrievances.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 40, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'No grievances filed yet',
                              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Column(
                        children: pagedGrievances.map((g) {
                          return InkWell(
                            onTap: () => _showGrievanceDetailModal(g),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildRecentGrievance(g),
                            ),
                          );
                        }).toList(),
                      ),
                      _buildGrievancePagination(totalItems, totalPages, startDisplay, endDisplay),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                buildLeftForm(),
                const SizedBox(height: 24),
                buildRightSidebar(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: buildLeftForm(),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: buildRightSidebar(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, {required bool required, String? suffix}) {
    return Row(
      children: [
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFEF4444),
            ),
          ),
        if (suffix != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              suffix,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrievancePagination(int totalItems, int totalPages, int startDisplay, int endDisplay) {
    if (totalItems <= 4) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Showing $startDisplay to $endDisplay of $totalItems grievances',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _currentGrievancePage > 1
                    ? () => setState(() => _currentGrievancePage--)
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: _currentGrievancePage > 1 ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              for (int p = 1; p <= totalPages; p++) ...[
                InkWell(
                  onTap: () => setState(() => _currentGrievancePage = p),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _currentGrievancePage == p ? const Color(0xFF2563EB) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$p',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentGrievancePage == p ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
              ],
              InkWell(
                onTap: _currentGrievancePage < totalPages
                    ? () => setState(() => _currentGrievancePage++)
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: _currentGrievancePage < totalPages ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF10B981), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGrievance(GrievanceModel item) {
    Color statusColor;
    switch (item.status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'in review':
      case 'in progress':
        statusColor = const Color(0xFF2563EB);
        break;
      case 'rejected':
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusColor = const Color(0xFFD97706);
    }

    Color priorityColor;
    switch (item.priority.toLowerCase()) {
      case 'high':
        priorityColor = const Color(0xFFDC2626);
        break;
      case 'low':
        priorityColor = const Color(0xFF16A34A);
        break;
      default:
        priorityColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.subject,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'To: ${item.recipient} • ${item.date}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          if (item.response.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.forum_outlined, size: 12, color: Color(0xFF15803D)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Response: ${item.response}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
