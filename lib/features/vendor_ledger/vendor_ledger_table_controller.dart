import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_repository.dart';

class VendorLedgerTableController extends GetxController {
  final repo = VendorLedgerRepository();
  final customerRepo = CustomerRepository();
  final _dbHelper = DBHelper();

  final currentVendor = Rx<Customer?>(null);
  final vendorLedgerEntries = <VendorLedgerEntry>[].obs;
  final filteredVendorEntries = <VendorLedgerEntry>[].obs;

  final fromDate = Rx<DateTime>(DateTime.now().subtract(Duration(days: 30)));
  final toDate = Rx<DateTime>(DateTime.now());

  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final searchController = TextEditingController();

  final selectedTransactionType = RxnString();
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  // Reactive totals for UI updates
  final RxDouble rxTotalDebit = 0.0.obs;
  final RxDouble rxTotalCredit = 0.0.obs;
  final RxDouble rxNetBalance = 0.0.obs;

  var openingBalance = 0.0;
  var itemLedgerCredits = 0.0;
  var itemLedgerDebits = 0.0;
  Customer? vendor;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    fromDate.value = thirtyDaysAgo;
    toDate.value = now;
    fromDateController.text = DateFormat('dd-MM-yyyy').format(thirtyDaysAgo);
    toDateController.text = DateFormat('dd-MM-yyyy').format(now);

