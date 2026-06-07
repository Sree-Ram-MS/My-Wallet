class Account {
  final String id;
  final String name;
  final String? accountNumber;
  final String currency;
  final String color; // Hex string e.g., "0xFF2196F3"
  final double balance;
  final bool isArchived;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    this.accountNumber,
    required this.currency,
    required this.color,
    required this.balance,
    required this.isArchived,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? currency,
    String? color,
    double? balance,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      currency: currency ?? this.currency,
      color: color ?? this.color,
      balance: balance ?? this.balance,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'currency': currency,
      'color': color,
      'balance': balance,
      'isArchived': isArchived ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      accountNumber: map['accountNumber'],
      currency: map['currency'] ?? 'INR',
      color: map['color'] ?? '0xFF2196F3',
      balance: (map['balance'] ?? 0.0) is int 
          ? (map['balance'] as int).toDouble() 
          : (map['balance'] ?? 0.0),
      isArchived: (map['isArchived'] ?? 0) == 1,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}
