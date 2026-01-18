import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/time_utils.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/chat_model.dart' show ChatMessage, MessageStatus;

class ChatScreen extends StatefulWidget {
  final TransactionModel transaction;

  const ChatScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
      // Auto-scroll to bottom when messages load
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.loadMessages(widget.transaction.id);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final success = await chatProvider.sendMessage(
      widget.transaction.id,
      _messageController.text.trim(),
    );

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatProvider.error ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isCurrentUser(String aadhar) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.user?.aadhar == aadhar;
  }

  String _maskAadhar(String value) {
    if (value.length != 12) return value;
    return '${value.substring(0, 4)} ${value.substring(8)}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserAadhar = authProvider.user?.aadhar ?? '';
    final isOwner = widget.transaction.senderAadhar == currentUserAadhar;
    final otherPartyAadhar = isOwner 
        ? widget.transaction.receiverAadhar 
        : widget.transaction.senderAadhar;
    final otherPartyName = isOwner 
        ? (widget.transaction.customerName ?? '')
        : ''; // For owner chat, we'll need to get owner name from auth or another source
    final maskedAadhar = _maskAadhar(otherPartyAadhar);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    otherPartyName.isNotEmpty ? otherPartyName : maskedAadhar,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (maskedAadhar.isNotEmpty && otherPartyName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    maskedAadhar,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            Text(
              '₹${widget.transaction.amount.toStringAsFixed(0)} • ${widget.transaction.status.toUpperCase()}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isMe = _isCurrentUser(message.senderAadhar);
                    
                    // Check if we need to show a date separator
                    bool showDateSeparator = false;
                    if (index == 0) {
                      showDateSeparator = true;
                    } else {
                      final previousMessage = chatProvider.messages[index - 1];
                      showDateSeparator = !TimeUtils.isSameDay(
                        message.createdAt,
                        previousMessage.createdAt,
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateSeparator) _buildDateSeparator(message.createdAt),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Message input (WhatsApp-style)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[900],
                          ),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer<ChatProvider>(
                      builder: (context, chatProvider, _) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF25D366), // WhatsApp green
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: chatProvider.isLoading ? null : _sendMessage,
                              child: Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                child: chatProvider.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          TimeUtils.getDateSeparator(date),
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 4,
          left: isMe ? 60 : 8,
          right: isMe ? 8 : 60,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFFDCF8C6) // WhatsApp sent message color
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(8),
                  topRight: const Radius.circular(8),
                  bottomLeft: Radius.circular(isMe ? 8 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 8),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      color: Colors.grey[900],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TimeUtils.formatISTTimeOnly(message.createdAt).replaceAll(' IST', ''),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatusIcon(message.status),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.read:
        icon = Icons.done_all;
        color = const Color(0xFF4FC3F7); // WhatsApp blue read tick
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey[600]!;
        break;
      case MessageStatus.sent:
        icon = Icons.done;
        color = Colors.grey[600]!;
        break;
    }

    return Icon(
      icon,
      size: 16,
      color: color,
    );
  }
}

