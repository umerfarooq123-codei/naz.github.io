import 'package:flutter/foundation.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/db_helper.dart';
import '../../core/models/item.dart';

class InventoryRepository {
  final DBHelper _dbHelper = DBHelper();
  Future<int> insertItem(Item item) async {
    final db = await _dbHelper.database;
    return await db.insert('item', item.toMap());
  }

  Future<List<Item>> getAllItems() async {
    final db = await _dbHelper.database;
    final result = await db.query('item', orderBy: 'name ASC');
    return result.map((e) => Item.fromMap(e)).toList();
  }

  Future<int> updateItem(Item item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'item',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<Item?> getItemById(int itemId) async {
    final db = await _dbHelper.database;
    final result = await db.query('item', where: 'id = ?', whereArgs: [itemId]);
    if (result.isEmpty) return null;
    return Item.fromMap(result.first);
  }

  Future<int> updateItemStock({
    required int itemId,
    required String transactionType,
    required double quantity,
  }) async {
    final db = await _dbHelper.database;
    final itemMap = await db.query(
      'item',
      where: 'id = ?',
      whereArgs: [itemId],
    );
    if (itemMap.isEmpty) throw Exception('Item not found');
    final item = Item.fromMap(itemMap.first);
    final newStock = transactionType == "Credit"
        ? item.availableStock + quantity
        : item.availableStock - quantity;
    if (newStock < 0) throw Exception('Insufficient stock');
    return await db.update(
      'item',
      {'availableStock': newStock},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('item', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertStockTransaction(StockTransaction tx) async {
    final db = await _dbHelper.database;
    return await db.transaction<int>((txn) async {
      final itemMap = await txn.query(
        'item',
        where: 'id = ?',
        whereArgs: [tx.itemId],
      );
      if (itemMap.isEmpty) throw Exception('Item not found');
      final item = Item.fromMap(itemMap.first);
      final isIn = tx.type == 'IN';
      final newStock = isIn
          ? (item.availableStock + tx.quantity)
          : (item.availableStock - tx.quantity);
      if (newStock < 0) throw Exception('Insufficient stock');
      await txn.update(
        'item',
        {'availableStock': newStock},
        where: 'id = ?',
        whereArgs: [tx.itemId],
      );
      return await txn.insert('stock_transaction', tx.toMap());
    });
  }

  Future<List<StockTransaction>> getStockTransactions(int itemId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'stock_transaction',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'date DESC',
    );
    return result.map((e) => StockTransaction.fromMap(e)).toList();
  }

  Future<List<Item>> getLowStockItems(int threshold) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'item',
      where: 'availableStock <= ?',
      whereArgs: [threshold],
    );
    return result.map((e) => Item.fromMap(e)).toList();
  }

  Future<void> createItemLedgerEntryTable(String ledgerNo) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';
    try {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS $tableName (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ledgerNo TEXT NOT NULL,
    voucherNo TEXT NOT NULL,
    itemId INTEGER,
    itemName TEXT NOT NULL,
    transactionType TEXT NOT NULL,
    debit REAL NOT NULL,
    credit REAL NOT NULL,
    balance REAL NOT NULL,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER NOT NULL
    )
    ''');
    } catch (e) {
      rethrow;
    }
  }

  Future<int> insertItemLedgerEntry(
    String ledgerNo,
    ItemLedgerEntry entry,
  ) async {
    await createItemLedgerEntryTable(ledgerNo);
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';
    return await db.insert(
      tableName,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ItemLedgerEntry>> getItemLedgerEntries(String ledgerNo) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';
    try {
      final result = await db.query(tableName);
      return result.map((e) => ItemLedgerEntry.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching ledger entries: $e");
      }
      return [];
    }
  }

  Future<ItemLedgerEntry?> getItemLedgerEntryById(
    String ledgerNo,
    int id,
  ) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';
    final result = await db.query(tableName, where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return ItemLedgerEntry.fromMap(result.first);
  }

  Future<int> deleteItemLedgerEntry(String ledgerNo, int id) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getLastVoucherNo(String ledgerNo) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';
    try {
      final result = await db.query(
        tableName,
        columns: ['voucherNo'],
        orderBy: 'voucherNo DESC',
        limit: 1,
      );
      if (result.isNotEmpty) {
        final lastVoucher = result.first['voucherNo'] as String;
        final match = RegExp(r'([A-Za-z]*)(\d+)').firstMatch(lastVoucher);
        if (match != null) {
          final prefix = match.group(1) ?? '';
          final number = int.parse(match.group(2)!);
          final nextNumber = number + 1;
          return '$prefix${nextNumber.toString().padLeft(2, '0')}';
        }
        return 'VN01';
      } else {
        return 'VN01';
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error getting last voucher number: $e");
      }
      return 'VN01';
    }
  }

  Future<int?> getLastInsertedItemId() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT id FROM item ORDER BY id DESC LIMIT 1',
    );
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return 1;
  }

  String sanitizeIdentifier(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
  }
}
