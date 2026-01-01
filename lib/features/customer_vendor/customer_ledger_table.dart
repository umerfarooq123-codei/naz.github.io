import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../core/models/customer.dart';

class CustomerLedgerTablePage extends StatelessWidget {
  final Customer customer;

  const CustomerLedgerTablePage({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    // Remove old controller instance and create a fresh one
    Get.delete<CustomerLedgerTableController>();
    final controller = Get.put(CustomerLedgerTableController());

    // Set the customer in the controller
    controller.currentCustomer.value = customer;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntries();
    });

    return BaseLayout(
      appBarTitle: "Ledger: ${customer.name}",
      showBackButton: true,
      onBackButtonPressed: () {
        NavigationHelper.pushReplacement(context, CustomerList());
      },
      child: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: (value) =>
                            controller.searchQuery.value = value,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          labelText: "Search by Voucher No or Date",
                          labelStyle: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: customer.name,
                      readOnly: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: "Customer Name",
                        labelStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.selectedTransactionType.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      items: const [
                        DropdownMenuItem(value: null, child: Text("All Types")),
                        DropdownMenuItem(value: "Debit", child: Text("Debit")),
                        DropdownMenuItem(
                          value: "Credit",
                          child: Text("Credit"),
                        ),
                      ],
                      onChanged: (value) {
                        controller.selectedTransactionType.value = value;
                      },
                      decoration: InputDecoration(
                        labelText: "Transaction Type",
                        labelStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: controller.fromDateController,
                      readOnly: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: "From Date",
                        labelStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => controller.selectDate(context, true),
                        ),
                      ),
                      onTap: () => controller.selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: controller.toDateController,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "To Date",
                        labelStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () =>
                              controller.selectDate(context, false),
                        ),
                      ),
                      onTap: () => controller.selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: 'customer-ledger-fab',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomerLedgerEntryAddEdit(
                            customer: customer,
                            onEntrySaved: () => controller.loadLedgerEntries(),
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            controller.isLoading.value
                ? Expanded(
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: Obx(() {
                      return SfDataGrid(
                        source: CustomerLedgerDataSource(
                          controller.filteredLedgerEntries,
                          controller,
                          context,
                          customer,
                        ),
                        controller: controller.dataGridController,
                        columnWidthMode: ColumnWidthMode.fill,
                        gridLinesVisibility: GridLinesVisibility.both,
                        headerGridLinesVisibility: GridLinesVisibility.both,
                        onCellTap: (DataGridCellTapDetails details) {
                          if (details.rowColumnIndex.rowIndex > 0) {
                            final entry =
                                controller.filteredLedgerEntries[details
                                        .rowColumnIndex
                                        .rowIndex -
                                    1];
                            showCustomerLedgerEntryDialog(context, entry);
                          }
                        },
                        placeholder: Center(
                          child: Text(
                            "No data available",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        columns: [
                          GridColumn(
                            columnName: 'voucherNo',
                            label: headerText("Voucher No", context),
                          ),
                          GridColumn(
                            columnName: 'date',
                            label: headerText("Date", context),
                          ),
                          GridColumn(
                            columnName: 'description',
                            label: headerText("Description", context),
                          ),
                          GridColumn(
                            columnName: 'transactionType',
                            label: headerText("Type", context),
                          ),
                          GridColumn(
                            columnName: 'paymentMethod',
                            label: headerText("Payment", context),
                          ),
                          GridColumn(
                            columnName: 'amount',
                            label: headerText("Amount", context),
                          ),
                        ],
                      );
                    }),
                  ),
            Container(
              alignment: Alignment.centerRight,
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FutureBuilder<double>(
                  future: CustomerRepository().getOpeningBalanceForCustomer(
                    customer.name,
                  ),
                  builder: (context, snapshott) {
                    return FutureBuilder<DebitCreditSummary>(
                      future: controller.customerListController
                          .getCustomerDebitCredit(
                            customer.name,
                            customer.type,
                            customer.id!,
                          ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(height: 20, width: 20);
                        }

                        if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }

                        if (!snapshot.hasData) {
                          return const Text('No data');
                        }

                        final summary = snapshot.data!;

                        // Fetch customer ledger debit separately for net balance
                        return FutureBuilder<DebitCreditSummary>(
                          future: CustomerLedgerRepository()
                              .fetchTotalDebitAndCredit(
                                customer.name,
                                customer.id!,
                              ),
                          builder: (context, customerLedgerSnapshot) {
                            final customerLedgerDebit =
                                customerLedgerSnapshot.hasData
                                ? double.tryParse(
                                        customerLedgerSnapshot.data!.debit,
                                      ) ??
                                      0.0
                                : 0.0;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (snapshott.connectionState ==
                                    ConnectionState.waiting)
                                  const SizedBox(height: 20, width: 20)
                                else
                                  snapshott.data != 0 || snapshott.data != 0.0
                                      ? totalBox(
                                          "Opening Bal",
                                          snapshott.data!,
                                          context,
                                        )
                                      : SizedBox.shrink(),
                                const SizedBox(width: 16),
                                totalBox(
                                  "Credit",
                                  double.parse(summary.credit),
                                  context,
                                ),
                                const SizedBox(width: 16),
                                totalBox(
                                  "Debit",
                                  double.parse(summary.debit),
                                  context,
                                ),
                                const SizedBox(width: 16),
                                totalBox(
                                  "Net Balance",
                                  ((double.parse(summary.credit) +
                                              (snapshott.data ?? 0)) -
                                          customerLedgerDebit)
                                      .clamp(0, double.infinity),
                                  context,
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
          ],
        );
      }),
    );
  }

  Widget headerText(String text, context) => Container(
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

class CustomerLedgerDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  final BuildContext context;
  final CustomerLedgerTableController controller;
  final Customer customer;

  CustomerLedgerDataSource(
    List<CustomerLedgerEntry> entries,
    this.controller,
    this.context,
    this.customer,
  ) {
    _buildRows(entries);
  }

  void _buildRows(List<CustomerLedgerEntry> entries) {
    _rows = entries.map((entry) {
      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'entry', value: entry),
          DataGridCell(columnName: 'voucherNo', value: entry.voucherNo),
          DataGridCell(
            columnName: 'date',
            value: DateFormat('dd-MM-yyyy').format(entry.date),
          ),
          DataGridCell(columnName: 'description', value: entry.description),
          DataGridCell(
            columnName: 'transactionType',
            value: entry.transactionType,
          ),
          DataGridCell(
            columnName: 'paymentMethod',
            value: entry.paymentMethod ?? 'Cash',
          ),
          DataGridCell(
            columnName: 'amount',
            value: entry.debit == 0.0
                ? "${NumberFormat('#,##0', 'en_US').format(entry.credit)}(Credit)"
                : "${NumberFormat('#,##0', 'en_US').format(entry.debit)}(Debit)",
          ),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final allCells = row.getCells();
    final entryCell = allCells.firstWhere((cell) => cell.columnName == 'entry');
    final entry = entryCell.value as CustomerLedgerEntry;
    final dataCells = allCells
        .where((cell) => cell.columnName != 'entry')
        .toList();
    bool isHovered = false;

    return DataGridRowAdapter(
      cells: dataCells.asMap().entries.map((cellEntry) {
        final cell = cellEntry.value;
        final isBalanceCell = cell.columnName == 'amount';

        if (isBalanceCell) {
          return StatefulBuilder(
            builder: (context, setState) {
              return MouseRegion(
                onEnter: (_) => setState(() => isHovered = true),
                onExit: (_) => setState(() => isHovered = false),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          entry.debit == 0.0
                              ? NumberFormat(
                                  '#,##0',
                                  'en_US',
                                ).format(entry.credit)
                              : NumberFormat(
                                  '#,##0',
                                  'en_US',
                                ).format(entry.debit),
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Positioned(
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: "delete",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => confirmDeleteDialog(
                                    onConfirm: () {
                                      deleteEntry(entry, context);
                                    },
                                    context: context,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: "edit",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => editEntry(entry, context),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        }

        return Container(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              cell.value.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: cell.columnName == 'amount'
                    ? FontWeight.w500
                    : null,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void deleteEntry(CustomerLedgerEntry entry, BuildContext context) async {
    try {
      await controller.repo.deleteCustomerLedgerEntry(
        entry.id!,
        customer.name,
        customer.id!,
      );

      await controller.loadLedgerEntries();

      Get.snackbar(
        'Success',
        'Entry deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete entry: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  void editEntry(CustomerLedgerEntry entry, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerLedgerEntryAddEdit(
          customer: customer,
          entry: entry,
          onEntrySaved: () => controller.loadLedgerEntries(),
        ),
      ),
    );
  }
}

class CustomerLedgerTableController extends GetxController {
  final DataGridController dataGridController = DataGridController();
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final searchController = TextEditingController();
  final selectedTransactionType = RxnString();
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final fromDate = Rx<DateTime>(DateTime.now().subtract(Duration(days: 30)));
  final toDate = Rx<DateTime>(DateTime.now());
  final filteredLedgerEntries = <CustomerLedgerEntry>[].obs;
  final repo = CustomerLedgerRepository();
  final customerRepo = CustomerRepository();
  final customerListController = Get.find<CustomerController>();
  Rx<Customer?> currentCustomer = Rx<Customer?>(null);
  final openingBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFilters();

    // Watch for changes to customer and reinitialize
    ever(currentCustomer, (_) {
      _initializeFilters();
    });
  }

  void _initializeFilters() {
    if (currentCustomer.value != null) {
      debugPrint(
        '🔧 _initializeFilters: Initializing for customer: ${currentCustomer.value!.name}',
      );
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(Duration(days: 30));
      fromDate.value = DateTime(
        thirtyDaysAgo.year,
        thirtyDaysAgo.month,
        thirtyDaysAgo.day,
      );
      toDate.value = DateTime(now.year, now.month, now.day);
      fromDateController.text = DateFormat('dd-MM-yyyy').format(fromDate.value);
      toDateController.text = DateFormat('dd-MM-yyyy').format(toDate.value);

      everAll([
        searchQuery,
        fromDate,
        toDate,
        selectedTransactionType,
      ], (_) => applyFilters());

      loadOpeningBalance();
      applyFilters();
    } else {
      debugPrint('⚠️ _initializeFilters: currentCustomer is still null!');
    }
  }

  Future<void> loadOpeningBalance() async {
    if (currentCustomer.value != null) {
      openingBalance.value = await customerRepo.getOpeningBalanceForCustomer(
        currentCustomer.value!.name,
      );
    }
  }

  Future<void> applyFilters() async {
    if (currentCustomer.value == null) {
      debugPrint('⚠️ applyFilters: currentCustomer is null');
      return;
    }

    isLoading.value = true;
    try {
      final customer = currentCustomer.value!;
      debugPrint(
        '📊 applyFilters: Loading entries for customer: ${customer.name} (ID: ${customer.id})',
      );
      final entries = await repo.getCustomerLedgerEntries(
        customer.name,
        customer.id!,
      );
      debugPrint(
        '📊 applyFilters: Retrieved ${entries.length} entries from database',
      );
      debugPrint("entriesss${entries.length}");

      final fromDateValue = DateTime(
        fromDate.value.year,
        fromDate.value.month,
        fromDate.value.day,
      );
      final toDateValue = DateTime(
        toDate.value.year,
        toDate.value.month,
        toDate.value.day,
        23,
        59,
        59,
        999,
      );

      final filtered = entries.where((entry) {
        final entryDate = entry.date;
        final normalizedEntryDate = DateTime(
          entryDate.year,
          entryDate.month,
          entryDate.day,
        );

        bool dateMatch =
            !normalizedEntryDate.isBefore(fromDateValue) &&
            !normalizedEntryDate.isAfter(toDateValue);
        bool typeMatch =
            selectedTransactionType.value == null ||
            entry.transactionType == selectedTransactionType.value;
        bool searchMatch =
            searchQuery.value.isEmpty ||
            entry.voucherNo.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            DateFormat(
              'dd-MM-yyyy',
            ).format(entryDate).contains(searchQuery.value);

        return dateMatch && typeMatch && searchMatch;
      }).toList();

      filtered.sort((a, b) {
        int dateComparison = a.date.compareTo(b.date);
        if (dateComparison != 0) return dateComparison;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

      // Calculate running balance including opening balance
      double runningBalance = openingBalance.value;
      for (var entry in filtered) {
        if (entry.transactionType == 'Credit') {
          runningBalance += entry.credit;
        } else {
          runningBalance -= entry.debit;
        }
        entry.balance = runningBalance;
      }

      filteredLedgerEntries.assignAll(filtered);
      debugPrint(
        '📊 applyFilters: After filtering, ${filtered.length} entries match criteria',
      );

      if (filteredLedgerEntries.isNotEmpty) {
        final lastIndex = filteredLedgerEntries.length - 1;
        Future.delayed(Duration(milliseconds: 500), () {
          dataGridController.scrollToRow(lastIndex.toDouble());
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error applying filters: $e");
      }
      filteredLedgerEntries.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectDate(BuildContext context, bool isFromDate) async {
    final currentDate = isFromDate ? fromDate.value : toDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final normalizedDate = DateTime(picked.year, picked.month, picked.day);
      if (isFromDate) {
        fromDate.value = normalizedDate;
        fromDateController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(normalizedDate);
      } else {
        toDate.value = normalizedDate;
        toDateController.text = DateFormat('dd-MM-yyyy').format(normalizedDate);
      }
    }
  }

  Future<void> loadLedgerEntries() async {
    if (currentCustomer.value == null) return;

    // Ensure the toDate includes today so new entries are visible
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (toDate.value.isBefore(today)) {
      toDate.value = today;
      toDateController.text = DateFormat('dd-MM-yyyy').format(today);
    }

    await loadOpeningBalance();
    await applyFilters();
  }

  double get totalDebit {
    return filteredLedgerEntries.fold(0, (sum, entry) => sum + entry.debit);
  }

  double get totalCredit {
    return filteredLedgerEntries.fold(0, (sum, entry) => sum + entry.credit);
  }

  double get netBalance {
    if (filteredLedgerEntries.isEmpty) {
      return openingBalance.value;
    }
    return filteredLedgerEntries.last.balance;
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    searchController.dispose();
    super.onClose();
  }
}

class CustomerLedgerEntryAddEdit extends StatefulWidget {
  final Customer customer;
  final CustomerLedgerEntry? entry;
  final VoidCallback onEntrySaved;

  const CustomerLedgerEntryAddEdit({
    super.key,
    required this.customer,
    this.entry,
    required this.onEntrySaved,
  });

  @override
  State<CustomerLedgerEntryAddEdit> createState() =>
      _CustomerLedgerEntryAddEditState();
}

class _CustomerLedgerEntryAddEditState
    extends State<CustomerLedgerEntryAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _voucherNoController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _chequeAmountController = TextEditingController();
  final _chequeDateController = TextEditingController();
  final _bankNameController = TextEditingController();
  final customerLedgerTableController = Get.put(
    CustomerLedgerTableController(),
    permanent: true,
  );
  String _transactionType = 'Debit';
  String _paymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedChequeDate;
  final repo = CustomerLedgerRepository();
  final customerRepo = CustomerRepository();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  Future<void> _initializeFields() async {
    if (widget.entry != null) {
      _voucherNoController.text = widget.entry!.voucherNo;
      _dateController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(widget.entry!.date);
      _selectedDate = widget.entry!.date;
      _descriptionController.text = widget.entry!.description;
      _transactionType = widget.entry!.transactionType;
      _paymentMethod = widget.entry!.paymentMethod ?? 'Cash';

      final amount = widget.entry!.transactionType == 'Debit'
          ? widget.entry!.debit
          : widget.entry!.credit;
      _amountController.text = amount.toString();

      if (widget.entry!.paymentMethod == 'Cheque') {
        _chequeNoController.text = widget.entry!.chequeNo ?? '';
        _chequeAmountController.text =
            widget.entry!.chequeAmount?.toString() ?? '';
        if (widget.entry!.chequeDate != null) {
          _selectedChequeDate = widget.entry!.chequeDate;
          _chequeDateController.text = DateFormat(
            'dd-MM-yyyy',
          ).format(widget.entry!.chequeDate!);
        }
        _bankNameController.text = widget.entry!.bankName ?? '';
      }
    } else {
      final voucherNo = await repo.getLastVoucherNo(
        widget.customer.name,
        widget.customer.id!,
      );
      _voucherNoController.text = voucherNo;
      _dateController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _selectChequeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedChequeDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedChequeDate = picked;
        _chequeDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate cheque fields if payment method is Cheque
    if (_paymentMethod == 'Cheque') {
      if (_chequeNoController.text.trim().isEmpty ||
          _chequeAmountController.text.trim().isEmpty ||
          _selectedChequeDate == null ||
          _bankNameController.text.trim().isEmpty) {
        Get.snackbar(
          'Error',
          'Please fill all cheque details',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    try {
      final amount = double.parse(_amountController.text);

      final entry = CustomerLedgerEntry(
        id: widget.entry?.id,
        voucherNo: _voucherNoController.text,
        date: _selectedDate,
        customerName: widget.customer.name,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : "-",
        debit: _transactionType == 'Debit' ? amount : 0.0,
        credit: _transactionType == 'Credit' ? amount : 0.0,
        balance: 0.0,
        transactionType: _transactionType,
        paymentMethod: _paymentMethod,
        chequeNo: _paymentMethod == 'Cheque' ? _chequeNoController.text : null,
        chequeAmount: _paymentMethod == 'Cheque'
            ? double.tryParse(_chequeAmountController.text)
            : null,
        chequeDate: _paymentMethod == 'Cheque' ? _selectedChequeDate : null,
        bankName: _paymentMethod == 'Cheque' ? _bankNameController.text : null,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      );

      if (widget.entry == null) {
        await repo.insertCustomerLedgerEntry(
          entry,
          widget.customer.name,
          widget.customer.id!,
        );
      } else {
        await repo.updateCustomerLedgerEntry(
          entry,
          widget.customer.name,
          widget.customer.id!,
        );
      }

      widget.onEntrySaved();

      if (mounted) {
        Get.snackbar(
          'Success',
          'Entry ${widget.entry == null ? 'added' : 'updated'} successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
      customerLedgerTableController.customerListController.loadRecentSearches();
      customerLedgerTableController.customerListController.fetchCustomers();
    } catch (e) {
      debugPrint(e.toString());
      Get.snackbar(
        'Error',
        'Failed to save entry: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: suffixIcon,
        errorStyle: TextStyle(
          color: Colors.red[900],
          fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
        ),
      ),
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
    );
  }

  Widget buildTotalBox(
    String label,
    double value, {
    Color? bgColor,
    Color? textColor,
  }) {
    final effectiveBgColor =
        bgColor ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
    final effectiveTextColor =
        textColor ?? Theme.of(context).colorScheme.primary;
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: effectiveBgColor,
          border: Border.all(
            color: effectiveBgColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              NumberFormat('#,##0', 'en_US').format(value),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: effectiveTextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final controller = Get.find<CustomerController>();

    return BaseLayout(
      appBarTitle: widget.entry == null
          ? 'Add Ledger Entry'
          : 'Edit Ledger Entry',
      onBackButtonPressed: () {
        NavigationHelper.pushReplacement(
          context,
          CustomerLedgerTablePage(customer: widget.customer),
        );
      },
      showBackButton: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          Theme.of(context).cardTheme.color!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: isDesktop
                        ? Column(
                            children: [
                              // Row 1: Voucher No & Date
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      controller: _voucherNoController,
                                      label: 'Voucher No',
                                      readOnly: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      controller: _dateController,
                                      label: 'Date',
                                      readOnly: true,
                                      onTap: _selectDate,
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.calendar_today),
                                        onPressed: _selectDate,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Row 2: Transaction Type & Payment Method
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _transactionType,
                                      items: [
                                        // DropdownMenuItem(
                                        //   value: 'Credit',
                                        //   child: Text(
                                        //     'Credit',
                                        //     style: Theme.of(context)
                                        //         .textTheme
                                        //         .bodySmall!
                                        //         .copyWith(color: Colors.white),
                                        //   ),
                                        // ),
                                        DropdownMenuItem(
                                          value: 'Debit',
                                          child: Text(
                                            'Debit',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _transactionType = value!;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Transaction Type',
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.8),
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _paymentMethod,
                                      items: [
                                        DropdownMenuItem(
                                          value: 'Cash',
                                          child: Text(
                                            'Cash',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Cheque',
                                          child: Text(
                                            'Cheque',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall!
                                                .copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _paymentMethod = value!;
                                        });
                                      },
                                      decoration: InputDecoration(
                                        labelText: 'Payment Method',
                                        labelStyle: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.8),
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Row 3: Amount & Description
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      controller: _amountController,
                                      label: 'Amount',
                                      keyboardType: TextInputType.number,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(value!) == null) {
                                          return 'Invalid amount';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      controller: _descriptionController,
                                      label: 'Description',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Cheque Details Section (Conditional)
                              if (_paymentMethod == 'Cheque') ...[
                                Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Cheque Details',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                ),
                                const SizedBox(height: 16),

                                // Row 4: Cheque No & Cheque Amount
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: buildTextField(
                                        controller: _chequeNoController,
                                        label: 'Cheque No',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTextField(
                                        controller: _chequeAmountController,
                                        label: 'Cheque Amount',
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Row 5: Cheque Date & Bank Name
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: buildTextField(
                                        controller: _chequeDateController,
                                        label: 'Cheque Date',
                                        readOnly: true,
                                        onTap: _selectChequeDate,
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.calendar_today),
                                          onPressed: _selectChequeDate,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTextField(
                                        controller: _bankNameController,
                                        label: 'Bank Name',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Save & Cancel Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Cancel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _saveEntry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).iconTheme.color,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      widget.entry == null ? 'Save' : 'Update',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              buildTextField(
                                controller: _voucherNoController,
                                label: 'Voucher No',
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                controller: _dateController,
                                label: 'Date',
                                readOnly: true,
                                onTap: _selectDate,
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.calendar_today),
                                  onPressed: _selectDate,
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _transactionType,
                                items: [
                                  DropdownMenuItem(
                                    value: 'Credit',
                                    child: Text(
                                      'Credit',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Debit',
                                    child: Text(
                                      'Debit',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _transactionType = value!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Transaction Type',
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _paymentMethod,
                                items: [
                                  DropdownMenuItem(
                                    value: 'Cash',
                                    child: Text(
                                      'Cash',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cheque',
                                    child: Text(
                                      'Cheque',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(color: Colors.white),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _paymentMethod = value!;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Payment Method',
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                controller: _amountController,
                                label: 'Amount',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Required';
                                  if (double.tryParse(value!) == null) {
                                    return 'Invalid amount';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                controller: _descriptionController,
                                label: 'Description',
                              ),
                              const SizedBox(height: 16),

                              // Cheque Details Section (Conditional)
                              if (_paymentMethod == 'Cheque') ...[
                                Divider(),
                                const SizedBox(height: 8),
                                Text(
                                  'Cheque Details',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: _chequeNoController,
                                  label: 'Cheque No',
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: _chequeAmountController,
                                  label: 'Cheque Amount',
                                  keyboardType: TextInputType.number,
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: _chequeDateController,
                                  label: 'Cheque Date',
                                  readOnly: true,
                                  onTap: _selectChequeDate,
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_today),
                                    onPressed: _selectChequeDate,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: _bankNameController,
                                  label: 'Bank Name',
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Save & Cancel Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      'Cancel',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _saveEntry,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).iconTheme.color,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      widget.entry == null ? 'Save' : 'Update',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),

                // Balance Summary Row
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.all(8.0),
                  width: MediaQuery.of(context).size.width,
                  height: 60,
                  child: FutureBuilder<double>(
                    future: customerRepo.getOpeningBalanceForCustomer(
                      widget.customer.name,
                    ),
                    builder: (context, snapshott) {
                      return FutureBuilder<DebitCreditSummary>(
                        future: controller.getCustomerDebitCredit(
                          widget.customer.name,
                          widget.customer.type,
                          widget.customer.id!,
                        ),
                        builder: (context, snapshot) {
                          // Check connection state first
                          if (snapshott.connectionState ==
                                  ConnectionState.waiting ||
                              snapshot.connectionState ==
                                  ConnectionState.waiting) {
                            return const SizedBox(height: 20, width: 20);
                          }

                          // Handle error states
                          if (snapshot.hasError || snapshott.hasError) {
                            return const SizedBox(height: 20, width: 20);
                          }

                          // Check if data exists before accessing it
                          if (!snapshot.hasData ||
                              snapshot.data == null ||
                              !snapshott.hasData ||
                              snapshott.data == null) {
                            return const SizedBox(height: 20, width: 20);
                          }

                          // Now safe to access data
                          final summary = snapshot.data!;
                          final openingBal = snapshott.data!;

                          final totalDebit = double.parse(summary.debit);
                          final totalCredit = double.parse(summary.credit);
                          final netBalance =
                              openingBal + totalCredit - totalDebit;

                          final debitColor = Colors.red;
                          final creditColor = Colors.green;
                          final netBgColor = netBalance >= 0
                              ? creditColor.withValues(alpha: 0.1)
                              : debitColor.withValues(alpha: 0.1);
                          final netTextColor = netBalance >= 0
                              ? creditColor
                              : debitColor;
                          final openingBgColor = openingBal >= 0
                              ? creditColor.withValues(alpha: 0.1)
                              : debitColor.withValues(alpha: 0.1);
                          final openingTextColor = openingBal >= 0
                              ? creditColor
                              : debitColor;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Always show opening balance (adapted from filtered check)
                              buildTotalBox(
                                "Opening Balance",
                                openingBal,
                                bgColor: openingBgColor,
                                textColor: openingTextColor,
                              ),
                              const SizedBox(width: 16),
                              buildTotalBox(
                                "Total Debit",
                                totalDebit,
                                bgColor: debitColor.withValues(alpha: 0.1),
                                textColor: debitColor,
                              ),
                              const SizedBox(width: 16),
                              buildTotalBox(
                                "Total Credit",
                                totalCredit,
                                bgColor: creditColor.withValues(alpha: 0.1),
                                textColor: creditColor,
                              ),
                              const SizedBox(width: 16),
                              buildTotalBox(
                                "Net Balance",
                                (customerLedgerTableController.netBalance +
                                    (customerLedgerTableController.totalCredit +
                                        double.parse(summary.credit))),
                                bgColor: netBgColor,
                                textColor: netTextColor,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _voucherNoController.dispose();
    _dateController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _chequeNoController.dispose();
    _chequeAmountController.dispose();
    _chequeDateController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }
}
