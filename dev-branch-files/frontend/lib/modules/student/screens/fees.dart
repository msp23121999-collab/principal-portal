// ignore_for_file: deprecated_member_use, unused_element, unused_field, prefer_final_fields
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../models/app_state.dart';
import '../widgets/academic_year_dropdown.dart';

class FeesScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  const FeesScreen({super.key, this.onNavigate});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  String _selectedSem = 'V';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    final appState = AppState.instance;
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    String targetSem = _selectedSem;
    if (!sems.contains(targetSem)) {
      targetSem = sems.first;
    }

    final hasCache = appState.hasCachedFees(appState.selectedAcademicYear, targetSem);
    if (!hasCache) {
      _isLoading = true;
    }

    try {
      await appState.refreshFeesOnly(
        academicYear: appState.selectedAcademicYear,
        semester: targetSem,
      );
    } catch (e) {
      debugPrint("Error loading fees: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _triggerPaymentRedirect() {
    html.window.open('https://erp.ksrei.org/PrimeERP_KSR/Login.aspx', '_blank');
  }

  Widget _buildPillDropdown<T>({
    required IconData icon,
    required String prefixText,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF2563EB), size: 16),
          alignment: Alignment.center,
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((T val) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 13),
                  const SizedBox(width: 5),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: items.map<DropdownMenuItem<T>>((T val) {
            return DropdownMenuItem<T>(
              value: val,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFF2563EB), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '$prefixText ${val.toString().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);

    final payButton = Container(
      height: 34,
      child: ElevatedButton.icon(
        onPressed: _triggerPaymentRedirect,
        icon: const Icon(Icons.payment_rounded, size: 12, color: Colors.white),
        label: const Text(
          'Pay Online',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          elevation: 0,
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const AcademicYearDropdown(),
          const SizedBox(width: 8),
          payButton,
          const SizedBox(width: 8),
          _buildPillDropdown<String>(
            icon: Icons.school_outlined,
            prefixText: 'SEMESTER',
            value: _selectedSem,
            items: sems,
            onChanged: (v) {
              if (v != null) {
                setState(() => _selectedSem = v);
                _loadFees();
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amt) {
    String val = amt.round().toString();
    if (val.length <= 3) return '₹$val';
    String lastThree = val.substring(val.length - 3);
    String other = val.substring(0, val.length - 3);
    String result = '';
    int count = 0;
    for (int i = other.length - 1; i >= 0; i--) {
      result = other[i] + result;
      count++;
      if (count == 2 && i != 0) {
        result = ',$result';
        count = 0;
      }
    }
    return '₹$result,$lastThree';
  }

  int _semToNum(String sem) {
    final trimmed = sem.trim().toUpperCase();
    final parsed = int.tryParse(trimmed);
    if (parsed != null) return parsed;
    switch (trimmed) {
      case 'I': return 1;
      case 'II': return 2;
      case 'III': return 3;
      case 'IV': return 4;
      case 'V': return 5;
      case 'VI': return 6;
      case 'VII': return 7;
      case 'VIII': return 8;
      default: return 0;
    }
  }

  String? _lastAcademicYear;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final sems = appState.getAvailableSemestersForYear(appState.selectedAcademicYear);
    if (!sems.contains(_selectedSem)) {
      _selectedSem = sems.first;
    }

    final selectedAy = appState.selectedAcademicYear;
    final selectedSem = _selectedSem;

    if (_lastAcademicYear != selectedAy) {
      _lastAcademicYear = selectedAy;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFees();
      });
    }

    // Filter fees strictly matching the selected academic year and semester
    final activeFeeList = appState.fees.where((f) {
      final matchesYear = f.academicYear.isEmpty || f.academicYear == selectedAy || f.academicYear.contains(selectedAy) || selectedAy.contains(f.academicYear);
      final matchesSem = f.semester.isEmpty || _semToNum(f.semester) == _semToNum(selectedSem);
      return matchesYear && matchesSem;
    }).toList();

    final List<Map<String, dynamic>> breakdownItems = [];
    for (var f in activeFeeList) {
      breakdownItems.add({
        'title': f.title,
        'category': f.category,
        'amount': f.amount,
        'isPaid': f.isPaid,
        'dueDate': f.dueDate,
        'receiptNo': f.receiptNo,
        'paymentDate': f.paymentDate,
      });
    }

    final double totalFees = breakdownItems.fold(0.0, (sum, item) => sum + (item['amount'] as double));
    final double paidAmount = breakdownItems.where((item) => item['isPaid'] == true).fold(0.0, (sum, item) => sum + (item['amount'] as double));
    final double pendingAmount = (totalFees - paidAmount).clamp(0.0, totalFees);
    final double progressPercent = totalFees > 0 ? (paidAmount / totalFees).clamp(0.0, 1.0) : (activeFeeList.isNotEmpty ? 1.0 : 0.0);

    final unpaidFees = activeFeeList.where((f) => !f.isPaid).toList();
    unpaidFees.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final String nextDueDate = unpaidFees.isNotEmpty ? unpaidFees.first.dueDate : (totalFees > 0 ? 'All Cleared' : '-');
    final String nextDueSubtitle = unpaidFees.isNotEmpty ? 'For ${unpaidFees.first.title}' : (totalFees > 0 ? 'No pending dues' : 'No dues for this semester');

    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 768 && !isDesktop;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildTopMetricsRow(totalFees, paidAmount, pendingAmount, nextDueDate, nextDueSubtitle, isDesktop, isTablet),
              const SizedBox(height: 24),
              _buildMiddleSection(totalFees, paidAmount, pendingAmount, progressPercent, nextDueDate, nextDueSubtitle, breakdownItems, isDesktop, isTablet),
            ],
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.55),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopMetricsRow(
    double total, double paid, double pending, String dueDate, String dueSubtitle,
    bool isDesktop, bool isTablet
  ) {
    final double spacing = 16.0;
    int crossAxisCount = 4;
    if (!isDesktop && !isTablet) {
      crossAxisCount = 1;
    } else if (isTablet) {
      crossAxisCount = 2;
    }

    return LayoutBuilder(builder: (context, constraints) {
      final double width = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
      final cards = [
        _buildMetricCard(
          title: 'Total Fees',
          amount: _formatAmount(total),
          subtitle: 'Tuition + Allied Fees',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: const Color(0xFF3B82F6),
          bgColor: const Color(0xFFEFF6FF),
        ),
        _buildMetricCard(
          title: 'Paid Amount',
          amount: _formatAmount(paid),
          subtitle: 'Instantly Credited',
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
        ),
        _buildMetricCard(
          title: 'Pending Amount',
          amount: _formatAmount(pending),
          subtitle: 'Dues remaining',
          icon: Icons.pending_actions_rounded,
          iconColor: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFEF3C7),
        ),
        _buildMetricCard(
          title: 'Next Due Date',
          amount: dueDate,
          subtitle: dueSubtitle,
          icon: Icons.event_note_rounded,
          iconColor: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
        ),
      ];

      if (!isDesktop && !isTablet) {
        return Column(
          children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
        );
      }

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: cards.map((card) => SizedBox(width: width, child: card)).toList(),
      );
    });
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleSection(
    double total, double paid, double pending, double progress, String dueDate, String dueSubtitle,
    List<Map<String, dynamic>> breakdownItems, bool isDesktop, bool isTablet
  ) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: _buildPaymentProgress(paid, pending, progress, dueDate)),
          const SizedBox(width: 24),
          Expanded(flex: 6, child: _buildFeeBreakdown(total, breakdownItems)),
        ],
      );
    }

    return Column(
      children: [
        _buildPaymentProgress(paid, pending, progress, dueDate),
        const SizedBox(height: 24),
        _buildFeeBreakdown(total, breakdownItems),
      ],
    );
  }

  Widget _buildPaymentProgress(double paid, double pending, double progress, String dueDate) {
    final int percentVal = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF8FAFC),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$percentVal%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: -1.0,
                          ),
                        ),
                        const Text(
                          'Paid',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Text('Paid amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                    Text(
                      _formatAmount(paid),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.pending_actions_rounded, color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 8),
                        Text('Balance pending', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                    Text(
                      _formatAmount(pending),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeBreakdown(double total, List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fee Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Total: ${_formatAmount(total)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Column(
            children: items.map((item) {
              final String title = item['title'] as String;
              final String category = item['category'] as String;
              final double amt = item['amount'] as double;
              final bool isPaid = item['isPaid'] == true;
              final String dueDate = item['dueDate']?.toString() ?? '-';
              final double barFill = total > 0 ? (amt / total).clamp(0.0, 1.0) : 0.0;

              // Category accent colors for bar gradient
              Color barStart = const Color(0xFFE53E3E);

              if (category.toLowerCase().contains('tuition')) {
                barStart = const Color(0xFFE53E3E);
              } else if (category.toLowerCase().contains('academic')) {
                barStart = const Color(0xFF7C3AED);
              } else if (category.toLowerCase().contains('exam')) {
                barStart = const Color(0xFF0891B2);
              } else if (category.toLowerCase().contains('transport')) {
                barStart = const Color(0xFF059669);
              } else if (category.toLowerCase().contains('hostel')) {
                barStart = const Color(0xFFDB2777);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row: fee name + amount + badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPaid ? 'PAID' : 'PENDING',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: isPaid ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatAmount(amt),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? const Color(0xFF1E293B) : const Color(0xFFDC2626),
                              ),
                            ),
                            if (!isPaid)
                              Text(
                                'Due $dueDate',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Gradient progress bar
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxW = constraints.maxWidth;
                        final double barW = maxW * barFill;
                        return Container(
                          height: 14,
                          width: maxW,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            // Unpaid gets a blue outline matching the design
                            border: !isPaid
                                ? Border.all(color: const Color(0xFF3B82F6), width: 1.5)
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Stack(
                              children: [
                                // Filled gradient portion
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  width: barW,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: barStart,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
