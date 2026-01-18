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

            if (chatProvider.error != null && chatProvider.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading conversations',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        chatProvider.error!,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        chatProvider.clearError();
                        chatProvider.loadConversations(useCache: false);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (chatProvider.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by opening a payment and messaging the owner.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => chatProvider.loadConversations(),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: chatProvider.conversations.length,
                separatorBuilder: (context, index) => const SizedBox.shrink(),
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
        ? TimeUtils.formatChatListTime(convo.lastMessage!.createdAt)
        : '';
    final subtitle = convo.lastMessage?.message ?? 'No messages yet';
    final counterpartAadhar = isOwner ? convo.receiverAadhar : convo.senderAadhar;
    final counterpartName = isOwner 
        ? (convo.customerName ?? convo.receiverName ?? '')
        : (convo.senderName ?? '');
    final maskedAadhar = _maskAadhar(counterpartAadhar ?? '-');
    final unread = convo.unreadCount;
    final isUnread = unread > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isUnread ? Colors.grey[50] : Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(counterpartName, counterpartAadhar),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            counterpartName.isNotEmpty ? counterpartName : maskedAadhar,
                            style: GoogleFonts.inter(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 16,
                              color: Colors.grey[900],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lastTime,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isUnread ? Colors.grey[900] : Colors.grey[600],
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: isUnread ? Colors.grey[900] : Colors.grey[600],
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366), // WhatsApp green
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
    
    // WhatsApp-like avatar colors
    final colors = [
      [const Color(0xFF25D366), const Color(0xFF128C7E)], // Green
      [const Color(0xFF34B7F1), const Color(0xFF0084FF)], // Blue
      [const Color(0xFFFF6B6B), const Color(0xFFE63946)], // Red
      [const Color(0xFFFFA726), const Color(0xFFFF6F00)], // Orange
      [const Color(0xFFAB47BC), const Color(0xFF7B1FA2)], // Purple
      [const Color(0xFF26A69A), const Color(0xFF00695C)], // Teal
    ];
    final colorIndex = (name?.hashCode ?? aadhar?.hashCode ?? 0).abs() % colors.length;
    final avatarColors = colors[colorIndex];
    
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: avatarColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: avatarColors[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: name != null && name.isNotEmpty ? 18 : 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} ${value.substring(8)}';
  }
}


