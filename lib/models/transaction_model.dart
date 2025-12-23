class TransactionModel {
  final String id;
  final String senderAadhar;
  final String receiverAadhar;
  final double amount;
  final String status; // pending, closed, cancelled
  final DateTime createdAt;
  final DateTime? closedAt;
  final String? mobile;
  final String? senderMobile;
  final double interest;

  TransactionModel({
    required this.id,
    required this.senderAadhar,
    required this.receiverAadhar,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.interest,
    this.closedAt,
    this.mobile,
    this.senderMobile,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? json['id'] ?? '',
      senderAadhar: json['senderAadhar'] ?? json['sender_aadhar'] ?? '',
      receiverAadhar: json['receiverAadhar'] ?? json['receiver_aadhar'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      interest: (json['interest'] ?? 0).toDouble(),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'])
          : null,
      mobile: json['mobile'] ?? json['receiverMobile'],
      senderMobile: json['senderMobile'] ?? json['sender_mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderAadhar': senderAadhar,
      'receiverAadhar': receiverAadhar,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'mobile': mobile,
      'senderMobile': senderMobile,
      'interest': interest,
    };
  }
}

