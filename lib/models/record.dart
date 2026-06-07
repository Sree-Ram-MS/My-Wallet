class Record {
  final String id;
  final String type; // 'expense' | 'income' | 'transfer'
  final double amount;
  final String currency;
  final String accountId;
  final String? fromAccountId; // Only if transfer
  final String? toAccountId;   // Only if transfer
  final String? categoryId;
  final String? note;
  final DateTime dateTime;
  final String? templateId;
  final DateTime createdAt;

  Record({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.accountId,
    this.fromAccountId,
    this.toAccountId,
    this.categoryId,
    this.note,
    required this.dateTime,
    this.templateId,
    required this.createdAt,
  });

  Record copyWith({
    String? id,
    String? type,
    double? amount,
    String? currency,
    String? accountId,
    String? fromAccountId,
    String? toAccountId,
    String? categoryId,
    String? note,
    DateTime? dateTime,
    String? templateId,
    DateTime? createdAt,
  }) {
    return Record(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      dateTime: dateTime ?? this.dateTime,
      templateId: templateId ?? this.templateId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'currency': currency,
      'accountId': accountId,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'note': note,
      'dateTime': dateTime.toIso8601String(),
      'templateId': templateId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Record.fromMap(Map<String, dynamic> map) {
    return Record(
      id: map['id'] ?? '',
      type: map['type'] ?? 'expense',
      amount: (map['amount'] ?? 0.0) is int 
          ? (map['amount'] as int).toDouble() 
          : (map['amount'] ?? 0.0),
      currency: map['currency'] ?? 'INR',
      accountId: map['accountId'] ?? '',
      fromAccountId: map['fromAccountId'],
      toAccountId: map['toAccountId'],
      categoryId: map['categoryId'],
      note: map['note'],
      dateTime: map['dateTime'] != null 
          ? DateTime.parse(map['dateTime']) 
          : DateTime.now(),
      templateId: map['templateId'],
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}
