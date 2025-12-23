import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../chat/chat_screen.dart';

class SearchResultsScreen extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String aadhar;

  const SearchResultsScreen({
    Key? key,
    required this.transactions,
    required this.aadhar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Results',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No transactions found for this Aadhaar',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Results for: $aadhar',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final transaction = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.15),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${transaction.amount.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey[900],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Customer Aadhaar: ${_maskAadhar(transaction.receiverAadhar)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mobile: ${transaction.mobile ?? '-'}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        transaction.status.toLowerCase() == 'closed' && transaction.closedAt != null
                                            ? 'Closed: ${DateFormat('dd MMM yyyy, hh:mm a').format(transaction.closedAt!)}'
                                            : 'Created: ${DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: transaction.status.toLowerCase() == 'closed' 
                                              ? Colors.green[700] 
                                              : Colors.grey[600],
                                          fontWeight: transaction.status.toLowerCase() == 'closed' 
                                              ? FontWeight.w600 
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(transaction.status)
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        transaction.status.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              _getStatusColor(transaction.status),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                        final currentUserAadhar = authProvider.user?.aadhar ?? '';
                                        final isOwner = transaction.senderAadhar == currentUserAadhar;
                                        
                                        return IconButton(
                                          icon: Icon(
                                            isOwner ? Icons.person : Icons.chat_bubble_outline,
                                            size: 20,
                                          ),
                                          color: isOwner 
                                              ? Colors.grey[600] 
                                              : Theme.of(context).primaryColor,
                                          tooltip: isOwner ? 'You are the owner' : 'Chat with owner',
                                          onPressed: () => _openChat(context, transaction, isOwner),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _openChat(BuildContext context, TransactionModel t, bool isOwner) {
    // If user is the owner, show message
    if (isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are the owner of this payment. You cannot chat with yourself.'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Navigate to in-app chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(transaction: t),
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
}
