class PlannedPayment {
  final String id;
  final String name;
  final String categoryId;
  final String accountId;
  final double amount;
  final String currency;
  final String? notes;
  final String frequency; // 'one-time' | 'recurring'
  final DateTime startDate;
  final String? recurrence; // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String endType; // 'forever' | 'until-date' | 'occurrences'
  final DateTime? endDate;
  final int? endOccurrences;
  final String? label;

  PlannedPayment({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.accountId,
    required this.amount,
    required this.currency,
    this.notes,
    required this.frequency,
    required this.startDate,
    this.recurrence,
    required this.endType,
    this.endDate,
    this.endOccurrences,
    this.label,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'accountId': accountId,
      'amount': amount,
      'currency': currency,
      'notes': notes,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'recurrence': recurrence,
      'endType': endType,
      'endDate': endDate?.toIso8601String(),
      'endOccurrences': endOccurrences,
      'label': label,
    };
  }

  factory PlannedPayment.fromMap(Map<String, dynamic> map) {
    return PlannedPayment(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      categoryId: map['categoryId'] ?? '',
      accountId: map['accountId'] ?? '',
      amount: (map['amount'] ?? 0.0) is int 
          ? (map['amount'] as int).toDouble() 
          : (map['amount'] ?? 0.0),
      currency: map['currency'] ?? 'INR',
      notes: map['notes'],
      frequency: map['frequency'] ?? 'one-time',
      startDate: map['startDate'] != null 
          ? DateTime.parse(map['startDate']) 
          : DateTime.now(),
      recurrence: map['recurrence'],
      endType: map['endType'] ?? 'forever',
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      endOccurrences: map['endOccurrences'],
      label: map['label'],
    );
  }
}
