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
  final String transactionType;
  final double debit;
  final double credit;
  double balance;
  final DateTime createdAt;
  DateTime? updatedAt;

  ItemLedgerEntry({
    this.id,
    required this.ledgerNo,
    required this.voucherNo,
    required this.itemId,
    required this.itemName,
    required this.transactionType,
    required this.debit,
    required this.credit,
    required this.createdAt,
    this.updatedAt,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ledgerNo': ledgerNo,
      'voucherNo': voucherNo,
      'itemId': itemId,
      'itemName': itemName,
      'transactionType': transactionType,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt!.millisecondsSinceEpoch,
    };
  }

  factory ItemLedgerEntry.fromMap(Map<String, dynamic> map) {
    return ItemLedgerEntry(
      id: map['id'] != null ? map['id'] as int : null,
      ledgerNo: map['ledgerNo'] as String,
      voucherNo: map['voucherNo'] as String,
      itemId: map['itemId'] != null ? map['itemId'] as int : null,
      itemName: map['itemName'] as String,
      transactionType: map['transactionType'] as String,
      debit: map['debit'] as double,
      credit: map['credit'] as double,
      balance: map['balance'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  String toJson() => json.encode(toMap());

  factory ItemLedgerEntry.fromJson(String source) =>
      ItemLedgerEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
