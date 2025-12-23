import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transaction = ModalRoute.of(context)?.settings.arguments as TransactionModel?;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Request Created',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (transaction != null) ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Customer Aadhaar',
                          transaction.receiverAadhar,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Amount',
                          '₹${transaction.amount.toStringAsFixed(2)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Interest',
                          '${transaction.interest.toStringAsFixed(2)}%',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'Status',
                          transaction.status.toUpperCase(),
                        ),
                        const Divider(),
                        _buildInfoRow(
                          transaction.status.toLowerCase() == 'closed' && transaction.closedAt != null
                              ? 'Closed Date'
                              : 'Created Date',
                          transaction.status.toLowerCase() == 'closed' && transaction.closedAt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(transaction.closedAt!)
                              : DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
                        ),
                        if (transaction.status.toLowerCase() == 'closed' && transaction.closedAt != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            'Created Date',
                            DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/dashboard',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back to Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

