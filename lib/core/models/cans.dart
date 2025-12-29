// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

/// Model representing a Cans table for a customer
class Cans {
  final int? id;
  final String accountName;
  final int? accountId;
  final double openingBalanceCans;
  final double currentCans;
  final double totalCans;
  final double receivedCans;
  final DateTime insertedDate;
  final DateTime updatedDate;

  Cans({
    this.id,
    required this.accountName,
    this.accountId,
    required this.openingBalanceCans,
    required this.currentCans,
    required this.totalCans,
    required this.receivedCans,
    required this.insertedDate,
    required this.updatedDate,
  });

  /// Creates a copy of this object with the specified fields replaced with new values.
  Cans copyWith({
    int? id,
    String? accountName,
    int? accountId,
    double? openingBalanceCans,
    double? currentCans,
    double? totalCans,
    double? receivedCans,
    DateTime? insertedDate,
    DateTime? updatedDate,
  }) {
    return Cans(
      id: id ?? this.id,
      accountName: accountName ?? this.accountName,
      accountId: accountId ?? this.accountId,
      openingBalanceCans: openingBalanceCans ?? this.openingBalanceCans,
      currentCans: currentCans ?? this.currentCans,
      totalCans: totalCans ?? this.totalCans,
      receivedCans: receivedCans ?? this.receivedCans,
      insertedDate: insertedDate ?? this.insertedDate,
      updatedDate: updatedDate ?? this.updatedDate,
    );
  }

  /// Converts the model to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountName': accountName,
      'accountId': accountId,
      'openingBalanceCans': openingBalanceCans,
      'currentCans': currentCans,
      'totalCans': totalCans,
      'receivedCans': receivedCans,
      'insertedDate': insertedDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
    };
  }

  /// Creates a model instance from a Map (database or API response)
  factory Cans.fromMap(Map<String, dynamic> map) {
    return Cans(
      id: map['id'],
      accountName: map['accountName'] ?? '',
      accountId: map['accountId'],
      openingBalanceCans: (map['openingBalanceCans'] as num?)?.toDouble() ?? 0.0,
      currentCans: (map['currentCans'] as num?)?.toDouble() ?? 0.0,
      totalCans: (map['totalCans'] as num?)?.toDouble() ?? 0.0,
      receivedCans: (map['receivedCans'] as num?)?.toDouble() ?? 0.0,
      insertedDate: map['insertedDate'] != null
          ? DateTime.parse(map['insertedDate'])
          : DateTime.now(),
      updatedDate: map['updatedDate'] != null
          ? DateTime.parse(map['updatedDate'])
          : DateTime.now(),
    );
  }

  /// Converts the model to a JSON string
  String toJson() => jsonEncode(toMap());

  /// Creates a model instance from a JSON string
  factory Cans.fromJson(String source) =>
      Cans.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Cans(id: $id, accountName: $accountName, accountId: $accountId, openingBalanceCans: $openingBalanceCans, currentCans: $currentCans, totalCans: $totalCans, receivedCans: $receivedCans, insertedDate: $insertedDate, updatedDate: $updatedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cans &&
        other.id == id &&
        other.accountName == accountName &&
        other.accountId == accountId &&
        other.openingBalanceCans == openingBalanceCans &&
        other.currentCans == currentCans &&
        other.totalCans == totalCans &&
        other.receivedCans == receivedCans &&
        other.insertedDate == insertedDate &&
        other.updatedDate == updatedDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        accountName.hashCode ^
        accountId.hashCode ^
        openingBalanceCans.hashCode ^
        currentCans.hashCode ^
        totalCans.hashCode ^
        receivedCans.hashCode ^
        insertedDate.hashCode ^
        updatedDate.hashCode;
  }
}

/// Model representing a transaction entry in a Cans table
class CansEntry {
  final int? id;
  final int cansId;
  final String voucherNo;
  final int? accountId;
  final String accountName;
  final DateTime date;
  final String transactionType;
  final double currentCans;
  final double receivedCans;
  final double balance;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  CansEntry({
    this.id,
    required this.cansId,
    required this.voucherNo,
    this.accountId,
    required this.accountName,
    required this.date,
    required this.transactionType,
    required this.currentCans,
    required this.receivedCans,
    required this.balance,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this object with the specified fields replaced with new values.
  CansEntry copyWith({
    int? id,
    int? cansId,
    String? voucherNo,
    int? accountId,
    String? accountName,
    DateTime? date,
    String? transactionType,
    double? currentCans,
    double? receivedCans,
    double? balance,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CansEntry(
      id: id ?? this.id,
      cansId: cansId ?? this.cansId,
      voucherNo: voucherNo ?? this.voucherNo,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      date: date ?? this.date,
      transactionType: transactionType ?? this.transactionType,
      currentCans: currentCans ?? this.currentCans,
      receivedCans: receivedCans ?? this.receivedCans,
      balance: balance ?? this.balance,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the model to a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cansId': cansId,
      'voucherNo': voucherNo,
      'accountId': accountId,
      'accountName': accountName,
      'date': date.toIso8601String(),
      'transactionType': transactionType,
      'currentCans': currentCans,
      'receivedCans': receivedCans,
      'balance': balance,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a model instance from a Map (database or API response)
  factory CansEntry.fromMap(Map<String, dynamic> map) {
    return CansEntry(
      id: map['id'],
      cansId: map['cansId'] ?? 0,
      voucherNo: map['voucherNo'] ?? '',
      accountId: map['accountId'],
      accountName: map['accountName'] ?? '',
      date:
          map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      transactionType: map['transactionType'] ?? '',
      currentCans: (map['currentCans'] as num?)?.toDouble() ?? 0.0,
      receivedCans: (map['receivedCans'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      description: map['description'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Converts the model to a JSON string
  String toJson() => jsonEncode(toMap());

  /// Creates a model instance from a JSON string
  factory CansEntry.fromJson(String source) =>
      CansEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'CansEntry(id: $id, cansId: $cansId, voucherNo: $voucherNo, accountId: $accountId, accountName: $accountName, date: $date, transactionType: $transactionType, currentCans: $currentCans, receivedCans: $receivedCans, balance: $balance, description: $description, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CansEntry &&
        other.id == id &&
        other.cansId == cansId &&
        other.voucherNo == voucherNo &&
        other.accountId == accountId &&
        other.accountName == accountName &&
        other.date == date &&
        other.transactionType == transactionType &&
        other.currentCans == currentCans &&
        other.receivedCans == receivedCans &&
        other.balance == balance &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        cansId.hashCode ^
        voucherNo.hashCode ^
        accountId.hashCode ^
        accountName.hashCode ^
        date.hashCode ^
        transactionType.hashCode ^
        currentCans.hashCode ^
        receivedCans.hashCode ^
        balance.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
