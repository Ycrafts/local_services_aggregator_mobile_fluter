class User {
  final int? id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? profileImage;
  final String userType; // 'customer' or 'provider'
  
  User({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.profileImage,
    required this.userType,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    print('Parsing user JSON: $json'); // Debug log
    
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      profileImage: json['profile_image'] as String?,
      userType: json['user_type'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_image': profileImage,
      'user_type': userType,
    };
  }
} 