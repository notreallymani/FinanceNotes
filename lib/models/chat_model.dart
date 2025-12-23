class ChatMessage {
  final String id;
  final String transactionId;
  final String senderAadhar;
  final String receiverAadhar;
  final String message;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.transactionId,
    required this.senderAadhar,
    required this.receiverAadhar,
    required this.message,
    required this.read,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      transactionId: json['transactionId'] ?? json['transaction_id'] ?? '',
      senderAadhar: json['senderAadhar'] ?? json['sender_aadhar'] ?? '',
      receiverAadhar: json['receiverAadhar'] ?? json['receiver_aadhar'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'senderAadhar': senderAadhar,
      'receiverAadhar': receiverAadhar,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }
}

