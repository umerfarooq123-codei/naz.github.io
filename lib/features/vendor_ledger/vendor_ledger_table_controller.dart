import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_repository.dart';

class VendorLedgerTableController extends GetxController {
  final repo = VendorLedgerRepository();
  final customerRepo = CustomerRepository();

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

      // Fetch opening balance for vendor
      openingBalance = await customerRepo.getOpeningBalanceForCustomer(
        vendor.name,
      );

      await loadVendorLedgerEntries(vendor.name, vendor.id!);
      _applyFilters();
      updateReactiveTotals();
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
    filteredVendorEntries.assignAll(filtered);
  }

  void updateReactiveTotals() {
    rxTotalDebit.value = totalDebit;
    rxTotalCredit.value = totalCredit;
    rxNetBalance.value = netBalance;
  }

  double get totalDebit {
    return filteredVendorEntries.fold(0.0, (sum, entry) => sum + entry.debit);
  }

  double get totalCredit {
    return filteredVendorEntries.fold(0.0, (sum, entry) => sum + entry.credit);
  }

  double get netBalance {
    return (totalCredit + openingBalance - totalDebit).clamp(
      0,
      double.infinity,
    );
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

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    searchController.dispose();
    super.onClose();
  }
}
