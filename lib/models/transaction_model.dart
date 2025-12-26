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
  final List<TransactionDocument> documents;

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
    this.documents = const [],
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final documentsJson = json['documents'] as List<dynamic>? ?? [];
    final documents = documentsJson
        .map((doc) => TransactionDocument.fromJson(doc as Map<String, dynamic>))
        .toList();

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
      documents: documents,
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
      'documents': documents.map((doc) => doc.toJson()).toList(),
    };
  }
}

/// Transaction Document Model
class TransactionDocument {
  final String filename;
  final String url;
  final int? size;
  final String? mimetype;

  TransactionDocument({
    required this.filename,
    required this.url,
    this.size,
    this.mimetype,
  });

  factory TransactionDocument.fromJson(Map<String, dynamic> json) {
    return TransactionDocument(
      filename: json['filename'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] as int?,
      mimetype: json['mimetype'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'size': size,
      'mimetype': mimetype,
    };
  }

  String get fileExtension {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage {
    final ext = fileExtension;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  bool get isPdf {
    return fileExtension == 'pdf';
  }
}

