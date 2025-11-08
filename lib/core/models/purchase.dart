class ExpensePurchase {
  int? id;
  DateTime date;
  String description;
  double amount;
  String madeBy;
  String category;
  String paymentMethod;
  String? referenceNumber;
  String? notes;
  DateTime createdAt;
  DateTime updatedAt;

  ExpensePurchase({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.madeBy,
    this.category = 'General',
    this.paymentMethod = 'Cash',
    this.referenceNumber,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'amount': amount,
      'madeBy': madeBy,
      'category': category,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ExpensePurchase.fromMap(Map<String, dynamic> map) {
    return ExpensePurchase(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      description: map['description'],
      amount: map['amount'],
      madeBy: map['madeBy'],
      category: map['category'] ?? 'General',
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      referenceNumber: map['referenceNumber'],
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  ExpensePurchase copyWith({
    int? id,
    DateTime? date,
    String? description,
    double? amount,
    String? madeBy,
    String? category,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpensePurchase(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      madeBy: madeBy ?? this.madeBy,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
