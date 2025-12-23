class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String aadhar;
  final String picture;
  final bool? aadharVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.aadhar,
    required this.picture,
    this.aadharVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? json['mobile'] ?? '',
      aadhar: json['aadhar'] ?? json['aadhaar'] ?? '',
      picture: json['picture'] ?? '',
      aadharVerified: json['aadharVerified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'aadhar': aadhar,
      'picture': picture,
      'aadharVerified': aadharVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? aadhar,
    String? picture,
    bool? aadharVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      aadhar: aadhar ?? this.aadhar,
      picture: picture ?? this.picture,
      aadharVerified: aadharVerified ?? this.aadharVerified,
    );
  }
}

