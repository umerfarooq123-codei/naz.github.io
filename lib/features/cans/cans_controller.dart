import 'package:get/get.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';

class CansController extends GetxController {
  final CansRepository _repository;

  CansController(this._repository);

  final cans = <Cans>[].obs;
  final cansEntries = <CansEntry>[].obs;
  final filteredCans = <Cans>[].obs;
  final filteredCansEntries = <CansEntry>[].obs;
  final searchQuery = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCans();
    ever(searchQuery, (_) => _applyFilters());
  }

  Future<void> fetchCans() async {
    try {
      isLoading.value = true;
      final result = await _repository.getAllCans();
      cans.assignAll(result);
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch cans tables: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCansEntries(int cansId) async {
    try {
      isLoading.value = true;
      final result = await _repository.getCansEntriesByCansId(cansId);
      cansEntries.assignAll(result);
      _applyFilters();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch entries: $e');
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

    if (cansEntries.isNotEmpty) {
      // Filter cans entries by voucher no or date
      filteredCansEntries.assignAll(
        cansEntries
            .where((entry) => entry.voucherNo.toLowerCase().contains(query))
            .toList(),
      );
    }
  }

  Future<void> addCansTable(Cans cans) async {
    try {
      final id = await _repository.addCans(cans);
      final newCans = cans.copyWith(id: id);
      this.cans.add(newCans);
      _applyFilters();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCansTable(Cans cans) async {
    try {
      await _repository.updateCans(cans);
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
      await _repository.deleteCans(id);
      cans.removeWhere((c) => c.id == id);
      _applyFilters();
      Get.snackbar('Success', 'Cans table deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete cans table: $e');
    }
  }

  Future<void> addCansEntry(CansEntry entry) async {
    try {
      final id = await _repository.addCansEntry(entry);
      final newEntry = entry.copyWith(id: id);
      cansEntries.add(newEntry);
      _applyFilters();
      Get.snackbar('Success', 'Transaction added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add transaction: $e');
    }
  }

  Future<void> updateCansEntry(CansEntry entry) async {
    try {
      await _repository.updateCansEntry(entry);
      final index = cansEntries.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        cansEntries[index] = entry;
      }
      _applyFilters();
      Get.snackbar('Success', 'Transaction updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update transaction: $e');
    }
  }

  Future<void> deleteCansEntry(int id) async {
    try {
      await _repository.deleteCansEntry(id);
      cansEntries.removeWhere((e) => e.id == id);
      _applyFilters();
      Get.snackbar('Success', 'Transaction deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete transaction: $e');
    }
  }

  bool cansExistsForAccount(String accountName) {
    return cans.any(
      (c) => c.accountName.toLowerCase() == accountName.toLowerCase(),
    );
  }
}
