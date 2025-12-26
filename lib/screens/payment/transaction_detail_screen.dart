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
import '../../utils/navigation_helper.dart';

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
    try {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('Downloading ${document.filename}...'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final documentService = DocumentService();
      final file = await documentService.downloadDocument(
        url: document.url,
        filename: document.filename,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to: ${file?.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

