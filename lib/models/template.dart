class Template {
  final String id;
  final String name;
  final String type; // 'expense' | 'income' | 'transfer'
  final double? amount;
  final String? accountId;
  final String? categoryId;
  final String? note;

  Template({
    required this.id,
    required this.name,
    required this.type,
    this.amount,
    this.accountId,
    this.categoryId,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'accountId': accountId,
      'categoryId': categoryId,
      'note': note,
    };
  }

  factory Template.fromMap(Map<String, dynamic> map) {
    return Template(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'expense',
      amount: map['amount'] != null 
          ? (map['amount'] is int ? (map['amount'] as int).toDouble() : map['amount'] as double)
          : null,
      accountId: map['accountId'],
      categoryId: map['categoryId'],
      note: map['note'],
    );
  }
}
