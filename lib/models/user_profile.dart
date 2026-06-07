class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? profilePicUrl;
  final String defaultCurrency;
  final String authType; // 'google' | 'guest'

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicUrl,
    this.defaultCurrency = 'INR',
    required this.authType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicUrl': profilePicUrl,
      'defaultCurrency': defaultCurrency,
      'authType': authType,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePicUrl: map['profilePicUrl'],
      defaultCurrency: map['defaultCurrency'] ?? 'INR',
      authType: map['authType'] ?? 'guest',
    );
  }
}
