class Debt {
  final String id;
  final String borrowerName;
  final String? notes;
  final String accountId;
  final double amount;
  final DateTime date;
  final DateTime dueDate;
  final bool isPaid;
  final String? paidToAccountId;
  final String recordId;       // Auto-created transaction record ID
  final String? paidRecordId;  // Auto-created on mark as paid

  Debt({
    required this.id,
    required this.borrowerName,
    this.notes,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.dueDate,
    required this.isPaid,
    this.paidToAccountId,
    required this.recordId,
    this.paidRecordId,
  });

  Debt copyWith({
    String? id,
    String? borrowerName,
    String? notes,
    String? accountId,
    double? amount,
    DateTime? date,
    DateTime? dueDate,
    bool? isPaid,
    String? paidToAccountId,
    String? recordId,
    String? paidRecordId,
  }) {
    return Debt(
      id: id ?? this.id,
      borrowerName: borrowerName ?? this.borrowerName,
      notes: notes ?? this.notes,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidToAccountId: paidToAccountId ?? this.paidToAccountId,
      recordId: recordId ?? this.recordId,
      paidRecordId: paidRecordId ?? this.paidRecordId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrowerName': borrowerName,
      'notes': notes,
      'accountId': accountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'paidToAccountId': paidToAccountId,
      'recordId': recordId,
      'paidRecordId': paidRecordId,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'] ?? '',
      borrowerName: map['borrowerName'] ?? '',
      notes: map['notes'],
      accountId: map['accountId'] ?? '',
      amount: (map['amount'] ?? 0.0) is int 
          ? (map['amount'] as int).toDouble() 
          : (map['amount'] ?? 0.0),
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : DateTime.now(),
      isPaid: (map['isPaid'] ?? 0) == 1,
      paidToAccountId: map['paidToAccountId'],
      recordId: map['recordId'] ?? '',
      paidRecordId: map['paidRecordId'],
    );
  }
}