    ever(searchQuery, (_) {
      _applyFilters();
      updateReactiveTotals();
    });
    ever(fromDate, (_) {
      _applyFilters();
      updateReactiveTotals();
    });
    ever(toDate, (_) {
      _applyFilters();
      updateReactiveTotals();
    });
    ever(selectedTransactionType, (_) {
      _applyFilters();
      updateReactiveTotals();
    });
    ever(filteredVendorEntries, (_) {
      updateReactiveTotals();
    });
    ever(currentVendor, (_) {
      _initializeFilters();
    });
  }

  Future<void> _initializeFilters() async {
    if (currentVendor.value == null) {
      debugPrint('⚠️ _initializeFilters: currentVendor is null!');
      return;
    }

    isLoading.value = true;
    try {
      final vendor = currentVendor.value!;
      debugPrint('\n=== INITIALIZING VENDOR FILTERS ===');
      debugPrint('Vendor: ${vendor.name} (ID: ${vendor.id})');

      // Fetch opening balance for vendor
      openingBalance = await customerRepo.getOpeningBalanceForCustomer(
        vendor.name,
      );
      debugPrint('📊 Opening Balance: $openingBalance');

      // Fetch item ledger credits (purchases from vendor) for this vendor
      itemLedgerCredits = await getItemLedgerCredits(vendor.name);
      debugPrint('✅ Item Ledger Credits: $itemLedgerCredits');

      await loadVendorLedgerEntries(vendor.name, vendor.id!);
      debugPrint(
        '📝 Vendor Ledger Entries loaded: ${vendorLedgerEntries.length}',
      );

      _applyFilters();
      debugPrint('🔍 Filtered Entries: ${filteredVendorEntries.length}');

      updateReactiveTotals();
      debugPrint('📈 Updated Reactive Totals');
      debugPrint('=== INITIALIZATION COMPLETE ===\n');
    } catch (e) {
      debugPrint('Error initializing vendor filters: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadVendorLedgerEntries(String vendorName, int vendorId) async {
    try {
      isLoading.value = true;
      // Clear old data first to ensure fresh load
      vendorLedgerEntries.clear();
      filteredVendorEntries.clear();

      final entries = await repo.getVendorLedgerEntries(vendorName, vendorId);
      vendorLedgerEntries.assignAll(entries);
      _applyFilters();
      updateReactiveTotals();
    } catch (e) {
      debugPrint('Error loading vendor ledger entries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    DateTime fromDateValue;
    DateTime toDateValue;

    try {
      fromDateValue = DateTime(
        fromDate.value.year,
        fromDate.value.month,
        fromDate.value.day,
      );
      toDateValue = DateTime(
        toDate.value.year,
        toDate.value.month,
        toDate.value.day,
        23,
        59,
        59,
        999,
      );
    } catch (e) {
      fromDateValue = DateTime.now().subtract(Duration(days: 30));
      toDateValue = DateTime.now();
    }

    final filtered = vendorLedgerEntries.where((entry) {
      final entryDate = entry.date;

      bool dateMatch =
          entryDate.isAfter(fromDateValue.subtract(Duration(days: 1))) &&
          entryDate.isBefore(toDateValue.add(Duration(days: 1)));

      bool typeMatch =
          selectedTransactionType.value == null ||
          entry.transactionType == selectedTransactionType.value;

      bool searchMatch =
          searchQuery.value.isEmpty ||
          entry.voucherNo.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          (entry.description?.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ??
              false);

      return dateMatch && typeMatch && searchMatch;
    }).toList();

    filtered.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    debugPrint(
      '🔄 _applyFilters: ${vendorLedgerEntries.length} entries → ${filtered.length} filtered',
    );
    filteredVendorEntries.assignAll(filtered);
  }

  void updateReactiveTotals() {
    final td = totalDebit;
    final tc = totalCredit;
    final nb = netBalance;

    debugPrint('\n--- Updating Reactive Totals ---');
    debugPrint('Total Debit: $td');
    debugPrint('Total Credit: $tc');
    debugPrint('Net Balance: $nb');
    debugPrint('---\n');

    rxTotalDebit.value = td;
    rxTotalCredit.value = tc;
    rxNetBalance.value = nb;
  }

  double get totalDebit {
    // Total debit = vendor ledger debits (payments made to vendor) ONLY
    // Item ledger debits are for inventory tracking, not vendor payments
    final vendorDebits = filteredVendorEntries.fold(
      0.0,
      (sum, entry) => sum + entry.debit,
    );
    debugPrint('💰 TOTAL DEBIT CALCULATION:');
    debugPrint('  - Vendor Ledger Debits (Payments): $vendorDebits');
    debugPrint('  - Item Ledger Debits: NOT INCLUDED (inventory only)');
    debugPrint('  - TOTAL: $vendorDebits');
    return vendorDebits;
  }

  double get totalCredit {
    // Total credit = vendor ledger credits + item ledger credits (purchases from vendor)
    final vendorCredits = filteredVendorEntries.fold(
      0.0,
      (sum, entry) => sum + entry.credit,
    );
    final total = vendorCredits + itemLedgerCredits;
    debugPrint('💳 TOTAL CREDIT CALCULATION:');
    debugPrint('  - Vendor Ledger Credits: $vendorCredits');
    debugPrint('  - Item Ledger Credits: $itemLedgerCredits');
    debugPrint('  - TOTAL: $total');
    return total;
  }

  double get netBalance {
    // Net balance = Opening balance + Total Credits (amount owed) - Total Debits (payments made)
    // This represents the remaining amount owed to the vendor after all payments
    final tc = totalCredit;
    final td = totalDebit;
    final balance = (openingBalance + tc - td);
    debugPrint('⚖️  NET BALANCE CALCULATION:');
    debugPrint('  - Opening Balance: $openingBalance');
    debugPrint('  - Total Credit: $tc');
    debugPrint('  - Total Debit: $td');
    debugPrint('  - Net: $openingBalance + $tc - $td = $balance');
    return balance < 0 ? 0 : balance;
  }

  Future<void> selectDate(BuildContext context, bool isFromDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate ? fromDate.value : toDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      if (isFromDate) {
        fromDate.value = picked;
        fromDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      } else {
        toDate.value = picked;
        toDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      }
      _applyFilters();
      updateReactiveTotals();
    }
  }

  // Overload for simplified calling from UI
  void loadVendorLedgerEntriesNoParams() async {
    final vendor = currentVendor.value;
    if (vendor != null) {
      await loadVendorLedgerEntries(vendor.name, vendor.id!);
    }
  }

  Future<void> deleteVendorLedgerEntry(int id) async {
    try {
      await repo.deleteVendorLedgerEntry(id);
      vendorLedgerEntries.removeWhere((entry) => entry.id == id);
      _applyFilters();
      updateReactiveTotals();
    } catch (e) {
      debugPrint('Error deleting vendor ledger entry: $e');
    }
  }

  // Get item ledger credits for this vendor (purchases from vendor)
  Future<double> getItemLedgerCredits(String vendorName) async {
    try {
      final db = await _dbHelper.database;
      debugPrint('🔍 Fetching item ledger CREDITS for vendor: $vendorName');

      // Get all ledger tables for this vendor
      final tableResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'item_ledger_entries_%'",
      );

      debugPrint('📊 Found ${tableResult.length} item ledger tables');
      if (tableResult.isEmpty) {
        debugPrint('⚠️  No item ledger tables found for any vendor');
        return 0.0;
      }

      double totalCredit = 0.0;

      // Check each item ledger table for entries from this vendor
      for (var tableRow in tableResult) {
        final tableName = tableRow['name'] as String;
        debugPrint('🔎 Checking table: $tableName');

        final result = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(credit), 0) AS totalCredit
          FROM $tableName
          WHERE UPPER(vendorName) = UPPER(?) AND transactionType = 'Credit'
        ''',
          [vendorName],
        );

        if (result.isNotEmpty) {
          final tableCredit =
              (result.first['totalCredit'] as num?)?.toDouble() ?? 0.0;
          debugPrint('  ✅ Found $tableCredit credits in $tableName');
          totalCredit += tableCredit;
        }
      }

      debugPrint('✅ Total Item Ledger Credits found: $totalCredit');
      return totalCredit;
    } catch (e) {
      debugPrint('❌ Error getting item ledger credits: $e');
      return 0.0;
    }
  }

  // Get item ledger debits for this vendor (outgoing items)
  Future<double> getItemLedgerDebits(String vendorName) async {
    try {
      final db = await _dbHelper.database;
      debugPrint('🔍 Fetching item ledger DEBITS for vendor: $vendorName');

      // Get all ledger tables for this vendor
      final tableResult = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'item_ledger_entries_%'",
      );

      debugPrint('📊 Found ${tableResult.length} item ledger tables');
      if (tableResult.isEmpty) {
        debugPrint('⚠️  No item ledger tables found for any vendor');
        return 0.0;
      }

      double totalDebit = 0.0;

      // Check each item ledger table for entries from this vendor
      for (var tableRow in tableResult) {
        final tableName = tableRow['name'] as String;
        debugPrint('🔎 Checking table: $tableName');

        final result = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(debit), 0) AS totalDebit
          FROM $tableName
          WHERE UPPER(vendorName) = UPPER(?) AND transactionType = 'Debit'
        ''',
          [vendorName],
        );

        if (result.isNotEmpty) {
          final tableDebit =
              (result.first['totalDebit'] as num?)?.toDouble() ?? 0.0;
          debugPrint('  ❌ Found $tableDebit debits in $tableName');
          totalDebit += tableDebit;
        }
      }

      debugPrint('❌ Total Item Ledger Debits found: $totalDebit');
      return totalDebit;
    } catch (e) {
      debugPrint('❌ Error getting item ledger debits: $e');
      return 0.0;
    }
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
