import 'package:get/get.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';

class CansController extends GetxController {
  final CansRepository repository;

  CansController(this.repository);

  final cans = <Cans>[].obs;
  final filteredCans = <Cans>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;
  final cansEntries = <CansEntry>[].obs;
  final filteredCansEntries = <CansEntry>[].obs;
  final cansSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCans();
    ever(searchQuery, (_) => _applyFilters());
  }

  Future<void> fetchCans() async {
    try {
      isLoading.value = true;
      final result = await repository.getAllCans();
      cans.assignAll(result);
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch cans tables: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    final query = searchQuery.value.toLowerCase();

    if (cans.isNotEmpty) {
      // Filter cans tables by account name
      filteredCans.assignAll(
        cans
            .where(
              (can) =>
                  can.accountName.toLowerCase().contains(query) ||
                  (can.accountId?.toString().contains(query) ?? false),
            )
            .toList(),
      );
    }
  }

  Future<void> addCansTable(Cans cans) async {
    try {
      final id = await repository.addCans(cans);
      final newCans = cans.copyWith(id: id);
      this.cans.add(newCans);
      _applyFilters();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCansTable(Cans cans) async {
    try {
      await repository.updateCans(cans);
      final index = this.cans.indexWhere((c) => c.id == cans.id);
      if (index >= 0) {
        this.cans[index] = cans;
      }
      _applyFilters();
      Get.snackbar('Success', 'Cans table updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update cans table: $e');
    }
  }

  Future<void> deleteCansTable(int id) async {
    try {
      await repository.deleteCans(id);
      cans.removeWhere((c) => c.id == id);
      _applyFilters();
      Get.snackbar('Success', 'Cans table deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete cans table: $e');
    }
  }

  /// Get the last cans record for a specific customer
  Future<Cans?> getLastCansForCustomer(int customerId) async {
    try {
      final result = await repository.getCansById(customerId);
      return result;
    } catch (e) {
      print('Error fetching cans for customer: $e');
      return null;
    }
  }

  /// Get cans data for a specific customer by accountId
  Cans? getCansForCustomer(int customerId) {
    try {
      if (customerId <= 0) return null;
      return cans.firstWhereOrNull((c) => c.accountId == customerId);
    } catch (e) {
      return null;
    }
  }

  /// Get cans data for a specific customer by account name (fallback)
  Cans? getCansForCustomerByName(String accountName) {
    try {
      if (accountName.isEmpty) return null;
      return cans.firstWhereOrNull(
        (c) => c.accountName.toLowerCase() == accountName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  bool cansExistsForAccount(String accountName) {
    return cans.any(
      (c) => c.accountName.toLowerCase() == accountName.toLowerCase(),
    );
  }

  /// Fetch cans entries for a specific cans table
  Future<void> fetchCansEntries(int cansId) async {
    try {
      isLoading.value = true;
      final result = await repository.getCansEntriesByCansId(cansId);
      cansEntries.assignAll(result);
      applyEntriesFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch cans entries: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyEntriesFilters() {
    final query = cansSearchQuery.value.toLowerCase();
    if (cansEntries.isNotEmpty) {
      filteredCansEntries.assignAll(
        cansEntries
            .where(
              (entry) =>
                  entry.voucherNo.toLowerCase().contains(query) ||
                  entry.date.toString().contains(query),
            )
            .toList(),
      );
    } else {
      filteredCansEntries.clear();
    }
  }

  /// Add a new cans entry
  Future<void> addCansEntry(CansEntry entry) async {
    try {
      final id = await repository.addCansEntry(entry);
      final newEntry = entry.copyWith(id: id);
      cansEntries.add(newEntry);
      applyEntriesFilters();
      Get.snackbar('Success', 'Cans entry added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add cans entry: $e');
      rethrow;
    }
  }

  /// Update an existing cans entry
  Future<void> updateCansEntry(CansEntry entry) async {
    try {
      await repository.updateCansEntry(entry);
      final index = cansEntries.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        cansEntries[index] = entry;
      }
      applyEntriesFilters();
      Get.snackbar('Success', 'Cans entry updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update cans entry: $e');
      rethrow;
    }
  }

  /// Delete a cans entry
  Future<void> deleteCansEntry(int id) async {
    try {
      await repository.deleteCansEntry(id);
      cansEntries.removeWhere((e) => e.id == id);
      applyEntriesFilters();
      Get.snackbar('Success', 'Cans entry deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete cans entry: $e');
      rethrow;
    }
  }

  /// Get the balance summary for a specific account
  Future<Map<String, dynamic>> getCansBalanceSummary(int accountId) async {
    try {
      final summary = await repository.getCansBalanceSummary(accountId);
      return summary;
    } catch (e) {
      print('Error getting cans balance summary: $e');
      return {
        'accountId': accountId,
        'opening_balance': 0.0,
        'total_current': 0.0,
        'total_received': 0.0,
        'final_balance': 0.0,
        'has_data': false,
        'error': e.toString(),
      };
    }
  }
}
