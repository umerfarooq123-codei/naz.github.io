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
