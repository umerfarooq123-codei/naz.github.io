// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class StockTransaction {
  final int? id;
  final int itemId;
  final double quantity; // Changed from int to double
  final String type;
  final DateTime date;

  StockTransaction({
    this.id,
    required this.itemId,
    required this.quantity, // Now double
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'quantity': quantity, // Now double
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'],
      itemId: map['itemId'],
      quantity: (map['quantity'] as num).toDouble(), // Convert to double
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }
}

class LedgerEntry {
  final int? id;
  final String ledgerNo;
  final String voucherNo;
  final int? accountId;
  final String accountName;
  final DateTime date;
  final String transactionType;
  final double debit;
  final double credit;
  double balance;
  final String status;
  final String? description;
  final String? referenceNo;
  final String? category;
  final List<String>? tags;
  final String? createdBy;
  String? balanceCans;
  String? receivedCans;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? itemId;
  final String? itemName;
  final double? itemPricePerUnit;
  final double? canWeight;
  final int? cansQuantity;
  final double? sellingPricePerCan;
  final String? paymentMethod;
  final String? chequeNo;
  final double? chequeAmount;
  final DateTime? chequeDate;
  final String? bankName;

  LedgerEntry({
    this.id,
    required this.ledgerNo,
    required this.voucherNo,
    this.accountId,
    required this.accountName,
    required this.date,
    required this.transactionType,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.status,
    this.description,
    this.referenceNo,
    this.category,
    this.tags,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.balanceCans,
    required this.receivedCans,
    this.itemId,
    this.itemName,
    this.itemPricePerUnit,
    this.canWeight,
    this.cansQuantity,
    this.sellingPricePerCan,
    this.paymentMethod,
    this.chequeNo,
    this.chequeAmount,
    this.chequeDate,
    this.bankName,
  });

  double get totalWeight {
    if (cansQuantity == null || canWeight == null) return 0.0;
    return cansQuantity! * canWeight!;
  }

  /// Converts model to Map for database or API use
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledgerNo': ledgerNo,
      'voucherNo': voucherNo,
      'accountId': accountId,
      'accountName': accountName,
      'date': date.toIso8601String(),
      'transactionType': transactionType,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'status': status,
      'description': description,
      'referenceNo': referenceNo,
      'category': category,
      'tags': tags != null ? jsonEncode(tags) : null,
      'createdBy': createdBy,
      'balanceCans': balanceCans,
      'receivedCans': receivedCans,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'itemId': itemId,
      'itemName': itemName,
      'itemPricePerUnit': itemPricePerUnit,
      'canWeight': canWeight,
      'cansQuantity': cansQuantity,
      'sellingPricePerCan': sellingPricePerCan,
      'paymentMethod': paymentMethod,
      'chequeNo': chequeNo,
      'chequeAmount': chequeAmount,
      'chequeDate': chequeDate?.toIso8601String(),
      'bankName': bankName,
    };
  }

  /// Converts model to JSON string
  String toJson() => jsonEncode(toMap());

  /// Helper for safe DateTime parsing
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        final parts = value.split('-');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  /// Creates model from Map
  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'],
      ledgerNo: map['ledgerNo'] ?? '',
      voucherNo: map['voucherNo'] ?? '',
      accountId: map['accountId'],
      accountName: map['accountName'] ?? '',
      date: _parseDate(map['date']),
      transactionType: map['transactionType'] ?? '',
      debit: (map['debit'] ?? 0).toDouble(),
      credit: (map['credit'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
      status: map['status'] ?? '',
      description: map['description'],
      referenceNo: map['referenceNo'],
      category: map['category'],
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags']))
          : null,
      createdBy: map['createdBy'],
      balanceCans: map['balanceCans'],
      receivedCans: map['receivedCans'],
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      itemId: map['itemId'],
      itemName: map['itemName'],
      itemPricePerUnit: map['itemPricePerUnit'] != null
          ? (map['itemPricePerUnit'] as num).toDouble()
          : null,
      canWeight: map['canWeight'] != null
          ? (map['canWeight'] as num).toDouble()
          : null,
      cansQuantity: map['cansQuantity'],
      sellingPricePerCan: map['sellingPricePerCan'] != null
          ? (map['sellingPricePerCan'] as num).toDouble()
          : null,
      paymentMethod: map['paymentMethod'],
      chequeNo: map['chequeNo'],
      chequeAmount: map['chequeAmount'] != null
          ? (map['chequeAmount'] as num).toDouble()
          : null,
      chequeDate: _parseDate(map['chequeDate']),
      bankName: map['bankName'],
    );
  }

  /// Creates model from JSON string
  factory LedgerEntry.fromJson(String source) =>
      LedgerEntry.fromMap(jsonDecode(source));
}

class Ledger {
  final int? id;
  final String ledgerNo;
  final int? accountId;
  final String accountName;
  final String transactionType;
  final double debit;
  final double credit;
  final DateTime date;
  final String? description;
  final String? referenceNumber;
  final int? transactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? category;
  final List<String>? tags;
  final String voucherNo;
  final double balance;
  final String status;

  Ledger({
    this.id,
    required this.ledgerNo,
    this.accountId,
    required this.accountName,
    required this.transactionType,
    required this.debit,
    required this.credit,
    required this.date,
    this.description,
    this.referenceNumber,
    this.transactionId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.category,
    this.tags,
    required this.voucherNo,
    required this.balance,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ledgerNo': ledgerNo,
      'accountId': accountId,
      'accountName': accountName,
      'transactionType': transactionType,
      'debit': debit,
      'credit': credit,
      'date': date.toIso8601String(),
      'description': description,
      'referenceNumber': referenceNumber,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
      'category': category,
      'tags': tags != null ? jsonEncode(tags) : null,
      'voucherNo': voucherNo,
      'balance': balance,
      'status': status,
    };
  }

  factory Ledger.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();

      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          final parts = value.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return Ledger(
      id: map['id'],
      ledgerNo: map['ledgerNo'],
      accountId: map['accountId'],
      accountName: map['accountName'],
      transactionType: map['transactionType'],
      debit: (map['debit'] as num).toDouble(),
      credit: (map['credit'] as num).toDouble(),
      date: parseDate(map['date']),
      description: map['description'],
      referenceNumber: map['referenceNumber'],
      transactionId: map['transactionId'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      createdBy: map['createdBy'],
      category: map['category'],
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags']))
          : null,
      voucherNo: map['voucherNo'],
      balance: (map['balance'] as num).toDouble(),
      status: map['status'],
    );
  }
}

class TransactionItem {
  final int id;
  final String type;
  final String ledgerNo;
  final DateTime date;
  double debit;
  double credit;
  double balance;
  String status;

  TransactionItem({
    required this.id,
    required this.type,
    required this.ledgerNo,
    required this.date,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.status,
  });
}
