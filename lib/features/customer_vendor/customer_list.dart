import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/features/customer_vendor/customer_ledger_table.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/ledger/ledger_repository.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_table_controller.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_table_page.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/customer.dart';
import 'customer_add_edit.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  @override
  Widget build(BuildContext context) {
    final vendController = Get.put(
      VendorLedgerTableController(),
      permanent: true,
    );
    final controller = Get.find<CustomerController>();
    controller.clearSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadRecentSearches();
      controller.fetchCustomers();
    });

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

    return Obx(
      () => Stack(
        children: [
          BaseLayout(
            showBackButton: false,
            onBackButtonPressed: null,
            appBarTitle: 'Customers & Vendors',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar (fixed at the top)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) {
                        return Get.find<CustomerController>().recentSearches;
                      }
                      return Get.find<CustomerController>().recentSearches
                          .where((search) => search.toLowerCase().contains(q));
                    },
                    onSelected: (String value) async {
                      Get.find<CustomerController>().searchQuery.value = value;
                      await Get.find<CustomerController>().saveRecentSearch(
                        value,
                      );
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
                                              Get.find<CustomerController>()
                                                  .clearSearch();
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                            ),
                            onChanged: (value) {
                              Get.find<CustomerController>().searchQuery.value =
                                  value;
                            },
                            onSubmitted: (value) async {
                              onFieldSubmitted();
                              if (value.trim().isNotEmpty) {
                                await Get.find<CustomerController>()
                                    .saveRecentSearch(value.trim());
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
                      mainAxisSize: MainAxisSize.min,
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
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gridAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 2.2 / 1.20,
                                    ),
                                itemCount: controller.filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer =
                                      controller.filteredCustomers[index];

                                  // FIXED: Don't modify state during build
                                  // Store the vendor reference without triggering state changes
                                  final isVendor =
                                      customer.type.toLowerCase() == 'vendor';
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (isVendor) {
                                      vendController.currentVendor.value =
                                          customer;
                                      vendController.updateReactiveTotals();
                                    }
                                  });
                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                        width: 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        // Set vendor state here in the callback, not during build
                                        if (isVendor) {
                                          vendController.currentVendor.value =
                                              customer;
                                          NavigationHelper.pushReplacement(
                                            context,
                                            VendorLedgerTablePage(
                                              vendor: customer,
                                            ),
                                          );
                                        } else {
                                          NavigationHelper.push(
                                            context,
                                            CustomerLedgerTablePage(
                                              customer: customer,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    size: 28,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          customer.name
                                                              .toUpperCase(),
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium,
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
                                              const SizedBox(height: 8),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .surfaceContainerLowest,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                      ),
                                                      child: FutureBuilder<double>(
                                                        future: CustomerRepository()
                                                            .getOpeningBalanceForCustomer(
                                                              customer.name,
                                                            ),
                                                        builder: (context, snapshott) {
                                                          return FutureBuilder<
                                                            DebitCreditSummary
                                                          >(
                                                            future: controller
                                                                .getCustomerDebitCredit(
                                                                  customer.name,
                                                                  customer.type,
                                                                  customer.id!,
                                                                ),
                                                            builder: (context, snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return const SizedBox(
                                                                  height: 20,
                                                                  width: 20,
                                                                );
                                                              }
                                                              if (snapshot
                                                                  .hasError) {
                                                                return Text(
                                                                  'Error: ${snapshot.error}',
                                                                );
                                                              }
                                                              if (!snapshot
                                                                  .hasData) {
                                                                return const Text(
                                                                  'No data',
                                                                );
                                                              }

                                                              final summary =
                                                                  snapshot
                                                                      .data!;

                                                              // Fetch actual ledger debit for correct net balance
                                                              return FutureBuilder<
                                                                DebitCreditSummary
                                                              >(
                                                                future: CustomerLedgerRepository()
                                                                    .fetchTotalDebitAndCredit(
                                                                      customer
                                                                          .name,
                                                                      customer
                                                                          .id!,
                                                                    ),
                                                                builder:
                                                                    (
                                                                      context,
                                                                      ledgerSnapshot,
                                                                    ) {
                                                                      final ledgerDebit =
                                                                          ledgerSnapshot
                                                                              .hasData
                                                                          ? double.tryParse(
                                                                                  ledgerSnapshot.data!.debit,
                                                                                ) ??
                                                                                0.0
                                                                          : 0.0;

                                                                      final openingBalance =
                                                                          snapshott
                                                                              .data ??
                                                                          0.0;

                                                                      return Column(
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          // Opening Balance
                                                                          if (snapshott.connectionState ==
                                                                              ConnectionState.waiting)
                                                                            const SizedBox(
                                                                              height: 20,
                                                                              width: 20,
                                                                            )
                                                                          else if (openingBalance !=
                                                                                  0 &&
                                                                              openingBalance !=
                                                                                  0.0)
                                                                            Text(
                                                                              isVendor
                                                                                  ? "Opening Bal: ${NumberFormat('#,##0').format(vendController.openingBalance)}"
                                                                                  : "Opening Bal: ${NumberFormat('#,##0').format(openingBalance)}",
                                                                              style:
                                                                                  Theme.of(
                                                                                    context,
                                                                                  ).textTheme.bodySmall!.copyWith(
                                                                                    color: Theme.of(
                                                                                      context,
                                                                                    ).colorScheme.error,
                                                                                    fontWeight: FontWeight.bold,
                                                                                  ),
                                                                              overflow: TextOverflow.ellipsis,
                                                                              maxLines: 1,
                                                                            )
                                                                          else
                                                                            const SizedBox.shrink(),

                                                                          // Net Balance (Correct calculation)
                                                                          Text(
                                                                            isVendor
                                                                                ? 'Net Balance: ${NumberFormat('#,##0').format(vendController.rxNetBalance.value)}'
                                                                                : 'Net Balance: ${NumberFormat('#,##0').format(((double.parse(summary.credit) + openingBalance) - ledgerDebit).clamp(0, double.infinity))}',
                                                                            style:
                                                                                Theme.of(
                                                                                  context,
                                                                                ).textTheme.bodySmall!.copyWith(
                                                                                  color: Theme.of(
                                                                                    context,
                                                                                  ).colorScheme.error,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                          ),

                                                                          // Credit
                                                                          Text(
                                                                            isVendor
                                                                                ? 'Credit: ${NumberFormat('#,##0').format(vendController.rxTotalCredit.value)}'
                                                                                : 'Credit: ${NumberFormat('#,##0').format(double.parse(summary.credit))}',
                                                                            style:
                                                                                Theme.of(
                                                                                  context,
                                                                                ).textTheme.bodySmall!.copyWith(
                                                                                  color: Theme.of(
                                                                                    context,
                                                                                  ).colorScheme.error,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                          ),

                                                                          // Debit (from transactions)
                                                                          Text(
                                                                            isVendor
                                                                                ? 'Debit: ${NumberFormat('#,##0').format(vendController.rxTotalDebit.value)}'
                                                                                : 'Debit: ${NumberFormat('#,##0').format(double.parse(summary.debit))}',
                                                                            style:
                                                                                Theme.of(
                                                                                  context,
                                                                                ).textTheme.bodySmall!.copyWith(
                                                                                  color: const Color(
                                                                                    0xFF2E7D32,
                                                                                  ),
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                1,
                                                                          ),
                                                                        ],
                                                                      );
                                                                    },
                                                              );
                                                            },
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(width: 4),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      deleteButton(
                                                        context: context,
                                                        onPressed: () {
                                                          confirmDeleteDialog(
                                                            onConfirm: () {
                                                              controller
                                                                  .deleteCustomer(
                                                                    customer
                                                                        .id!,
                                                                  );
                                                            },
                                                            context: context,
                                                          );
                                                        },
                                                      ),
                                                      editButton(
                                                        context: context,
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
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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
                final controller = Get.find<CustomerController>();
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
  final TextEditingController openingBalanceController = TextEditingController(
    text: '0',
  );
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
    // Removed fetchCustomers() and loadRecentSearches() from onInit to avoid initial load;
    // these are now handled per-widget visit in initState for fresh loads each time

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

  /// ✅ FIXED: Get customer/vendor debit/credit with proper vendor matching
  /// ✅ FIXED: Get customer/vendor debit/credit with proper calculations
  Future<DebitCreditSummary> getCustomerDebitCredit(
    String customerName,
    String type,
    int customerId,
  ) async {
    double debit = 0.0;
    double credit = 0.0;

    try {
      if (type != 'Vendor') {
        // For customers - use regular ledger entries (stored locally)
        final entries = getLedgerEntriesForCustomer(customerName);

        for (final entry in entries) {
          debit += entry.debit;
          credit += entry.credit;
        }

        // ALSO fetch from customer ledger table
        final ledgerTotals = await CustomerLedgerRepository()
            .fetchTotalDebitAndCredit(customerName, customerId);

        final customerLedgerDebit = double.tryParse(ledgerTotals.debit) ?? 0.0;
        final customerLedgerCredit =
            double.tryParse(ledgerTotals.credit) ?? 0.0;

        debit += customerLedgerDebit;
        credit += customerLedgerCredit;
      } else {
        // For vendors - fetch vendor ledger entries
        final entries = await LedgerRepository().getLedgerEntriesByVendor(
          customerName,
        );

        for (final entry in entries) {
          debit += entry.debit;
          credit += entry.credit;
        }

        // ALSO fetch customer ledger table totals
        final debitAndCredit = await CustomerLedgerRepository()
            .fetchTotalDebitAndCredit(customerName, customerId);

        final customerLedgerDebit =
            double.tryParse(debitAndCredit.debit) ?? 0.0;
        final customerLedgerCredit =
            double.tryParse(debitAndCredit.credit) ?? 0.0;

        // ✅ FIX: For vendors, add both debit and credit properly
        debit += customerLedgerDebit;
        credit += customerLedgerCredit; // ✅ FIXED: Was subtracting debit!
      }
      return DebitCreditSummary(
        debit: debit.toString(),
        credit: credit.toString(),
      );
    } catch (e) {
      return DebitCreditSummary(debit: 0.0.toString(), credit: 0.0.toString());
    }
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
      final double openingBalance =
          double.tryParse(openingBalanceController.text.trim()) ?? 0.0;

      final newCustomer = Customer(
        id: customer?.id,
        name: nameController.text,
        address: addressController.text,
        customerNo: customerNoController.text,
        mobileNo: mobileNoController.text,
        ntnNo: ntnNoController.text,
        type: type.value,
        openingBalance: openingBalance,
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
    openingBalanceController.clear();
  }

  @override
  void onClose() {
    nameController.dispose();
    addressController.dispose();
    customerNoController.dispose();
    mobileNoController.dispose();
    ntnNoController.dispose();
    searchController.dispose();
    openingBalanceController.dispose();
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
