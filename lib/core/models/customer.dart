class Customer {
  final int? id;
  final String name;
  final String address;
  final String customerNo;
  final String mobileNo;
  final String? ntnNo;

  Customer({
    this.id,
    required this.name,
    required this.address,
    required this.customerNo,
    required this.mobileNo,
    this.ntnNo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'customerNo': customerNo,
      'mobileNo': mobileNo,
      'ntnNo': ntnNo,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      customerNo: map['customerNo'],
      mobileNo: map['mobileNo'],
      ntnNo: map['ntnNo'],
    );
  }
  static String generateCustomerNo() {
    return 'CUST${DateTime.now().millisecondsSinceEpoch}';
  }
}
