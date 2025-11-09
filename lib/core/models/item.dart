// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// Item Model
class Item {
  final int? id;
  final String name;
  final String type;
  final String vendor;
  double pricePerKg;
  double costPrice;
  double sellingPrice;
  double availableStock;
  double canWeight;

  Item({
    this.id,
    required this.name,
    required this.type,
    required this.vendor,
    this.pricePerKg = 0.0,
    this.costPrice = 0.0,
    this.sellingPrice = 0.0,
    this.availableStock = 0.0,
    this.canWeight = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'vendor': vendor,
      'pricePerKg': pricePerKg,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'availableStock': availableStock,
      'canWeight': canWeight,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      vendor: map['vendor'],
      pricePerKg: (map['pricePerKg'] as num).toDouble(),
      costPrice: (map['costPrice'] as num).toDouble(),
      sellingPrice: (map['sellingPrice'] as num).toDouble(),
      availableStock: (map['availableStock'] as num).toDouble(),
      canWeight: (map['canWeight'] as num).toDouble(),
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          pricePerKg == other.pricePerKg &&
          canWeight == other.canWeight &&
          availableStock == other.availableStock;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      pricePerKg.hashCode ^
      canWeight.hashCode ^
      availableStock.hashCode;
}

class ItemLedgerEntry {
  final int? id;
  final String ledgerNo;
  final String voucherNo;
  final int? itemId;
  final String itemName;
  final String vendorName;
  final String transactionType;
  final double debit;
  final double pricePerKg;
  final double costPrice;
  final double sellingPrice;
  final double canWeight;
  final double credit;
  final double newStock;
  double balance;
  final DateTime createdAt;
  DateTime? updatedAt;

  ItemLedgerEntry({
    this.id,
    required this.ledgerNo,
    required this.voucherNo,
    required this.itemId,
    required this.itemName,
    required this.vendorName,
    required this.transactionType,
    required this.debit,
    required this.pricePerKg,
    required this.costPrice,
    required this.sellingPrice,
    required this.canWeight,
    required this.credit,
    required this.newStock,
    required this.createdAt,
    this.updatedAt,
    this.balance = 0.0,
  });

  /// Convert object to Map (for DB or JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledgerNo': ledgerNo,
      'voucherNo': voucherNo,
      'itemId': itemId,
      'itemName': itemName,
      'vendorName': vendorName,
      'transactionType': transactionType,
      'debit': debit,
      'pricePerKg': pricePerKg,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'canWeight': canWeight,
      'credit': credit,
      'newStock': newStock,
      'balance': balance,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create object from Map
  factory ItemLedgerEntry.fromMap(Map<String, dynamic> map) {
    return ItemLedgerEntry(
      id: map['id'] != null ? map['id'] as int : null,
      ledgerNo: map['ledgerNo'] as String,
      voucherNo: map['voucherNo'] as String,
      itemId: map['itemId'] != null ? map['itemId'] as int : null,
      itemName: map['itemName'] as String,
      vendorName: map['vendorName'] as String,
      transactionType: map['transactionType'] as String,
      debit: (map['debit'] is int)
          ? (map['debit'] as int).toDouble()
          : (map['debit'] as double? ?? 0.0),
      pricePerKg: (map['pricePerKg'] is int)
          ? (map['pricePerKg'] as int).toDouble()
          : (map['pricePerKg'] as double? ?? 0.0),
      costPrice: (map['costPrice'] is int)
          ? (map['costPrice'] as int).toDouble()
          : (map['costPrice'] as double? ?? 0.0),
      sellingPrice: (map['sellingPrice'] is int)
          ? (map['sellingPrice'] as int).toDouble()
          : (map['sellingPrice'] as double? ?? 0.0),
      canWeight: (map['canWeight'] is int)
          ? (map['canWeight'] as int).toDouble()
          : (map['canWeight'] as double? ?? 0.0),
      credit: (map['credit'] is int)
          ? (map['credit'] as int).toDouble()
          : (map['credit'] as double? ?? 0.0),
      newStock: (map['newStock'] is int)
          ? (map['newStock'] as int).toDouble()
          : (map['newStock'] as double? ?? 0.0),
      balance: (map['balance'] is int)
          ? (map['balance'] as int).toDouble()
          : (map['balance'] as double? ?? 0.0),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }

  /// Convert object to JSON string
  String toJson() => json.encode(toMap());

  /// Create object from JSON string
  factory ItemLedgerEntry.fromJson(String source) =>
      ItemLedgerEntry.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ItemLedgerEntry(id: $id, ledgerNo: $ledgerNo, voucherNo: $voucherNo, itemName: $itemName, vendorName: $vendorName, debit: $debit, credit: $credit, balance: $balance, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
