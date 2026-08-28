import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/core_widgets.dart';
import '../../services/download_service.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  String? _downloadingReceiptId;

  @override
  Widget build(BuildContext context) {
    final fees = MockData.mockFees;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Fee Summary'),
            _buildFeeSummary(context, fees),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Payment History'),
            _buildPaymentHistory(fees),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSummary(BuildContext context, fees) {
    return CustomCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppTheme.sidebarGradient,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pending Amount', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(
                      '₹${fees.pending.toInt()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'Due: ${fees.dueDate.day}/${fees.dueDate.month}/${fees.dueDate.year}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFeeDetail('Total College Fees', '₹${fees.totalFees.toInt()}'),
                Container(height: 32, width: 1, color: Colors.grey.shade100),
                _buildFeeDetail('Amount Paid', '₹${fees.paid.toInt()}', color: const Color(0xFF10B981)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: PrimaryButton(
              text: 'Proceed to Payment',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Redirecting to payment gateway...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeDetail(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(fees) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fees.history.length,
      itemBuilder: (context, index) {
        final history = fees.history[index];
        final isDownloading = _downloadingReceiptId == history.receiptId;
        final hasUrl = history.receiptUrl != null && history.receiptUrl!.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CustomCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(history.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        '${history.date.day}/${history.date.month}/${history.date.year} • Ref: ${history.receiptId}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${history.amount.toInt()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: history.status),
                  ],
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: isDownloading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download_rounded, color: Color(0xFF10B981)),
                    onPressed: hasUrl && !isDownloading
                        ? () => _downloadReceipt(history)
                        : null,
                    tooltip: hasUrl ? 'Download receipt' : 'Receipt not available',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadReceipt(dynamic history) async {
    if (history.receiptUrl == null || history.receiptUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt is not available.')),
      );
      return;
    }

    setState(() => _downloadingReceiptId = history.receiptId);

    try {
      final fileName = 'Fee_Receipt_${history.receiptId}.pdf';
      final sanitized = DownloadService.sanitizeFilename(fileName);
      final success = await DownloadService.downloadFromUrl(history.receiptUrl!, sanitized);

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
        setState(() => _downloadingReceiptId = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download receipt. Please try again.')),
        );
        setState(() => _downloadingReceiptId = null);
      }
    }
  }
}
