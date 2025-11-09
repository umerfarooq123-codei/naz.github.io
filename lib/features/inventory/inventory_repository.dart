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

    // All entries ADD stock (purchase/incoming)
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

  /// ✅ NEW: Update vendor ledger entries (if ledger table exists for vendor)
  Future<void> updateVendorLedger({
    required String vendorName,
    required String transactionType,
    required double amount,
    required String voucherNo,
    required DateTime date,
  }) async {
    final db = await _dbHelper.database;

    print("\n📒 --- updateVendorLedger START ---");
    print("👤 Vendor: $vendorName | Type: $transactionType | Amount: $amount");

    try {
      // Get vendor to find their ledger
      final vendorResult = await db.query(
        'customer',
        where: 'LOWER(name) = ?',
        whereArgs: [vendorName.toLowerCase()],
        limit: 1,
      );

      if (vendorResult.isEmpty) {
        print("⚠️ Vendor not found");
        return;
      }

      final vendorMap = vendorResult.first;
      final customerNo = vendorMap['customerNo'] as String?;

      if (customerNo == null) {
        print("⚠️ Vendor has no customerNo");
        return;
      }

      // Check if ledger exists for this vendor
      final ledgerResult = await db.query(
        'ledger',
        where: 'accountName = ? OR ledgerNo LIKE ?',
        whereArgs: [vendorName, '%$customerNo%'],
        limit: 1,
      );

      if (ledgerResult.isEmpty) {
        print("ℹ️ No ledger found for vendor - skipping ledger entry");
        return;
      }

      final ledgerNo = ledgerResult.first['ledgerNo'] as String;
      print("📘 Found ledger: $ledgerNo");

      // Create ledger entry table if not exists
      await _dbHelper.createLedgerEntryTable(ledgerNo);

      final safeLedgerNo = sanitizeIdentifier(ledgerNo);
      final tableName = 'ledger_entries_$safeLedgerNo';

      // Get current balance from last entry
      final lastEntry = await db.query(tableName, orderBy: 'id DESC', limit: 1);

      double previousBalance = 0.0;
      if (lastEntry.isNotEmpty) {
        final balanceValue = lastEntry.first['balance'];
        if (balanceValue is double) {
          previousBalance = balanceValue;
        } else if (balanceValue is int) {
          previousBalance = balanceValue.toDouble();
        } else if (balanceValue is String) {
          previousBalance = double.tryParse(balanceValue) ?? 0.0;
        }
      }

      print("📊 Previous ledger balance: $previousBalance");

      // Calculate new balance
      double debit = 0.0;
      double credit = 0.0;
      double newBalance = previousBalance;

      if (transactionType == "Credit") {
        credit = amount;
        newBalance = previousBalance + credit;
        print("➕ Adding credit: $previousBalance + $credit = $newBalance");
      } else if (transactionType == "Debit") {
        debit = amount;
        newBalance = previousBalance + debit;
        print("➕ Adding debit: $previousBalance + $debit = $newBalance");
      }

      // Insert ledger entry
      final entry = {
        'ledgerNo': ledgerNo,
        'voucherNo': voucherNo,
        'accountId': vendorMap['id'],
        'accountName': vendorName,
        'date': date.toIso8601String(),
        'transactionType': transactionType,
        'debit': debit,
        'credit': credit,
        'balance': newBalance,
        'status': 'completed',
        'description': 'Item Purchase - $voucherNo',
        'referenceNo': voucherNo,
        'category': 'purchase',
        'tags': 'inventory,purchase',
        'createdBy': 'system',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };

      await db.insert(tableName, entry);
      print(
        "✅ Ledger entry created: debit=$debit, credit=$credit, balance=$newBalance",
      );

      // Update main ledger table totals
      await db.rawUpdate(
        '''
        UPDATE ledger
        SET debit = debit + ?,
            credit = credit + ?,
            updatedAt = ?
        WHERE ledgerNo = ?
      ''',
        [debit, credit, DateTime.now().toIso8601String(), ledgerNo],
      );

      print("🔚 --- updateVendorLedger END ---\n");
    } catch (e, st) {
      print("❌ Error updating vendor ledger: $e");
      print(st);
    }
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
          vendorName TEXT NOT NULL,
          transactionType TEXT NOT NULL,
          debit REAL NOT NULL,
          pricePerKg REAL NOT NULL,
          costPrice REAL NOT NULL,
          sellingPrice REAL NOT NULL,
          canWeight REAL NOT NULL,
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

    final item = await getItemById(entry.itemId!);
    if (item == null) {
      print("❌ Item not found for entry");
      return 0;
    }

    // ✅ Reverse vendor balance
    final reverseType = entry.transactionType == "Credit" ? "Debit" : "Credit";
    final amount = entry.transactionType == "Credit"
        ? entry.credit
        : entry.debit;

    print(
      "🔄 Reversing vendor balance: $reverseType $amount for ${item.vendor}",
    );

    // ✅ Reverse vendor ledger entry
    await updateVendorLedger(
      vendorName: item.vendor,
      transactionType: reverseType,
      amount: amount,
      voucherNo: entry.voucherNo,
      date: entry.createdAt,
    );

    // Remove stock
    final qtyToRemove = entry.newStock;
    print("🔄 Removing $qtyToRemove from stock");

    final itemMap = await db.query(
      'item',
      where: 'id = ?',
      whereArgs: [entry.itemId],
    );
    if (itemMap.isNotEmpty) {
      final currentItem = Item.fromMap(itemMap.first);
      double newStock = currentItem.availableStock - qtyToRemove;
      if (newStock < 0) newStock = 0;

      await db.update(
        'item',
        {'availableStock': newStock},
        where: 'id = ?',
        whereArgs: [entry.itemId],
      );
      print("📦 Stock updated: ${currentItem.availableStock} → $newStock");
    }

    final deleteResult = await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    print("🗑️ Deleted | rows=$deleteResult");

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
      final idMatch = RegExp(r'_(\d+)$').firstMatch(ledgerNo);
      if (idMatch == null) {
        print("❌ Can't extract itemId from $ledgerNo");
        return;
      }
      final itemId = int.parse(idMatch.group(1)!);
      print("🆔 ItemId: $itemId");

      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      if (tableCheck.isEmpty) {
        print("⚠️ Table doesn't exist");
        return;
      }

      final entries = await db.query(
        tableName,
        where: 'itemId = ?',
        whereArgs: [itemId],
        orderBy: 'id ASC',
      );

      print("📊 Remaining entries: ${entries.length}");

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

      print("🟢 ENTRIES EXIST → Preserving pricing fields");

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

      await db.update(
        'item',
        {
          'availableStock': currentItem.availableStock,
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
