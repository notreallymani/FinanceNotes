import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/time_utils.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh conversations when screen becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadConversations(useCache: false);
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
        ? TimeUtils.formatISTShort(convo.lastMessage!.createdAt)
        : '';
    final subtitle = convo.lastMessage?.message ?? 'No messages yet';
    final counterpartAadhar = isOwner ? convo.receiverAadhar : convo.senderAadhar;
    final counterpartName = isOwner 
        ? (convo.customerName ?? convo.receiverName ?? '')
        : (convo.senderName ?? '');
    final displayName = counterpartName.isNotEmpty 
        ? counterpartName 
        : _maskAadhar(counterpartAadhar ?? '-');
    final maskedAadhar = _maskAadhar(counterpartAadhar ?? '-');
    final amount = convo.amount != null ? '₹${convo.amount!.toStringAsFixed(0)}' : '';
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            // Build a minimal TransactionModel to pass to ChatScreen
            final tx = TransactionModel(
              id: convo.transactionId,
              senderAadhar: convo.senderAadhar ?? '',
              receiverAadhar: convo.receiverAadhar ?? '',
              amount: convo.amount ?? 0,
              status: convo.status ?? 'pending',
              createdAt: convo.transactionCreatedAt ?? DateTime.now(),
              interest: 0,
              customerName: convo.customerName,
            );
            // Navigate to chat screen and refresh conversations when returning
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(transaction: tx),
              ),
            );
            // Refresh conversations list when returning from chat screen
            if (mounted) {
              Provider.of<ChatProvider>(context, listen: false).loadConversations(useCache: false);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _buildAvatar(counterpartName, counterpartAadhar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.grey[900],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (counterpartName.isNotEmpty && maskedAadhar.isNotEmpty)
                                  Text(
                                    maskedAadhar,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
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
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (amount.isNotEmpty || status.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            if (amount.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  amount,
                                  style: GoogleFonts.inter(
                                    color: Colors.blue[800],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (status.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (unread > 0)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? name, String? aadhar) {
    String text;
    if (name != null && name.isNotEmpty) {
      // Use first letter(s) of name
      final parts = name.trim().split(' ');
      if (parts.length > 1) {
        text = '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      } else {
        text = name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
      }
    } else {
      // Fallback to last 4 digits of Aadhaar
      text = (aadhar != null && aadhar.length >= 4)
          ? aadhar.substring(aadhar.length - 4)
          : '----';
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.blue[400]!,
            Colors.blue[600]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: name != null && name.isNotEmpty ? 15 : 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} ${value.substring(8)}';
  }
}


