class Customer {
  final int? id;
  final String name;
  final String address;
  final String customerNo;
  final String mobileNo;
  final String type;
  final String? ntnNo;
  final double openingBalance; // 👈 NEW required field

  Customer({
    this.id,
    required this.name,
    required this.address,
    required this.customerNo,
    required this.mobileNo,
    required this.type,
    this.ntnNo,
    required this.openingBalance, // 👈 make required
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'customerNo': customerNo,
      'mobileNo': mobileNo,
      'ntnNo': ntnNo,
      'type': type,
      'openingBalance': openingBalance, // 👈 include in map
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    double parseOpeningBalance(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return Customer(
      id: map['id'],
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      customerNo: map['customerNo'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      ntnNo: map['ntnNo'],
      type: map['type'] ?? '',
      openingBalance: parseOpeningBalance(
        map['openingBalance'],
      ), // ✅ safe parsing
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Customer.fromJson(Map<String, dynamic> json) =>
      Customer.fromMap(json);
}

class CustomerLedgerEntry {
  final int? id;
  final String voucherNo;
  final DateTime date;
  final String customerName;
  final String description;
  final double debit;
  final double credit;
  double balance;
  final String transactionType; // 'Debit' or 'Credit'
  final String? paymentMethod; // 'Cash' or 'Cheque'
  final String? chequeNo;
  final double? chequeAmount;
  final DateTime? chequeDate;
  final String? bankName;
  final DateTime createdAt;

  CustomerLedgerEntry({
    this.id,
    required this.voucherNo,
    required this.date,
    required this.customerName,
    required this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.transactionType,
    this.paymentMethod,
    this.chequeNo,
    this.chequeAmount,
    this.chequeDate,
    this.bankName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherNo': voucherNo,
      'date': date.toIso8601String(),
      'customerName': customerName,
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'transactionType': transactionType,
      'paymentMethod': paymentMethod,
      'chequeNo': chequeNo,
      'chequeAmount': chequeAmount,
      'chequeDate': chequeDate?.toIso8601String(),
      'bankName': bankName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerLedgerEntry.fromMap(Map<String, dynamic> map) {
    return CustomerLedgerEntry(
      id: map['id'],
      voucherNo: map['voucherNo'] ?? '',
      date: DateTime.parse(map['date']),
      customerName: map['customerName'] ?? '',
      description: map['description'] ?? '',
      debit: (map['debit'] ?? 0.0).toDouble(),
      credit: (map['credit'] ?? 0.0).toDouble(),
      balance: (map['balance'] ?? 0.0).toDouble(),
      transactionType: map['transactionType'] ?? 'Credit',
      paymentMethod: map['paymentMethod'],
      chequeNo: map['chequeNo'],
      chequeAmount: map['chequeAmount'] != null
          ? (map['chequeAmount'] as num).toDouble()
          : null,
      chequeDate: map['chequeDate'] != null
          ? DateTime.parse(map['chequeDate'])
          : null,
      bankName: map['bankName'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  CustomerLedgerEntry copyWith({
    int? id,
    String? voucherNo,
    DateTime? date,
    String? customerName,
    String? description,
    double? debit,
    double? credit,
    double? balance,
    String? transactionType,
    String? paymentMethod,
    String? chequeNo,
    double? chequeAmount,
    DateTime? chequeDate,
    String? bankName,
    DateTime? createdAt,
  }) {
    return CustomerLedgerEntry(
      id: id ?? this.id,
      voucherNo: voucherNo ?? this.voucherNo,
      date: date ?? this.date,
      customerName: customerName ?? this.customerName,
      description: description ?? this.description,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      balance: balance ?? this.balance,
      transactionType: transactionType ?? this.transactionType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      chequeNo: chequeNo ?? this.chequeNo,
      chequeAmount: chequeAmount ?? this.chequeAmount,
      chequeDate: chequeDate ?? this.chequeDate,
      bankName: bankName ?? this.bankName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
