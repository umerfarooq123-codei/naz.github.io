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

    print("\n🔍 --- updateItemStock START ---");
    print("📦 Input → itemId=$itemId | type=$transactionType | qty=$quantity");

    final itemMap = await db.query(
      'item',
      where: 'id = ?',
      whereArgs: [itemId],
    );

    if (itemMap.isEmpty) {
      print("⚠️ Item not found!");
      return 0;
    }

    final item = Item.fromMap(itemMap.first);
    print("📦 Current availableStock: ${item.availableStock}");

    // ✅ CORRECTED: Every entry ADDS stock (purchase/incoming)
    // Transaction type (Debit/Credit) is only for payment tracking
    double newStock = item.availableStock + quantity;

    print(
      "➕ Adding $quantity to stock (transactionType=$transactionType is for payment only)",
    );
    print("🧮 New availableStock: $newStock (was ${item.availableStock})");

    final result = await db.update(
      'item',
      {'availableStock': newStock},
      where: 'id = ?',
      whereArgs: [itemId],
    );

    final verify = await db.query('item', where: 'id = ?', whereArgs: [itemId]);
    print("✅ Updated: ${verify.first}");
    print("🔚 --- updateItemStock END ---\n");

    return result;
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
          newStock REAL NOT NULL,
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
      final tableExists = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM sqlite_master WHERE type=? AND name=?',
          ['table', tableName],
        ),
      );

      if (tableExists == 0) {
        if (kDebugMode) print("Table $tableName doesn't exist");
        return [];
      }

      final result = await db.query(tableName, orderBy: 'id ASC');
      return result.map((e) => ItemLedgerEntry.fromMap(e)).toList();
    } catch (e) {
      if (kDebugMode) print("Error fetching entries: $e");
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

    print("\n🗑️ === DELETE ENTRY START ===");

    // Get entry before deleting
    final entryRows = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (entryRows.isEmpty) {
      print("❌ Entry $id not found");
      return 0;
    }

    final entry = ItemLedgerEntry.fromMap(entryRows.first);
    print("📄 Deleting entry: ${entry.toMap()}");

    // ✅ CORRECTED: Since all entries ADD stock, deleting means SUBTRACTING
    // Use newStock field which contains the quantity that was added
    final qtyToRemove = entry.newStock;

    print("🔄 Removing $qtyToRemove from stock");

    final itemMap = await db.query(
      'item',
      where: 'id = ?',
      whereArgs: [entry.itemId],
    );
    if (itemMap.isNotEmpty) {
      final item = Item.fromMap(itemMap.first);
      double newStock = item.availableStock - qtyToRemove;
      if (newStock < 0) newStock = 0;

      await db.update(
        'item',
        {'availableStock': newStock},
        where: 'id = ?',
        whereArgs: [entry.itemId],
      );
      print("📦 Stock updated: ${item.availableStock} → $newStock");
    }

    // Delete entry
    final deleteResult = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    print("🗑️ Deleted | rows=$deleteResult");

    // Update item fields
    await updateItemFieldsAfterDeletion(ledgerNo: ledgerNo);

    print("🔚 === DELETE ENTRY END ===\n");
    return deleteResult;
  }

  Future<void> updateItemFieldsAfterDeletion({required String ledgerNo}) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';

    print("\n🔄 === UPDATE FIELDS AFTER DELETION START ===");

    try {
      // Extract itemId
      final idMatch = RegExp(r'_(\d+)$').firstMatch(ledgerNo);
      if (idMatch == null) {
        print("❌ Can't extract itemId from $ledgerNo");
        return;
      }
      final itemId = int.parse(idMatch.group(1)!);
      print("🆔 ItemId: $itemId");

      // Check table exists
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      if (tableCheck.isEmpty) {
        print("⚠️ Table doesn't exist");
        return;
      }

      // Get remaining entries
      final entries = await db.query(
        tableName,
        where: 'itemId = ?',
        whereArgs: [itemId],
        orderBy: 'id ASC',
      );

      print("📊 Remaining entries: ${entries.length}");

      // CASE 1: No entries → Reset all 5 fields to 0
      if (entries.isEmpty) {
        print("🟡 NO ENTRIES → Resetting 5 fields to 0");

        await db.update(
          'item',
          {
            'pricePerKg': 0.0,
            'costPrice': 0.0,
            'sellingPrice': 0.0,
            'availableStock': 0.0,
            'canWeight': 0.0,
          },
          where: 'id = ?',
          whereArgs: [itemId],
        );

        final verify = await db.query(
          'item',
          where: 'id = ?',
          whereArgs: [itemId],
        );
        print("✅ Reset complete: ${verify.first}");
        print("🔚 === UPDATE FIELDS END ===\n");
        return;
      }

      // CASE 2: Entries exist → Update from last entry
      print("🟢 ENTRIES EXIST → Updating from last entry");

      final lastEntry = ItemLedgerEntry.fromMap(entries.last);
      print("📌 Last entry: id=${lastEntry.id}, balance=${lastEntry.balance}");

      // Get current item
      final itemData = await db.query(
        'item',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      if (itemData.isEmpty) {
        print("❌ Item not found");
        return;
      }
      final currentItem = Item.fromMap(itemData.first);

      // Update: availableStock from current item (already updated by stock removal)
      // Pricing fields should remain from current item
      await db.update(
        'item',
        {
          'availableStock': currentItem.availableStock, // Already correct
          'pricePerKg': currentItem.pricePerKg,
          'costPrice': currentItem.costPrice,
          'sellingPrice': currentItem.sellingPrice,
          'canWeight': currentItem.canWeight,
        },
        where: 'id = ?',
        whereArgs: [itemId],
      );

      final verify = await db.query(
        'item',
        where: 'id = ?',
        whereArgs: [itemId],
      );
      print("✅ Fields preserved: ${verify.first}");
      print("🔚 === UPDATE FIELDS END ===\n");
    } catch (e, st) {
      print("❌ Exception: $e");
      print(st);
    }
  }

  Future<String> getLastVoucherNo(String ledgerNo) async {
    final db = await _dbHelper.database;
    final safeLedgerNo = sanitizeIdentifier(ledgerNo);
    final tableName = 'item_ledger_entries_$safeLedgerNo';

    try {
      final tableExists = Sqflite.firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM sqlite_master WHERE type=? AND name=?',
          ['table', tableName],
        ),
      );

      if (tableExists == 0) {
        return 'VN01';
      }

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
      }
      return 'VN01';
    } catch (e) {
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
