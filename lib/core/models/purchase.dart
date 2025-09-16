class Purchase {
  final int? id;
  final int vendorId;
  final String purchaseNumber;
  final DateTime date;
  final double totalAmount;
  final double paidAmount;

  Purchase({
    this.id,
    required this.vendorId,
    required this.purchaseNumber,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
  });

  double get balance => totalAmount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendorId': vendorId,
      'purchaseNumber': purchaseNumber,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      vendorId: map['vendorId'],
      purchaseNumber: map['purchaseNumber'],
      date: DateTime.parse(map['date']),
      totalAmount: map['totalAmount'],
      paidAmount: map['paidAmount'],
    );
  }
}
