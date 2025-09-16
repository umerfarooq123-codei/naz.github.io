class Invoice {
  final int? id;
  final int customerId;
  final String invoiceNumber;
  final DateTime date;
  final double totalAmount;
  final double paidAmount;

  Invoice({
    this.id,
    required this.customerId,
    required this.invoiceNumber,
    required this.date,
    required this.totalAmount,
    required this.paidAmount,
  });

  double get balance => totalAmount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      customerId: map['customerId'],
      invoiceNumber: map['invoiceNumber'],
      date: DateTime.parse(map['date']),
      totalAmount: map['totalAmount'],
      paidAmount: map['paidAmount'],
    );
  }
}
