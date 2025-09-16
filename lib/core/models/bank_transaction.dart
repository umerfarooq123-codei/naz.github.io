class BankTransaction {
  final int? id;
  final String description;
  final DateTime date;
  final double amount;
  final String type; // CREDIT or DEBIT
  final bool cleared; // true if matched with ledger

  BankTransaction({
    this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.type,
    this.cleared = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type,
      'cleared': cleared ? 1 : 0,
    };
  }

  factory BankTransaction.fromMap(Map<String, dynamic> map) {
    return BankTransaction(
      id: map['id'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      amount: map['amount'],
      type: map['type'],
      cleared: map['cleared'] == 1,
    );
  }
}
