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
    
    // Debug log for each field
    print('name: ${json['name']}');
    print('email: ${json['email']}');
    print('phone_number: ${json['phone_number']}');
    print('address: ${json['address']}');
    print('profile_image: ${json['profile_image']}');
    print('user_type: ${json['user_type']}');
    
    // Handle null values with defaults
    return User(
      id: json['id'] as int?,
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone_number']?.toString(),
      address: json['address']?.toString(),
      profileImage: json['profile_image']?.toString(),
      userType: json['user_type']?.toString() ?? 'customer',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'phone_number': phone,
      'address': address,
      'profile_image': profileImage,
      'user_type': userType,
    };
  }
} 