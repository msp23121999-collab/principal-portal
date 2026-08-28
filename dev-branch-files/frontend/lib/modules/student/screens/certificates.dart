// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import '../models/app_state.dart';

class CertificatesScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const CertificatesScreen({super.key, this.onNavigate});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  void _showRequestCertificateModal(AppState appState) {
    String certType = 'Bonafide Certificate';
    final purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Request Official Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Certificate Type:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: certType,
                    items: const [
                      DropdownMenuItem(value: 'Bonafide Certificate', child: Text('Bonafide Certificate')),
                      DropdownMenuItem(value: 'Conduct Certificate', child: Text('Conduct Certificate')),
                      DropdownMenuItem(value: 'Provisional Certificate', child: Text('Provisional Certificate')),
                      DropdownMenuItem(value: 'Transfer Certificate (TC)', child: Text('Transfer Certificate (TC)')),
                    ],
                    onChanged: (val) => setModalState(() => certType = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purposeController,
                    decoration: const InputDecoration(labelText: 'Purpose / Reason (e.g. Bank Loan, Passport)'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (purposeController.text.isNotEmpty) {
                      appState.requestCertificate(
                        certType,
                        'Requested for ${purposeController.text}',
                        DateTime.now().toString().split(' ')[0],
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Certificate request submitted to Principal Office!'), backgroundColor: Color(0xFF10B981)),
                      );
                    }
                  },
                  child: const Text('Submit Request'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _downloadCertificate(CertificateModel cert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${cert.title} PDF (Verified Digital Copy)...'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showCertificateDetails(CertificateModel cert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(cert.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${cert.status}', style: TextStyle(fontWeight: FontWeight.bold, color: cert.status == 'Available' ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
              const SizedBox(height: 8),
              Text('Issued / Requested Date: ${cert.issuedOn}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text('Valid Upto: ${cert.validUpto}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              Text('Description: ${cert.desc}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
            ],
          ),
          actions: [
            if (cert.status == 'Available')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadCertificate(cert);
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Download PDF'),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final certificates = appState.certificates;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showRequestCertificateModal(appState),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Request Certificate'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Banner
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0F2FE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1D4ED8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your Achievements, Verified',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Download and manage your official certificates issued by the institution.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildCertificateGraphic(),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Grid Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Certificates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cards Grid
          Row(
            children: certificates.map((cert) {
              final isAvailable = cert.status == 'Available';
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildCertificateCard(
                    context,
                    icon: Icons.description_outlined,
                    iconColor: isAvailable ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
                    title: cert.title,
                    statusText: cert.status.toUpperCase(),
                    statusColor: isAvailable ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B),
                    desc: cert.desc,
                    issuedOn: cert.issuedOn,
                    validUpto: cert.validUpto,
                    actionText: isAvailable ? 'Download' : 'View Details',
                    actionIcon: isAvailable ? Icons.download_outlined : Icons.visibility_outlined,
                    onAction: () {
                      if (isAvailable) {
                        _downloadCertificate(cert);
                      } else {
                        _showCertificateDetails(cert);
                      }
                    },
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Important Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEF3C7)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Important Note',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Some certificates require verification and approval from the respective departments.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showRequestCertificateModal(appState),
                  icon: const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF1D4ED8)),
                  label: const Text(
                    'Certificate Requests',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateGraphic() {
    return SizedBox(
      width: 200,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(left: 10, bottom: 20, child: const Icon(Icons.star, color: Color(0xFFBFDBFE), size: 16)),
          Positioned(right: 10, top: 20, child: const Icon(Icons.star, color: Color(0xFFBFDBFE), size: 16)),
          Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF93C5FD), width: 2),
            ),
            child: Stack(
              children: [
                Positioned(top: 15, left: 15, child: Container(width: 50, height: 4, color: const Color(0xFFE2E8F0))),
                Positioned(top: 30, left: 15, child: Container(width: 80, height: 4, color: const Color(0xFFE2E8F0))),
                Positioned(top: 45, left: 15, child: Container(width: 70, height: 4, color: const Color(0xFFE2E8F0))),
                Positioned(top: 60, left: 15, child: Container(width: 40, height: 4, color: const Color(0xFFE2E8F0))),
              ],
            ),
          ),
          Positioned(
            bottom: 5,
            right: 40,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 14),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 12, color: const Color(0xFF60A5FA)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 12, color: const Color(0xFF60A5FA)),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: 15,
            child: Container(
              width: 30,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF93C5FD),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String statusText,
    required Color statusColor,
    required String desc,
    required String issuedOn,
    required String validUpto,
    String issuedLabel = 'Issued On',
    String validLabel = 'Valid Upto',
    required String actionText,
    required IconData actionIcon,
    required VoidCallback onAction,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              issuedLabel,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          issuedOn,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          validLabel,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          validUpto,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(actionIcon, color: iconColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    actionText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: iconColor, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
