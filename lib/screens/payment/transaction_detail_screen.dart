/// Transaction Detail Screen
/// 
/// Single Responsibility: Displays transaction details
/// Dependency Inversion: Uses services for document operations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import '../../models/transaction_model.dart';
import '../../services/document_service.dart';
import '../../utils/interest_calculator.dart';
import '../../utils/time_utils.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Transaction Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAmountCard(context),
              const SizedBox(height: 16),
              _buildDetailsCard(context),
              if (transaction.documents.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDocumentsSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    final calculation = transaction.interest > 0
        ? InterestCalculator.calculateInterest(
            principal: transaction.amount,
            interest: transaction.interest,
            createdAt: transaction.createdAt,
            closedAt: transaction.closedAt,
          )
        : null;
    final statusColor = _getStatusColor(transaction.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  transaction.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${transaction.amount.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
              ),
            ),
          ),
          if (calculation != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  InterestCalculator.formatCurrency(calculation.totalAmount),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final receiverMobile = transaction.mobile;
    final senderMobile = transaction.senderMobile;
    final calculation = transaction.interest > 0
        ? InterestCalculator.calculateInterest(
            principal: transaction.amount,
            interest: transaction.interest,
            createdAt: transaction.createdAt,
            closedAt: transaction.closedAt,
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSimpleRow('Sender Aadhaar', _maskAadhar(transaction.senderAadhar)),
          const Divider(height: 24),
          _buildSimpleRow('Receiver Aadhaar', _maskAadhar(transaction.receiverAadhar)),
          if (transaction.customerName != null && transaction.customerName!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildSimpleRow('Customer Name', transaction.customerName!),
          ],
          if (receiverMobile != null && receiverMobile.isNotEmpty) ...[
            const Divider(height: 24),
            _buildPhoneRow(context, 'Receiver Mobile', receiverMobile),
          ],
          if (senderMobile != null && senderMobile.isNotEmpty) ...[
            const Divider(height: 24),
            _buildPhoneRow(context, 'Sender Mobile', senderMobile),
          ],
          if (calculation != null) ...[
            const Divider(height: 24),
            _buildSimpleRow('Principal', InterestCalculator.formatCurrency(calculation.principal)),
            const SizedBox(height: 12),
            _buildSimpleRow('Interest Rate', calculation.isPercentage 
                ? InterestCalculator.formatPercentage(calculation.interestRate)
                : InterestCalculator.formatCurrency(calculation.interestRate)),
            const SizedBox(height: 12),
            _buildSimpleRow('Interest Amount', InterestCalculator.formatCurrency(calculation.totalInterest)),
            const SizedBox(height: 12),
            _buildSimpleRow('Period', calculation.formattedPeriod),
          ],
          const Divider(height: 24),
          _buildSimpleRow('Created', TimeUtils.formatIST(transaction.createdAt)),
          if (transaction.closedAt != null) ...[
            const Divider(height: 24),
            _buildSimpleRow('Closed', TimeUtils.formatIST(transaction.closedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneRow(BuildContext context, String label, String phone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                phone,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _makePhoneCall(phone),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.phone,
                      size: 18,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents (${transaction.documents.length})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: transaction.documents.map((document) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDocumentCard(context, document),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, TransactionDocument document) {
    final documentService = DocumentService();
    final isImage = document.isImage;
    final isPdf = document.isPdf;
    final iconColor = isImage ? Colors.blue : (isPdf ? Colors.red : Colors.orange);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _downloadDocument(context, document),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                isImage 
                    ? Icons.image 
                    : isPdf 
                        ? Icons.picture_as_pdf 
                        : Icons.insert_drive_file,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      document.filename,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[900],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (document.size != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        documentService.formatFileSize(document.size),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} **** ${value.substring(8)}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _downloadDocument(BuildContext context, TransactionDocument document) async {
    if (!context.mounted) return;

    // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Downloading ${document.filename}...',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 30),
          backgroundColor: Colors.blue[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

    try {
      final documentService = DocumentService();
      final file = await documentService.downloadDocument(
        url: document.url,
        filename: document.filename,
      );

      if (!context.mounted) return;

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (file != null) {
        // Show success snackbar with action to open file
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Downloaded: ${document.filename}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    'Saved to Downloads folder',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await OpenFile.open(file.path);
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Could not open file: $e',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        throw Exception('File download returned null');
      }
    } catch (e) {
      if (!context.mounted) return;
      
      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      String errorMessage = 'Download failed';
      final errorString = e.toString().replaceAll('Exception: ', '');
      
      if (errorString.contains('permission')) {
        errorMessage = 'Permission denied. Please grant storage permission in app settings.';
      } else if (errorString.contains('timeout')) {
        errorMessage = 'Download timeout. Please check your internet connection.';
      } else if (errorString.contains('HTTP') || errorString.contains('status')) {
        errorMessage = 'File not available. The document may have been removed.';
      } else if (errorString.contains('empty')) {
        errorMessage = 'Downloaded file is empty. Please try again.';
      } else {
        errorMessage = 'Download failed: ${errorString.length > 100 ? errorString.substring(0, 100) + "..." : errorString}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

