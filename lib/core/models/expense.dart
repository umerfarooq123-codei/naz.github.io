class Expense {
  final int? id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
