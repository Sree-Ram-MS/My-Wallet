class Credit {
  final String id;
  final String lenderName;
  final String? notes;
  final String accountId;
  final double amount;
  final DateTime date;
  final DateTime dueDate;
  final bool isPaid;
  final String? paidFromAccountId;
  final String recordId;
  final String? paidRecordId;

  Credit({
    required this.id,
    required this.lenderName,
    this.notes,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.dueDate,
    required this.isPaid,
    this.paidFromAccountId,
    required this.recordId,
    this.paidRecordId,
  });

  Credit copyWith({
    String? id,
    String? lenderName,
    String? notes,
    String? accountId,
    double? amount,
    DateTime? date,
    DateTime? dueDate,
    bool? isPaid,
    String? paidFromAccountId,
    String? recordId,
    String? paidRecordId,
  }) {
    return Credit(
      id: id ?? this.id,
      lenderName: lenderName ?? this.lenderName,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidFromAccountId: paidFromAccountId ?? this.paidFromAccountId,
      recordId: recordId ?? this.recordId,
      paidRecordId: paidRecordId ?? this.paidRecordId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lenderName': lenderName,
      'notes': notes,
      'accountId': accountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'paidFromAccountId': paidFromAccountId,
      'recordId': recordId,
      'paidRecordId': paidRecordId,
    };
  }

  factory Credit.fromMap(Map<String, dynamic> map) {
    return Credit(
      id: map['id'] ?? '',
      lenderName: map['lenderName'] ?? '',
      notes: map['notes'],
      accountId: map['accountId'] ?? '',
      amount: (map['amount'] ?? 0.0) is int 
          ? (map['amount'] as int).toDouble() 
          : (map['amount'] ?? 0.0),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      isPaid: (map['isPaid'] ?? 0) == 1,
      paidFromAccountId: map['paidFromAccountId'],
      recordId: map['recordId'] ?? '',
      paidRecordId: map['paidRecordId'],
    );
  }
}
