import 'package:flutter/foundation.dart';
import 'package:ledger_master/core/database/db_helper.dart';

class VendorLedgerEntry {
  final int? id;
  final String voucherNo;
  final String vendorName;
  final int vendorId;
  final DateTime date;
  final String? description;
  final double debit;
  final double credit;
  final double balance;
  final String transactionType;
  final String? paymentMethod;
  final String? chequeNo;
  final double? chequeAmount;
  final String? chequeDate;
  final String? bankName;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorLedgerEntry({
    this.id,
    required this.voucherNo,
    required this.vendorName,
    required this.vendorId,
    required this.date,
    this.description,
    required this.debit,
    required this.credit,
    required this.balance,
    required this.transactionType,
    this.paymentMethod,
    this.chequeNo,
    this.chequeAmount,
    this.chequeDate,
    this.bankName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'voucherNo': voucherNo,
      'vendorName': vendorName,
      'vendorId': vendorId,
      'date': date.toIso8601String(),
      'description': description,
      'debit': debit,
      'credit': credit,
      'balance': balance,
      'transactionType': transactionType,
      'paymentMethod': paymentMethod,
      'chequeNo': chequeNo,
      'chequeAmount': chequeAmount,
      'chequeDate': chequeDate,
      'bankName': bankName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static VendorLedgerEntry fromMap(Map<String, dynamic> map) {
    return VendorLedgerEntry(
      id: map['id'] as int?,
      voucherNo: map['voucherNo'] as String,
      vendorName: map['vendorName'] as String,
      vendorId: map['vendorId'] as int,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      transactionType: map['transactionType'] as String,
      paymentMethod: map['paymentMethod'] as String?,
      chequeNo: map['chequeNo'] as String?,
      chequeAmount: (map['chequeAmount'] as num?)?.toDouble(),
      chequeDate: map['chequeDate'] as String?,
      bankName: map['bankName'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}

class VendorLedgerRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> insertVendorLedgerEntry(VendorLedgerEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert('vendor_ledger_entries', entry.toMap());
  }

  Future<List<VendorLedgerEntry>> getVendorLedgerEntries(
    String vendorName,
    int vendorId,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'vendor_ledger_entries',
      where: 'UPPER(vendorName) = UPPER(?) AND vendorId = ?',
      whereArgs: [vendorName, vendorId],
      orderBy: 'date ASC, id ASC',
    );
    return result.map((e) => VendorLedgerEntry.fromMap(e)).toList();
  }

  Future<int> updateVendorLedgerEntry(VendorLedgerEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'vendor_ledger_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteVendorLedgerEntry(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'vendor_ledger_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DebitCreditSummary> fetchTotalDebitAndCredit(
    String vendorName,
    int vendorId,
  ) async {
    final db = await _dbHelper.database;

    debugPrint('=== fetchTotalDebitAndCredit (Vendor) ===');
    debugPrint('vendorName: $vendorName');
    debugPrint('vendorId: $vendorId');

    try {
      final result = await db.rawQuery(
        '''
      SELECT
        COALESCE(SUM(debit), 0) AS totalDebit,
        COALESCE(SUM(credit), 0) AS totalCredit
      FROM vendor_ledger_entries
      WHERE UPPER(vendorName) = UPPER(?) AND vendorId = ?
    ''',
        [vendorName, vendorId],
      );

      debugPrint('result.isEmpty: ${result.isEmpty}');
      if (result.isNotEmpty) {
        debugPrint('row: ${result.first}');
      }

      final row = result.firstOrNull ?? {};

      final totalDebit = (row['totalDebit'] ?? 0).toString();
      final totalCredit = (row['totalCredit'] ?? 0).toString();

      return DebitCreditSummary(debit: totalDebit, credit: totalCredit);
    } catch (e) {
      debugPrint('Error in fetchTotalDebitAndCredit: $e');
      return DebitCreditSummary(debit: '0', credit: '0');
    }
  }

  Future<String> getLastVoucherNo(String vendorName, int vendorId) async {
    final db = await _dbHelper.database;

    try {
      final result = await db.query(
        'vendor_ledger_entries',
        columns: ['voucherNo'],
        where: 'UPPER(vendorName) = UPPER(?) AND vendorId = ?',
        whereArgs: [vendorName, vendorId],
        orderBy: 'voucherNo DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        final lastVoucherNo = result.first['voucherNo'] as String;

        final regex = RegExp(r'(\d+)$');
        final match = regex.firstMatch(lastVoucherNo);

        if (match != null) {
          final num = int.parse(match.group(1)!);
          return 'VN${(num + 1).toString().padLeft(4, '0')}';
        }
      }

      return 'VN0001';
    } catch (e) {
      debugPrint('Error getting last vendor voucher no: $e');
      return 'VN0001';
    }
  }
}

class DebitCreditSummary {
  final String debit;
  final String credit;

  DebitCreditSummary({required this.debit, required this.credit});
}
