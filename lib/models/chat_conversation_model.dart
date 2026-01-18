import 'chat_model.dart';

class ChatConversation {
  final String transactionId;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final double? amount;
  final String? status;
  final String? senderAadhar;
  final String? receiverAadhar;
  final String? senderName;
  final String? receiverName;
  final String? customerName;
  final DateTime? transactionCreatedAt;

  ChatConversation({
    required this.transactionId,
    required this.lastMessage,
    required this.unreadCount,
    this.amount,
    this.status,
    this.senderAadhar,
    this.receiverAadhar,
    this.senderName,
    this.receiverName,
    this.customerName,
    this.transactionCreatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'amount': amount,
      'status': status,
      'senderAadhar': senderAadhar,
      'receiverAadhar': receiverAadhar,
      'senderName': senderName,
      'receiverName': receiverName,
      'customerName': customerName,
      'transactionCreatedAt': transactionCreatedAt?.toIso8601String(),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    try {
      // Parse last message if available
      ChatMessage? lastMessage;
      if (json['lastMessage'] != null && json['lastMessage'] is String) {
        try {
          // Backend sends lastMessage as string, and separate fields for metadata
          final lastCreatedAt = json['lastCreatedAt'];
          if (lastCreatedAt != null) {
            lastMessage = ChatMessage.fromJson({
              'message': json['lastMessage'],
              'senderAadhar': json['lastSenderAadhar'] ?? '',
              'receiverAadhar': json['lastReceiverAadhar'] ?? '',
              'createdAt': lastCreatedAt is String 
                  ? lastCreatedAt 
                  : (lastCreatedAt is DateTime 
                      ? lastCreatedAt.toIso8601String() 
                      : DateTime.now().toIso8601String()),
              '_id': 'last-${json['transactionId'] ?? ''}',
              'status': 'delivered',
              'read': true,
            });
          }
        } catch (e) {
          // If parsing fails, set to null
          lastMessage = null;
        }
      }

      // Parse transaction data (nested or flat)
      final transaction = json['transaction'] ?? {};
      final amount = transaction['amount'] ?? json['amount'];
      final status = transaction['status'] ?? json['status'];
      final senderAadhar = transaction['senderAadhar'] ?? json['senderAadhar'];
      final receiverAadhar = transaction['receiverAadhar'] ?? json['receiverAadhar'];
      final senderName = transaction['senderName'] ?? json['senderName'];
      final receiverName = transaction['receiverName'] ?? json['receiverName'];
      final customerName = transaction['customerName'] ?? json['customerName'];
      
      DateTime? transactionCreatedAt;
      try {
        final createdAt = transaction['createdAt'] ?? json['transactionCreatedAt'];
        if (createdAt != null) {
          transactionCreatedAt = createdAt is String 
              ? DateTime.parse(createdAt) 
              : (createdAt is DateTime ? createdAt : null);
        }
      } catch (e) {
        transactionCreatedAt = null;
      }

      return ChatConversation(
        transactionId: json['transactionId'] ?? json['transaction_id'] ?? '',
        lastMessage: lastMessage,
        unreadCount: json['unreadCount'] ?? 0,
        amount: amount != null ? (amount is num ? amount.toDouble() : double.tryParse(amount.toString())) : null,
        status: status?.toString(),
        senderAadhar: senderAadhar?.toString(),
        receiverAadhar: receiverAadhar?.toString(),
        senderName: senderName?.toString(),
        receiverName: receiverName?.toString(),
        customerName: customerName?.toString(),
        transactionCreatedAt: transactionCreatedAt,
      );
    } catch (e) {
      // Return a minimal conversation if parsing fails
      return ChatConversation(
        transactionId: json['transactionId'] ?? json['transaction_id'] ?? '',
        lastMessage: null,
        unreadCount: json['unreadCount'] ?? 0,
      );
    }
  }
}


