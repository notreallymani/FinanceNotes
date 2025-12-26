import 'chat_model.dart';

class ChatConversation {
  final String transactionId;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final double? amount;
  final String? status;
  final String? senderAadhar;
  final String? receiverAadhar;
  final DateTime? transactionCreatedAt;

  ChatConversation({
    required this.transactionId,
    required this.lastMessage,
    required this.unreadCount,
    this.amount,
    this.status,
    this.senderAadhar,
    this.receiverAadhar,
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
      'transactionCreatedAt': transactionCreatedAt?.toIso8601String(),
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      transactionId: json['transactionId'] ?? json['transaction_id'] ?? '',
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson({
              'message': json['lastMessage'],
              'senderAadhar': json['lastSenderAadhar'],
              'receiverAadhar': json['lastReceiverAadhar'],
              'createdAt': json['lastCreatedAt'],
              '_id': 'last-${json['transactionId'] ?? ''}',
              'read': true,
            })
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      amount: (json['transaction']?['amount'] ?? json['amount'])?.toDouble(),
      status: json['transaction']?['status'] ?? json['status'],
      senderAadhar: json['transaction']?['senderAadhar'] ?? json['senderAadhar'],
      receiverAadhar:
          json['transaction']?['receiverAadhar'] ?? json['receiverAadhar'],
      transactionCreatedAt: json['transaction']?['createdAt'] != null
          ? DateTime.parse(json['transaction']['createdAt'])
          : null,
    );
  }
}


