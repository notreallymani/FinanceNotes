/// Transaction Detail Screen
/// 
/// Single Responsibility: Displays transaction details
/// Dependency Inversion: Uses services for document operations

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/transaction_model.dart';
import '../../services/document_service.dart';
import '../../utils/interest_calculator.dart';

class TransactionDetailScreen extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildAmountCard(context),
              const SizedBox(height: 16),
              if (transaction.interest > 0) ...[
                _buildInterestCalculationSection(context),
                const SizedBox(height: 16),
              ],
              _buildInfoSection(context),
              const SizedBox(height: 16),
              _buildMobileSection(context),
              const SizedBox(height: 16),
              if (transaction.documents.isNotEmpty) ...[
                _buildDocumentsSection(context),
                const SizedBox(height: 16),
              ],
              _buildStatusCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction ID',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          transaction.id,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[900],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Amount',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${transaction.amount.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.blue[900],
            ),
          ),
          if (transaction.interest > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Interest: ₹${transaction.interest.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterestCalculationSection(BuildContext context) {
    final calculation = InterestCalculator.calculateInterest(
      principal: transaction.amount,
      interest: transaction.interest,
      createdAt: transaction.createdAt,
      closedAt: transaction.closedAt,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[50]!,
            Colors.purple[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interest Calculation',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'From ${calculation.formattedStartDate} to ${calculation.formattedEndDate}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.purple[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Calculation Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Principal Amount
                _buildCalculationRow(
                  label: 'Principal Amount',
                  value: InterestCalculator.formatCurrency(calculation.principal),
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.blue,
                ),
                const Divider(height: 24),
                
                // Interest Rate/Amount
                _buildCalculationRow(
                  label: calculation.isPercentage 
                      ? 'Interest Rate (per month)'
                      : 'Interest Amount (per month)',
                  value: calculation.isPercentage
                      ? InterestCalculator.formatPercentage(calculation.interestRate)
                      : InterestCalculator.formatCurrency(calculation.interestRate),
                  icon: Icons.percent,
                  iconColor: Colors.orange,
                ),
                const Divider(height: 24),
                
                // Period
                _buildCalculationRow(
                  label: 'Calculation Period',
                  value: calculation.formattedPeriod,
                  icon: Icons.calendar_today,
                  iconColor: Colors.green,
                ),
                const Divider(height: 24),
                
                // Daily Interest
                _buildCalculationRow(
                  label: 'Daily Interest',
                  value: InterestCalculator.formatCurrency(calculation.dailyInterest),
                  icon: Icons.today,
                  iconColor: Colors.teal,
                ),
                const Divider(height: 24),
                
                // Total Interest Accrued
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Total Interest Accrued',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                      ),
                      Text(
                        InterestCalculator.formatCurrency(calculation.totalInterest),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Total Amount
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple[600]!,
                        Colors.purple[700]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Principal + Interest',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        InterestCalculator.formatCurrency(calculation.totalAmount),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context) {
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
            'Transaction Information',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Sender Aadhaar', _maskAadhar(transaction.senderAadhar)),
          const Divider(height: 24),
          _buildInfoRow('Receiver Aadhaar', _maskAadhar(transaction.receiverAadhar)),
          const Divider(height: 24),
          _buildInfoRow(
            'Created',
            DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
          ),
          if (transaction.closedAt != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              'Closed',
              DateFormat('dd MMM yyyy, hh:mm a').format(transaction.closedAt!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSection(BuildContext context) {
    final receiverMobile = transaction.mobile;
    final senderMobile = transaction.senderMobile;

    if (receiverMobile == null && senderMobile == null) {
      return const SizedBox.shrink();
    }

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
            'Contact Information',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          if (receiverMobile != null && receiverMobile.isNotEmpty)
            _buildMobileRow('Receiver Mobile', receiverMobile),
          if (senderMobile != null && senderMobile.isNotEmpty) ...[
            if (receiverMobile != null && receiverMobile.isNotEmpty)
              const Divider(height: 24),
            _buildMobileRow('Sender Mobile', senderMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileRow(String label, String mobile) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mobile,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.phone, color: Colors.blue[700]),
          onPressed: () => _makePhoneCall(mobile),
          tooltip: 'Call $mobile',
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
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.grey[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Proof Documents',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...transaction.documents.asMap().entries.map((entry) {
            final index = entry.key;
            final document = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: index < transaction.documents.length - 1 ? 12 : 0),
              child: _buildDocumentCard(context, document),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, TransactionDocument document) {
    final documentService = DocumentService();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: document.isImage ? Colors.blue[100] : Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              document.isImage ? Icons.image : document.isPdf ? Icons.picture_as_pdf : Icons.insert_drive_file,
              color: document.isImage ? Colors.blue[700] : Colors.orange[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.filename,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (document.size != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    documentService.formatFileSize(document.size),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.download, color: Colors.blue[700]),
            onPressed: () => _downloadDocument(context, document),
            tooltip: 'Download ${document.filename}',
          ),
          IconButton(
            icon: Icon(Icons.open_in_new, color: Colors.blue[700]),
            onPressed: () => _viewDocument(context, document),
            tooltip: 'View ${document.filename}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getStatusColor(transaction.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(transaction.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(transaction.status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatusIcon(transaction.status),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(transaction.status),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Future<void> _viewDocument(BuildContext context, TransactionDocument document) async {
    final uri = Uri.parse(document.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open ${document.filename}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Downloading ${document.filename}...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 30), // Longer duration for download
        backgroundColor: Colors.blue,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Downloaded: ${document.filename}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Saved to Downloads folder',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
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
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}

