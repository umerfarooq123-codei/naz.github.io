import 'package:collection/collection.dart';

class Account {
  final String id;
  final String name;
  final String accountType; // asset, liability, equity, income, expense
  final double openingBalance;
  final Map<String, dynamic>? metadata;

  Account({
    required this.id,
    required this.name,
    required this.accountType,
    this.openingBalance = 0.0,
    this.metadata,
  });

  Account copyWith({
    String? id,
    String? name,
    String? accountType,
    double? openingBalance,
    Map<String, dynamic>? metadata,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    accountType: accountType ?? this.accountType,
    openingBalance: openingBalance ?? this.openingBalance,
    metadata: metadata ?? this.metadata,
  );

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'] as String,
    name: json['name'] as String,
    accountType: json['accountType'] as String,
    openingBalance: (json['openingBalance'] ?? 0).toDouble(),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'accountType': accountType,
    'openingBalance': openingBalance,
    'metadata': metadata,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => id.hashCode;
}
