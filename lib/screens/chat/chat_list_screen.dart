import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_conversation_model.dart';
import '../../models/transaction_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserAadhar = authProvider.user?.aadhar ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chats',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (chatProvider.conversations.isEmpty) {
              return Center(
                child: Text(
                  'No conversations yet.\nStart by opening a payment and messaging the owner.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => chatProvider.loadConversations(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: chatProvider.conversations.length,
                itemBuilder: (context, index) {
                  final convo = chatProvider.conversations[index];
                  final isOwner = convo.senderAadhar == currentUserAadhar;
                  return _buildConversationTile(convo, isOwner, currentUserAadhar);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation convo, bool isOwner, String currentUserAadhar) {
    final lastTime = convo.lastMessage?.createdAt != null
        ? DateFormat('dd MMM, hh:mm a').format(convo.lastMessage!.createdAt)
        : '';
    final subtitle = convo.lastMessage?.message ?? 'No messages yet';
    final counterpartAadhar = isOwner ? convo.receiverAadhar : convo.senderAadhar;
    final amount = convo.amount != null ? '₹${convo.amount!.toStringAsFixed(2)}' : '';
    final status = convo.status?.toUpperCase() ?? '';
    final isLastFromMe = convo.lastMessage?.senderAadhar == currentUserAadhar;
    final unread = convo.unreadCount;

    final Color statusColor;
    switch (status.toLowerCase()) {
      case 'closed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Build a minimal TransactionModel to pass to ChatScreen
          final tx = TransactionModel(
            id: convo.transactionId,
            senderAadhar: convo.senderAadhar ?? '',
            receiverAadhar: convo.receiverAadhar ?? '',
            amount: convo.amount ?? 0,
            status: convo.status ?? 'pending',
            createdAt: convo.transactionCreatedAt ?? DateTime.now(),
            interest: 0,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(transaction: tx),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _buildAvatar(counterpartAadhar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Aadhaar: ${_maskAadhar(counterpartAadhar ?? '-') }',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastTime,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          isLastFromMe ? Icons.north_east : Icons.south_west,
                          size: 16,
                          color: isLastFromMe ? Colors.blue : Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.grey[800],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (amount.isNotEmpty)
                          _chip(
                            icon: Icons.payments_outlined,
                            label: amount,
                            bg: Colors.blue.withOpacity(0.08),
                            fg: Colors.blue[800]!,
                          ),
                        const SizedBox(width: 6),
                        if (status.isNotEmpty)
                          _chip(
                            icon: Icons.info_outline,
                            label: status,
                            bg: statusColor.withOpacity(0.12),
                            fg: statusColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unread',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? aadhar) {
    final text = (aadhar != null && aadhar.length >= 4)
        ? aadhar.substring(aadhar.length - 4)
        : 'CHAT';
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color bg, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
}


