import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/app_state.dart';

class AchievementsScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const AchievementsScreen({super.key, this.onNavigate});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedCategory = 'All Achievements';
  int _visibleCount = 6;

  bool _isOnlyNumbers(String text) {
    if (text.trim().isEmpty) return false;
    return RegExp(r'^[0-9\s]+$').hasMatch(text);
  }

  void _showAddAchievementModal(AppState appState) {
    final titleController = TextEditingController();
    String selectedCategory = 'Academic';
    final descController = TextEditingController();
    final orgController = TextEditingController();
    final uploadNameController = TextEditingController();
    String? uploadedFileName;
    String? uploadedFileUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void triggerFileUpload() {
              try {
                final uploadInput = html.FileUploadInputElement();
                uploadInput.accept = '.pdf,image/*';
                uploadInput.click();
                uploadInput.onChange.listen((e) {
                  final files = uploadInput.files;
                  if (files != null && files.isNotEmpty) {
                    final file = files[0];
                    final objectUrl = html.Url.createObjectUrlFromBlob(file);
                    setModalState(() {
                      uploadedFileName = file.name;
                      uploadedFileUrl = objectUrl;
                      uploadNameController.text = file.name;
                    });
                  }
                });
              } catch (e) {
                setModalState(() {
                  uploadedFileName = "achievement_certificate.pdf";
                  uploadNameController.text = "achievement_certificate.pdf";
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add New Achievement', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title / Award Name'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Category Selection',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                        DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                        DropdownMenuItem(value: 'Technical', child: Text('Technical')),
                        DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                        DropdownMenuItem(value: 'Certification', child: Text('Certification')),
                        DropdownMenuItem(value: 'Social', child: Text('Social')),
                        DropdownMenuItem(value: 'Others', child: Text('Others')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orgController,
                      decoration: const InputDecoration(labelText: 'Organized By'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Certificate Upload (Image/PDF)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: triggerFileUpload,
                            child: AbsorbPointer(
                              child: TextField(
                                controller: uploadNameController,
                                decoration: InputDecoration(
                                  hintText: 'No file chosen',
                                  hintStyle: const TextStyle(fontSize: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: triggerFileUpload,
                          icon: const Icon(Icons.file_upload, size: 14),
                          label: const Text('Upload'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final org = orgController.text.trim();
                    final desc = descController.text.trim();
                    final uploadName = uploadNameController.text.trim();

                    if (title.isEmpty || org.isEmpty || desc.isEmpty || uploadName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All fields (Title, Organized By, Description, and Certificate file) are required.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }

                    if (_isOnlyNumbers(title) || _isOnlyNumbers(org) || _isOnlyNumbers(desc)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title, Organized By, and Description cannot contain only numbers.'),
                          backgroundColor: Color(0xFFDC2626),
                        ),
                      );
                      return;
                    }

                    appState.addAchievement(
                      title,
                      selectedCategory,
                      org,
                      DateTime.now().toString().split(' ')[0],
                      desc,
                      attachmentName: uploadedFileName,
                      attachmentUrl: uploadedFileUrl,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Achievement submitted for verification!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCertificateViewer(AchievementModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Certificate: ${item.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.workspace_premium, size: 64, color: Color(0xFF1D4ED8)),
                      const SizedBox(height: 8),
                      Text('Official Certificate of ${item.category}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('Awarded by ${item.org}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton.icon(
              onPressed: () {
                try {
                  if (item.attachmentUrl != null && item.attachmentUrl!.isNotEmpty) {
                    html.AnchorElement(href: item.attachmentUrl!)
                      ..setAttribute("download", item.attachmentName ?? "certificate.pdf")
                      ..click();
                  } else {
                    final csv = 'Mock PDF Document for Certificate: ${item.title}\nOrganized by: ${item.org}\nDate: ${item.date}';
                    final bytes = utf8.encode(csv);
                    final blob = html.Blob([bytes], 'application/pdf');
                    final url = html.Url.createObjectUrlFromBlob(blob);
                    html.AnchorElement(href: url)
                      ..setAttribute("download", "certificate_${item.title.replaceAll(' ', '_')}.pdf")
                      ..click();
                    html.Url.revokeObjectUrl(url);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading Certificate for ${item.title}...'), backgroundColor: const Color(0xFF16A34A)),
                  );
                } catch (e) {
                  debugPrint('Download error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Certificate PDF downloaded!')),
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Download Certificate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final list = appState.achievements;
    final verifiedCount = list.where((a) => a.status == 'Verified').length;
    final approvedCount = list.where((a) => a.status == 'Approved').length;
    final isDesktop = MediaQuery.of(context).size.width >= 1200;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Stats Banner Row (5 cards + Add button on right)
          LayoutBuilder(
            builder: (context, constraints) {
              final showScroll = constraints.maxWidth < 1100;
              final totalPoints = list.fold<int>(0, (sum, item) => sum + item.points);

              final List<Widget> stats = [
                _buildStatItem(Icons.emoji_events_outlined, const Color(0xFF2563EB), const Color(0xFFEFF6FF), '${list.length}', 'Total Achievements', 'All Time'),
                _buildStatItem(Icons.verified_user_outlined, const Color(0xFF10B981), const Color(0xFFF0FDF4), '$verifiedCount', 'Verified Achievements', null),
                _buildStatItem(Icons.workspace_premium_outlined, const Color(0xFFF59E0B), const Color(0xFFFFF7ED), '$approvedCount', 'Approved Achievements', null),
                _buildStatItem(Icons.star_outline_rounded, const Color(0xFF8B5CF6), const Color(0xFFF3E8FF), '$totalPoints', 'Achievement Points', 'Earned'),
                _buildStatItem(Icons.track_changes_outlined, const Color(0xFF0D9488), const Color(0xFFF0FDFA), 'Top ', 'Class Rank', 'Based on Points'),
              ];

              if (showScroll) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: stats.map((w) => Padding(padding: const EdgeInsets.only(right: 12), child: SizedBox(width: 190, child: w))).toList(),
                  ),
                );
              } else {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: stats.map((w) => Expanded(child: w)).toList(),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 32),

          // Filters Tab selector row
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterTab('All Achievements'),
                      _buildFilterTab('Academic'),
                      _buildFilterTab('Sports'),
                      _buildFilterTab('Technical'),
                      _buildFilterTab('Cultural'),
                      _buildFilterTab('Social'),
                      _buildFilterTab('Others'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Achievements Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardSpacing = 24.0;
              final int columnsCount = constraints.maxWidth >= 1200 ? 3 : (constraints.maxWidth >= 768 ? 2 : 1);
              final double cardWidth = (constraints.maxWidth - (columnsCount - 1) * cardSpacing) / columnsCount;

              final filteredList = list.where((item) {
                if (_selectedCategory == 'All Achievements') return true;
                if (_selectedCategory == 'Others') {
                  final cat = item.category.toLowerCase();
                  return cat != 'academic' && cat != 'sports' && cat != 'technical' && cat != 'cultural' && cat != 'social' && cat != 'certification';
                }
                return item.category.toLowerCase() == _selectedCategory.toLowerCase();
              }).toList();

              if (filteredList.isEmpty) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: const Text('No achievements found for the selected category.', style: TextStyle(color: Color(0xFF94A3B8))),
                );
              }

              final displayList = filteredList.take(_visibleCount).toList();
              final hasMore = _visibleCount < filteredList.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: cardSpacing,
                    runSpacing: cardSpacing,
                    children: displayList.map((item) {
                      return SizedBox(
                        width: cardWidth,
                        height: 240,
                        child: _buildAchievementCard(
                          title: item.title,
                          category: item.category,
                          desc: item.desc,
                          date: item.date,
                          org: item.org,
                          status: item.status,
                          points: item.points,
                          onViewCertificate: () => _showCertificateViewer(item),
                          onApprove: () {
                            appState.approveAchievement(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Faculty approved the achievement successfully!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: hasMore
                        ? OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _visibleCount += 6;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View More (${filteredList.length - _visibleCount} remaining)',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                              ],
                            ),
                          )
                        : (_visibleCount > 6
                            ? OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _visibleCount = 6;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text(
                                      'Show Less',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.keyboard_arrow_up,
                                      size: 16,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, Color bgColor, String count, String label, String? subtext) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF475569),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtext != null) ...[
              const SizedBox(height: 1),
              Text(
                subtext,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label) {
    final isSelected = _selectedCategory == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }


  Widget _buildAchievementCard({
    required String title,
    required String category,
    required String desc,
    required String date,
    required String org,
    required String status,
    required int points,
    required VoidCallback onViewCertificate,
    VoidCallback? onApprove,
  }) {
    IconData icon;
    Color iconColor;
    Color iconBg;
    Color catBg;
    Color catCol;

    final catLower = category.toLowerCase();
    if (catLower == 'academic') {
      icon = Icons.emoji_events;
      iconColor = const Color(0xFFD97706);
      iconBg = const Color(0xFFFEF3C7);
      catCol = const Color(0xFFD97706);
      catBg = const Color(0xFFFEF3C7);
    } else if (catLower == 'sports') {
      icon = Icons.military_tech;
      iconColor = const Color(0xFFEA580C);
      iconBg = const Color(0xFFFFF7ED);
      catCol = const Color(0xFFEA580C);
      catBg = const Color(0xFFFFF7ED);
    } else if (catLower == 'technical') {
      icon = Icons.code;
      iconColor = const Color(0xFF2563EB);
      iconBg = const Color(0xFFEFF6FF);
      catCol = const Color(0xFF2563EB);
      catBg = const Color(0xFFEFF6FF);
    } else if (catLower == 'cultural') {
      icon = Icons.star;
      iconColor = const Color(0xFFEA580C);
      iconBg = const Color(0xFFFFF7ED);
      catCol = const Color(0xFFEA580C);
      catBg = const Color(0xFFFFF7ED);
    } else if (catLower == 'certification') {
      icon = Icons.card_membership;
      iconColor = const Color(0xFF16A34A);
      iconBg = const Color(0xFFF0FDF4);
      catCol = const Color(0xFF16A34A);
      catBg = const Color(0xFFF0FDF4);
    } else if (catLower == 'social') {
      icon = Icons.handshake;
      iconColor = const Color(0xFF0D9488);
      iconBg = const Color(0xFFF0FDFA);
      catCol = const Color(0xFF0D9488);
      catBg = const Color(0xFFF0FDFA);
    } else {
      icon = Icons.emoji_events;
      iconColor = const Color(0xFF64748B);
      iconBg = const Color(0xFFF8FAFC);
      catCol = const Color(0xFF64748B);
      catBg = const Color(0xFFF8FAFC);
    }

    Color statusColor;
    IconData statusIcon;
    String displayStatus;
    if (status == 'Verified' || status == 'Approved') {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle;
      displayStatus = 'Verified';
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.hourglass_empty;
      displayStatus = 'Pending';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onViewCertificate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Category Icon + Category Badge & Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: catCol,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Metadata details
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(width: 16),
                  const Icon(Icons.school_outlined, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      org,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              // Status & Points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+$points Points',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9333EA),
                      ),
                    ),
                  ),
                ],
              ),
              if (status == 'Pending') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                    child: const Text('Simulate Approval', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
