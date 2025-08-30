class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final double outstandingBalance;
  final Map<String, dynamic>? metadata;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.outstandingBalance = 0.0,
    this.metadata,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    phone: json['phone'] as String?,
    outstandingBalance: (json['outstandingBalance'] ?? 0).toDouble(),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'outstandingBalance': outstandingBalance,
    'metadata': metadata,
  };
}
