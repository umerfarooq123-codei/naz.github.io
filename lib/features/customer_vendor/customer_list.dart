import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/ledger/ledger_repository.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/customer.dart';
import 'customer_add_edit.dart';

class CustomerList extends StatelessWidget {
  const CustomerList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerController>();
    int gridAxisCount = 0;
    switch (MediaQuery.of(context).size.width ~/ 200) {
      case 1:
        gridAxisCount = 1;
        break;
      case 2:
        gridAxisCount = 2;
        break;
      case 3:
        gridAxisCount = 3;
        break;
      case 4:
        gridAxisCount = 4;
        break;
      case 5:
        gridAxisCount = 5;
        break;
      default:
        gridAxisCount = 5;
    }
    void showCustomerDetailsDialog(Customer customer) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Customer Details - ${customer.customerNo}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${customer.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Customer No: ${customer.customerNo}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Address: ${customer.address}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Mobile No: ${customer.mobileNo}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'NTN No: ${customer.ntnNo}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((callBack) {
      controller.loadRecentSearches();
      controller.fetchCustomers();
    });
    controller.clearSearch();
    return Obx(
      () => Stack(
        children: [
          BaseLayout(
            showBackButton: false,
            appBarTitle: 'Customers & Vendors',
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrink-wrap the outer Column
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar (fixed at the top)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) {
                        return controller.recentSearches;
                      }
                      return controller.recentSearches.where(
                        (search) => search.toLowerCase().contains(q),
                      );
                    },
                    onSelected: (String value) async {
                      controller.searchQuery.value = value;
                      await controller.saveRecentSearch(value);
                    },
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: Theme.of(context).textTheme.bodySmall!,
                            decoration: InputDecoration(
                              hintText:
                                  'Search by name, number, address, ntn...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintStyle: Theme.of(context).textTheme.bodySmall!,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodySmall!,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              suffixIcon:
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: textEditingController,
                                    builder: (context, value, _) =>
                                        value.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                            onPressed: () {
                                              textEditingController.clear();
                                              controller.clearSearch();
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                            ),
                            onChanged: (value) {
                              controller.searchQuery.value = value;
                            },
                            onSubmitted: (value) async {
                              onFieldSubmitted();
                              if (value.trim().isNotEmpty) {
                                await controller.saveRecentSearch(value.trim());
                              }
                            },
                          );
                        },
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // Shrink-wrap the inner Column
                      children: [
                        controller.filteredCustomers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    controller.searchQuery.value.isEmpty
                                        ? 'No Customers found. Add some Customers to get started.'
                                        : 'No Customers match your search.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(16),
                                shrinkWrap:
                                    true, // Allow GridView to size itself
                                physics:
                                    const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gridAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 2.5 / 1.5,
                                    ),
                                itemCount: controller.filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer =
                                      controller.filteredCustomers[index];
                                  final summary = controller
                                      .getCustomerDebitCredit(customer.name);

                                  return Card(
                                    color: Colors.white30,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () =>
                                          showCustomerDetailsDialog(customer),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize
                                              .min, // Shrink-wrap inner Column
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize: MainAxisSize
                                                        .min, // Shrink-wrap
                                                    children: [
                                                      Text(
                                                        customer.name
                                                            .toUpperCase(),
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.titleMedium,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                      Text(
                                                        'No: ${customer.customerNo}',
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 6.0,
                                                          horizontal: 6.0,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize
                                                          .min, // Shrink-wrap
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'Credit: ${summary.credit}',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                        Text(
                                                          'Debit: ${summary.debit}',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall!
                                                              .copyWith(
                                                                color: Colors
                                                                    .green,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        size: 16,
                                                      ),
                                                      onPressed: () async {
                                                        await controller
                                                            .loadCustomer(
                                                              customer:
                                                                  customer,
                                                            );
                                                        if (context.mounted) {
                                                          NavigationHelper.push(
                                                            context,
                                                            CustomerAddEdit(
                                                              customer:
                                                                  customer,
                                                            ),
                                                          );
                                                        }
                                                        await controller
                                                            .fetchCustomers();
                                                      },
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        size: 16,
                                                      ),
                                                      onPressed: () =>
                                                          controller
                                                              .deleteCustomer(
                                                                customer.id!,
                                                              ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              onPressed: () async {
                await controller.loadCustomer();
                if (context.mounted) {
                  NavigationHelper.push(context, const CustomerAddEdit());
                }
                await controller.fetchCustomers();
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerController extends GetxController {
  final CustomerRepository repo;
  final LedgerRepository ledgerRepo = LedgerRepository();
  final customers = <Customer>[].obs;
  final filteredCustomers = <Customer>[].obs;
  final isDarkMode = true.obs;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final customerNoController = TextEditingController();
  final mobileNoController = TextEditingController();
  final ntnNoController = TextEditingController();
  final searchController = TextEditingController();
  RxString type = "Customer".obs;

  final customerLedgerEntries = <String, List<LedgerEntry>>{}.obs;
  final isLoadingLedgers = false.obs;

  // Search functionality
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;

  CustomerController(this.repo);

  @override
  void onInit() {
    super.onInit();
    loadTheme();
    fetchCustomers();
    loadRecentSearches();

    // Listen to search query changes
    ever(searchQuery, (query) => filterCustomers(query));
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
  }

  Future<void> fetchCustomers() async {
    final data = await repo.getAllCustomers();
    customers.assignAll(data);
    filterCustomers(searchQuery.value);
    await fetchLedgerEntriesForAllCustomers(); // Fetch ledger entries after getting customers
  }

  void filterCustomers(String query) {
    if (query.isEmpty) {
      filteredCustomers.assignAll(customers);
    } else {
      final q = query.toLowerCase();
      filteredCustomers.assignAll(
        customers.where(
          (customer) =>
              customer.name.toLowerCase().contains(q) ||
              customer.address.toLowerCase().contains(q) ||
              customer.customerNo.toLowerCase().contains(q) ||
              customer.mobileNo.toLowerCase().contains(q) ||
              (customer.ntnNo?.toLowerCase().contains(q) ?? false),
        ),
      );
    }
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.assignAll(
      prefs.getStringList('customerRecentSearches') ?? [],
    );
  }

  Future<void> saveRecentSearch(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;

    // Remove if already exists to avoid duplicates
    recentSearches.remove(searchTerm.trim());

    // Add to beginning of list
    recentSearches.insert(0, searchTerm.trim());

    // Keep only the last 5 searches
    if (recentSearches.length > 5) {
      recentSearches.removeLast();
    }

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'customerRecentSearches',
      recentSearches.toList(),
    );
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  // Helper method to get ledger entries for a specific customer
  List<LedgerEntry> getLedgerEntriesForCustomer(String customerName) {
    return customerLedgerEntries[customerName] ?? [];
  }

  // Helper method to calculate total debt/credit for a customer
  CustomerBalance calculateCustomerDebitCredit(String customerName) {
    final entries = getLedgerEntriesForCustomer(customerName);
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    for (final entry in entries) {
      totalDebit += entry.debit;
      totalCredit += entry.credit;
    }

    return CustomerBalance(
      totalDebit: totalDebit,
      totalCredit: totalCredit,
      netBalance: totalDebit - totalCredit,
      transactionCount: entries.length,
    );
  }

  DebitCreditSummary getCustomerDebitCredit(String customerName) {
    final entries = getLedgerEntriesForCustomer(customerName);
    double debit = 0.0;
    double credit = 0.0;

    for (final entry in entries) {
      debit += entry.debit;
      credit += entry.credit;
    }

    // Add comma separators:
    final formatter = NumberFormat('#,##0.00'); // e.g. 12,345.67
    final debitFormatted = formatter.format(debit);
    final creditFormatted = formatter.format(credit);

    return DebitCreditSummary(debit: debitFormatted, credit: creditFormatted);
  }

  // Update fetchLedgerEntriesForAllCustomers to use customer name
  Future<void> fetchLedgerEntriesForAllCustomers() async {
    isLoadingLedgers.value = true;
    try {
      final Map<String, List<LedgerEntry>> entriesMap = {};

      for (final customer in customers) {
        // Use customer.name instead of customer.customerNo
        final entries = await ledgerRepo.getLedgerEntriesByCustomer(
          customer.name,
        );
        entriesMap[customer.name] = entries;
      }

      customerLedgerEntries.value = entriesMap;
    } finally {
      isLoadingLedgers.value = false;
    }
  }

  Future<void> deleteCustomer(int id) async {
    await repo.deleteCustomer(id);
    await fetchCustomers();
  }

  Future<void> loadCustomer({Customer? customer}) async {
    if (customer == null) {
      clearForm();
      customerNoController.text = await repo.getLastCustNVendNo(type.value);
    } else {
      nameController.text = customer.name;
      addressController.text = customer.address;
      customerNoController.text = customer.customerNo;
      mobileNoController.text = customer.mobileNo;
      ntnNoController.text = customer.ntnNo ?? '';
    }
  }

  Future<void> saveCustomer(BuildContext context, {Customer? customer}) async {
    if (formKey.currentState!.validate()) {
      final newCustomer = Customer(
        id: customer?.id,
        name: nameController.text,
        address: addressController.text,
        customerNo: customerNoController.text,
        mobileNo: mobileNoController.text,
        ntnNo: ntnNoController.text,
        type: type.value,
      );

      if (customer == null) {
        await repo.insertCustomer(newCustomer);
      } else {
        await repo.updateCustomer(newCustomer);
      }
      clearForm();
      await fetchCustomers();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void clearForm() {
    nameController.clear();
    addressController.clear();
    mobileNoController.clear();
    ntnNoController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    customerNoController.dispose();
    mobileNoController.dispose();
    ntnNoController.dispose();
    searchController.dispose();
    super.onClose();
  }
}

class CustomerBalance {
  final double totalDebit;
  final double totalCredit;
  final double netBalance;
  final int transactionCount;

  CustomerBalance({
    required this.totalDebit,
    required this.totalCredit,
    required this.netBalance,
    required this.transactionCount,
  });
}

class DebitCreditSummary {
  final String debit;
  final String credit;

  DebitCreditSummary({required this.debit, required this.credit});
}
