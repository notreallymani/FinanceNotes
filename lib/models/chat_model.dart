enum MessageStatus { sent, delivered, read }

class ChatMessage {
  final String id;
  final String transactionId;
  final String senderAadhar;
  final String receiverAadhar;
  final String message;
  final MessageStatus status;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;

  ChatMessage({
    required this.id,
    required this.transactionId,
    required this.senderAadhar,
    required this.receiverAadhar,
    required this.message,
    required this.status,
    required this.read,
    required this.createdAt,
    this.readAt,
    this.deliveredAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    MessageStatus parseStatus(String? statusStr) {
      switch (statusStr?.toLowerCase()) {
        case 'read':
          return MessageStatus.read;
        case 'delivered':
          return MessageStatus.delivered;
        case 'sent':
        default:
          return MessageStatus.sent;
      }
    }

    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      transactionId: json['transactionId'] ?? json['transaction_id'] ?? '',
      senderAadhar: json['senderAadhar'] ?? json['sender_aadhar'] ?? '',
      receiverAadhar: json['receiverAadhar'] ?? json['receiver_aadhar'] ?? '',
      message: json['message'] ?? '',
      status: parseStatus(json['status']),
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    String statusToString(MessageStatus status) {
      switch (status) {
        case MessageStatus.read:
          return 'read';
        case MessageStatus.delivered:
          return 'delivered';
        case MessageStatus.sent:
        default:
          return 'sent';
      }
    }

    return {
      'id': id,
      'transactionId': transactionId,
      'senderAadhar': senderAadhar,
      'receiverAadhar': receiverAadhar,
      'message': message,
      'status': statusToString(status),
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }
}

