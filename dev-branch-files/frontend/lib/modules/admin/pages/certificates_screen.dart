import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../widgets/app_responsive.dart';
import '../utils/file_downloader.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String _searchQuery = '';
  String _typeFilter = 'All';

  final List<Map<String, dynamic>> _fallbackData = [
    {
      'id': 'CERT-2026-089',
      'student': 'Aravind Swamy',
      'regNo': '731522104001',
      'dept': 'CSE',
      'type': 'Bonafide Certificate',
      'date': '24 Jul 2026',
      'status': 'Approved',
      'purpose': 'Passport Application'
    },
    {
      'id': 'CERT-2026-090',
      'student': 'Bhavana Devi',
      'regNo': '731522104002',
      'dept': 'ECE',
      'type': 'Transfer Certificate (TC)',
      'date': '23 Jul 2026',
      'status': 'Approved',
      'purpose': 'Higher Studies Abroad'
    },
    {
      'id': 'CERT-2026-091',
      'student': 'Charan Kumar',
      'regNo': '731522106015',
      'dept': 'MECH',
      'type': 'Conduct Certificate',
      'date': '22 Jul 2026',
      'status': 'Pending',
      'purpose': 'Job Application / HR Review'
    },
    {
      'id': 'CERT-2026-092',
      'student': 'Divya Bharathi',
      'regNo': '731522205022',
      'dept': 'EEE',
      'type': 'Academic Transcript',
      'date': '21 Jul 2026',
      'status': 'Approved',
      'purpose': 'WES Credential Evaluation'
    },
    {
      'id': 'CERT-2026-093',
      'student': 'Eshwar Sharma',
      'regNo': '731522104044',
      'dept': 'CSE',
      'type': 'Course Completion Certificate',
      'date': '20 Jul 2026',
      'status': 'Approved',
      'purpose': 'Degree Convocation'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _data = List.from(_fallbackData);
      _loading = false;
    });
  }

  void _showCertificatePreviewModal(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Certificate Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0052CC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF0052CC), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Digital Certificate Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          Text('ID: ${item['id']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Mock Certificate Graphic Border
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD97706), width: 3),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.school_rounded, size: 40, color: Color(0xFF0052CC)),
                    const SizedBox(height: 8),
                    const Text('KSR COLLEGE OF ENGINEERING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Color(0xFF0F172A))),
                    const Text('Tiruchengode, Tamil Nadu — 637215', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    Text((item['type'] as String).toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    const SizedBox(height: 16),
                    Text(
                      'This is to certify that Mr./Ms. ${item['student']} (Reg No: ${item['regNo']}) of ${item['dept']} Department has been issued this ${item['type']} for the purpose of ${item['purpose']}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.qr_code_2_rounded, size: 36, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text('Scan to Verify', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
                          ],
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Dr. P. Murugesan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('Principal & Controller of Exams', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      final fname = '${item['student'].toString().replaceAll(" ", "_")}_${item['type'].toString().replaceAll(" ", "_")}.pdf';
                      FileDownloader.downloadPdf(filename: fname);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloaded $fname to local system!'),
                          backgroundColor: const Color(0xFF0052CC),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Official PDF'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0052CC), foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIssueCertificateSheet() {
    final nameCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'CSE');
    final purposeCtrl = TextEditingController(text: 'Higher Education / Passport');
    var typeVal = 'Bonafide Certificate';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Color(0xFF0052CC)),
                        SizedBox(width: 10),
                        Text('Issue New Certificate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Student Full Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: regCtrl,
                  decoration: const InputDecoration(labelText: 'Register Number (12 Digits)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  decoration: const InputDecoration(labelText: 'Department / Discipline', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: typeVal,
                  decoration: const InputDecoration(labelText: 'Certificate Type', border: OutlineInputBorder()),
                  items: [
                    'Bonafide Certificate',
                    'Transfer Certificate (TC)',
                    'Conduct Certificate',
                    'Academic Transcript',
                    'Course Completion Certificate'
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => typeVal = v!,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(labelText: 'Purpose of Issue', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && regCtrl.text.isNotEmpty) {
                      final newEntry = <String, dynamic>{
                        'id': 'CERT-2026-0${_data.length + 94}',
                        'student': nameCtrl.text,
                        'regNo': regCtrl.text,
                        'dept': deptCtrl.text,
                        'type': typeVal,
                        'date': '08 Aug 2026',
                        'status': 'Approved',
                        'purpose': purposeCtrl.text,
                      };
                      setState(() => _data.insert(0, newEntry));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Certificate issued successfully for ${nameCtrl.text}!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Generate & Sign Certificate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    final filteredData = _data.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item['student'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['regNo'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesType = _typeFilter == 'All' || item['type'] == _typeFilter;

      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderBanner(context),
              const SizedBox(height: 20),
              _buildMetricsSummary(),
              const SizedBox(height: 20),
              _buildSearchFilterToolbar(context),
              const SizedBox(height: 20),
              _buildCertificatesListCard(context, filteredData),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER BANNER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeaderBanner(BuildContext context) {
    final isMobile = AppResponsive.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHeaderBadgeIcon(),
                    _buildStatusPill(),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Certificates & Transcripts',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: AppTypography.fontFamily,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Issue official Bonafide, Transfer (TC), Conduct, and Academic Transcripts with QR verification.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75), height: 1.4),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _buildIssueButton(),
                ),
              ],
            )
          : Row(
              children: [
                _buildHeaderBadgeIcon(),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Certificates & Transcripts',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStatusPill(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Issue official Bonafide, Transfer (TC), Conduct, and Academic Transcripts with QR verification.',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.75)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildIssueButton(),
              ],
            ),
    );
  }

  Widget _buildHeaderBadgeIcon() => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 30),
    );

  Widget _buildStatusPill() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
          SizedBox(width: 6),
          Text('Digital QR Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF34D399))),
        ],
      ),
    );

  Widget _buildIssueButton() => ElevatedButton.icon(
      onPressed: _showIssueCertificateSheet,
      icon: const Icon(Icons.add_moderator_rounded, size: 18),
      label: const Text('Issue New Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );

  // ───────────────────────────────────────────────────────────────────────────
  // METRICS SUMMARY CHIPS
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMetricsSummary() => LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int count = width < 600 ? 2 : 4;
        final itemWidth = (width - (count - 1) * 12) / count;

        final metrics = [
          {'title': 'Total Issued', 'val': '${_data.length}', 'icon': Icons.verified_rounded, 'color': const Color(0xFF3B82F6)},
          {'title': 'Pending Requests', 'val': '1 Request', 'icon': Icons.pending_actions_rounded, 'color': const Color(0xFFF59E0B)},
          {'title': 'Bonafide Active', 'val': '840 Docs', 'icon': Icons.badge_rounded, 'color': const Color(0xFF10B981)},
          {'title': 'TC & Transcripts', 'val': '580 Docs', 'icon': Icons.description_rounded, 'color': const Color(0xFF8B5CF6)},
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.map((m) {
            final color = m['color'] as Color;
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF64748B).withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(m['icon'] as IconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['val'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          Text(m['title'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

  // ───────────────────────────────────────────────────────────────────────────
  // SEARCH & FILTER TOOLBAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchFilterToolbar(BuildContext context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, register number, or CERT ID...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Text('Type: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                const SizedBox(width: 8),
                ...['All', 'Bonafide Certificate', 'Transfer Certificate (TC)', 'Conduct Certificate', 'Academic Transcript'].map((type) {
                  final isSel = _typeFilter == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(type),
                      selected: isSel,
                      selectedColor: const Color(0xFF0052CC).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF0052CC),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? const Color(0xFF0052CC) : const Color(0xFF475569),
                      ),
                      onSelected: (sel) => setState(() => _typeFilter = type),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );

  // ───────────────────────────────────────────────────────────────────────────
  // CERTIFICATES LIST CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCertificatesListCard(BuildContext context, List<Map<String, dynamic>> items) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Certificate Registry (${items.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    const Text('Official digital certificates issued by Controller of Examinations', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.folder_off_rounded, size: 48, color: Color(0xFF94A3B8)),
                  SizedBox(height: 12),
                  Text('No certificates found matching criteria.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (ctx, i) => const Divider(height: 24, color: Color(0xFFE2E8F0)),
              itemBuilder: (ctx, idx) {
                final item = items[idx];
                final isApproved = item['status'] == 'Approved';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isApproved ? Icons.verified_rounded : Icons.pending_rounded,
                        color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(item['type'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['status'] as String,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isApproved ? const Color(0xFF059669) : const Color(0xFFD97706)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Student: ${item['student']} • Reg No: ${item['regNo']} (${item['dept']})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CERT ID: ${item['id']} • Date: ${item['date']} • Purpose: ${item['purpose']}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Preview Certificate',
                          icon: const Icon(Icons.visibility_rounded, color: Color(0xFF0052CC)),
                          onPressed: () => _showCertificatePreviewModal(item),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final fname = '${item['student'].toString().replaceAll(" ", "_")}_${item['type'].toString().replaceAll(" ", "_")}.pdf';
                            FileDownloader.downloadPdf(filename: fname);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloaded $fname to local system!'),
                                backgroundColor: const Color(0xFF0052CC),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
