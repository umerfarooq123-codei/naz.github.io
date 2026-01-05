import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_repository.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_table_controller.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class VendorLedgerTablePage extends StatefulWidget {
  final Customer vendor;

  const VendorLedgerTablePage({super.key, required this.vendor});

  @override
  State<VendorLedgerTablePage> createState() => _VendorLedgerTablePageState();
}

class _VendorLedgerTablePageState extends State<VendorLedgerTablePage> {
  late VendorLedgerTableController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller
    Get.delete<VendorLedgerTableController>();
    controller = Get.put(VendorLedgerTableController(), permanent: true);
    controller.currentVendor.value = widget.vendor;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadVendorLedgerEntriesNoParams();
    });
  }

  @override
  void dispose() {
    // Clean up controller when widget is disposed
    Get.delete<VendorLedgerTableController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      appBarTitle: "Ledger: ${widget.vendor.name}",
      showBackButton: true,
      onBackButtonPressed: () {
        NavigationHelper.pushReplacement(context, const CustomerList());
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
                          labelStyle: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: widget.vendor.name,
                      readOnly: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: "Vendor Name",
                        labelStyle: Theme.of(context).textTheme.bodySmall!
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                        border: const OutlineInputBorder(),
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
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            "All Types",
                            style: TextStyle(
                              fontSize: Theme.of(
                                context,
                              ).textTheme.bodySmall!.fontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Debit",
                          child: Text(
                            "Debit",
                            style: TextStyle(
                              fontSize: Theme.of(
                                context,
                              ).textTheme.bodySmall!.fontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Credit",
                          child: Text(
                            "Credit",
                            style: TextStyle(
                              fontSize: Theme.of(
                                context,
                              ).textTheme.bodySmall!.fontSize,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        controller.selectedTransactionType.value = value;
                      },
                      decoration: InputDecoration(
                        labelText: "Transaction Type",
                        labelStyle: Theme.of(context).textTheme.bodySmall!
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                        border: const OutlineInputBorder(),
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
                        labelStyle: Theme.of(context).textTheme.bodySmall!
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
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
                      readOnly: true,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: "To Date",
                        labelStyle: Theme.of(context).textTheme.bodySmall!
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
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
                    heroTag: 'vendor-ledger-fab',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VendorLedgerEntryAddEdit(
                            vendor: widget.vendor,
                            onEntrySaved: () {
                              controller.loadVendorLedgerEntriesNoParams();
                            },
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
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: Obx(() {
                      return SfDataGrid(
                        source: VendorLedgerDataSource(
                          controller.filteredVendorEntries,
                          controller,
                          context,
                          widget.vendor,
                        ),
                        columnWidthMode: ColumnWidthMode.fill,
                        gridLinesVisibility: GridLinesVisibility.both,
                        headerGridLinesVisibility: GridLinesVisibility.both,
                        onCellTap: (details) {
                          if (details.rowColumnIndex.rowIndex > 0) {
                            // final entry =
                            //     controller.filteredVendorEntries[details
                            //             .rowColumnIndex
                            //             .rowIndex -
                            //         1];
                            // Optional: show details dialog if needed
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

            // Bottom summary
            Container(
              alignment: Alignment.centerRight,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    totalBox("Opening Bal", controller.openingBalance, context),
                    const SizedBox(width: 16),
                    totalBox("Credit", controller.rxTotalCredit.value, context),
                    const SizedBox(width: 16),
                    totalBox("Debit", controller.rxTotalDebit.value, context),
                    const SizedBox(width: 16),
                    Obx(
                      () => totalBox(
                        "Net Balance",
                        controller.rxNetBalance.value,
                        context,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

Widget headerText(String text, BuildContext context) => Container(
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

class VendorLedgerDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  final List<VendorLedgerEntry> entries;
  final VendorLedgerTableController controller;
  final BuildContext context;
  final Customer vendor;

  VendorLedgerDataSource(
    this.entries,
    this.controller,
    this.context,
    this.vendor,
  ) {
    _buildRows(entries);
  }

  void _buildRows(List<VendorLedgerEntry> entries) {
    _rows = entries.map((entry) {
      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'entry', value: entry),
          DataGridCell(columnName: 'voucherNo', value: entry.voucherNo),
          DataGridCell(
            columnName: 'date',
            value: DateFormat('dd-MM-yyyy').format(entry.date),
          ),
          DataGridCell(
            columnName: 'description',
            value: entry.description ?? '-',
          ),
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
            value: entry.transactionType == 'Debit'
                ? entry.debit
                : entry.credit,
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
    final entry = entryCell.value as VendorLedgerEntry;
    final dataCells = allCells
        .where((cell) => cell.columnName != 'entry')
        .toList();

    bool isHovered = false;

    return DataGridRowAdapter(
      cells: dataCells.asMap().entries.map((cellEntry) {
        final cell = cellEntry.value;
        final isAmountCell = cell.columnName == 'amount';

        if (isAmountCell) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        NumberFormat('#,##0.00').format(cell.value),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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
                                offset: const Offset(0, 2),
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
                                message: "Delete",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => confirmDeleteDialog(
                                    onConfirm: () {
                                      deleteEntry(entry);
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
                                message: "Edit",
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => editEntry(entry),
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
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(
            cell.value.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      }).toList(),
    );
  }

  void deleteEntry(VendorLedgerEntry entry) async {
    try {
      await controller.deleteVendorLedgerEntry(entry.id!);
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

  void editEntry(VendorLedgerEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VendorLedgerEntryAddEdit(
          vendor: vendor,
          entry: entry, // ← THIS MUST BE PASSED!
          onEntrySaved: () {
            controller.loadVendorLedgerEntriesNoParams();
          },
        ),
      ),
    );
  }
}

class VendorLedgerEntryAddEdit extends StatefulWidget {
  final Customer vendor;
  final VendorLedgerEntry? entry;
  final VoidCallback onEntrySaved;

  const VendorLedgerEntryAddEdit({
    super.key,
    required this.vendor,
    this.entry,
    required this.onEntrySaved,
  });

  @override
  State<VendorLedgerEntryAddEdit> createState() =>
      _VendorLedgerEntryAddEditState();
}

class _VendorLedgerEntryAddEditState extends State<VendorLedgerEntryAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _voucherNoController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _chequeNoController = TextEditingController();
  final _chequeAmountController = TextEditingController();
  final _chequeDateController = TextEditingController();
  final _bankNameController = TextEditingController();

  final repo = VendorLedgerRepository();

  String _paymentMethod = 'Cash';
  String _transactionType = 'Debit';
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedChequeDate;

  final List<String> bankList = [
    'HBL - Habib Bank Limited',
    'UBL - United Bank Limited',
    'NBP - National Bank of Pakistan',
    'Allied Bank',
    'MCB - Muslim Commercial Bank',
    'Bank Alfalah',
    'Bank Al-Habib',
    'Faysal Bank',
    'JS Bank',
    'Askari Bank',
    'KASB Bank',
    'BOP - Bank of Punjab',
    'BIPL - Burj Bank',
    'Meezan Bank',
  ];

  bool get isEditMode => widget.entry != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode) {
      final entry = widget.entry!;

      _voucherNoController.text = entry.voucherNo;
      _selectedDate = entry.date;
      _dateController.text = DateFormat('dd-MM-yyyy').format(entry.date);

      _descriptionController.text = entry.description ?? '';

      final amount = entry.debit > 0 ? entry.debit : entry.credit;
      _amountController.text = amount.toStringAsFixed(2);

      _transactionType = entry.transactionType;
      _paymentMethod = entry.paymentMethod ?? 'Cash';

      if (_paymentMethod == 'Cheque') {
        _chequeNoController.text = entry.chequeNo ?? '';
        _chequeAmountController.text =
            entry.chequeAmount?.toStringAsFixed(2) ?? '';
        _bankNameController.text = entry.bankName ?? '';

        if (entry.chequeDate != null) {
          DateTime? parsedDate;
          if (entry.chequeDate is DateTime) {
            parsedDate = entry.chequeDate as DateTime;
          } else if (entry.chequeDate is String &&
              (entry.chequeDate as String).isNotEmpty) {
            parsedDate = DateTime.tryParse(entry.chequeDate as String);
          }

          if (parsedDate != null) {
            _selectedChequeDate = parsedDate;
            _chequeDateController.text = DateFormat(
              'dd-MM-yyyy',
            ).format(parsedDate);
          }
        }
      }
    } else {
      _dateController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final voucherNo = await repo.getLastVoucherNo(
            widget.vendor.name,
            widget.vendor.id!,
          );
          if (mounted) {
            setState(() {
              _voucherNoController.text = voucherNo;
            });
          }
        } catch (e) {
          debugPrint('Error loading voucher number: $e');
          if (mounted) {
            _voucherNoController.text = 'VN-001';
          }
        }
      });
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

      // Get the controller to calculate proper balance
      final vendorController = Get.find<VendorLedgerTableController>();

      // Balance calculation: Opening Balance + Total Credits (from item ledger) - Total Debits (payments)
      // This represents the remaining amount owed to the vendor
      double totalDebitsAfterSave = vendorController.totalDebit;

      if (isEditMode && widget.entry != null) {
        // When editing: remove old debit amount and add new debit amount
        totalDebitsAfterSave =
            vendorController.totalDebit - widget.entry!.debit;
        if (_transactionType == 'Debit') {
          totalDebitsAfterSave += amount;
        }
      } else if (!isEditMode) {
        // When creating new entry
        if (_transactionType == 'Debit') {
          totalDebitsAfterSave = vendorController.totalDebit + amount;
        }
      }

      double newBalance =
          vendorController.openingBalance +
          vendorController.totalCredit -
          totalDebitsAfterSave;
      if (newBalance < 0) newBalance = 0.0;

      final entry = VendorLedgerEntry(
        id: widget.entry?.id,
        voucherNo: _voucherNoController.text,
        vendorName: widget.vendor.name,
        vendorId: widget.vendor.id!,
        date: _selectedDate,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        debit: _transactionType == 'Debit' ? amount : 0.0,
        credit: _transactionType == 'Credit' ? amount : 0.0,
        balance: newBalance,
        transactionType: _transactionType,
        paymentMethod: _paymentMethod,
        chequeNo: _paymentMethod == 'Cheque' ? _chequeNoController.text : null,
        chequeAmount: _paymentMethod == 'Cheque'
            ? double.tryParse(_chequeAmountController.text)
            : null,
        chequeDate: _paymentMethod == 'Cheque'
            ? _selectedChequeDate.toString()
            : null,
        bankName: _paymentMethod == 'Cheque' ? _bankNameController.text : null,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEditMode) {
        await repo.updateVendorLedgerEntry(entry);
      } else {
        await repo.insertVendorLedgerEntry(entry);
      }

      // Reload vendor ledger entries to reflect updated balance
      await vendorController.loadVendorLedgerEntries(
        widget.vendor.name,
        widget.vendor.id!,
      );

      widget.onEntrySaved();

      if (mounted) {
        Get.snackbar(
          'Success',
          'Entry ${isEditMode ? 'updated' : 'added'} successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
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
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: suffixIcon,
        errorStyle: TextStyle(
          color: Colors.red[900],
          fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return BaseLayout(
      appBarTitle: isEditMode ? 'Edit Ledger Entry' : 'Add Ledger Entry',
      onBackButtonPressed: () {
        NavigationHelper.pushReplacement(
          context,
          VendorLedgerTablePage(vendor: widget.vendor),
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
                        ? Column(children: _buildDesktopForm())
                        : Column(children: _buildMobileForm()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDesktopForm() {
    return [
      Row(
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
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectDate,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: [
                DropdownMenuItem(
                  value: 'Cash',
                  child: Text(
                    'Cash',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                DropdownMenuItem(
                  value: 'Cheque',
                  child: Text(
                    'Cheque',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _paymentMethod = value!),
              decoration: InputDecoration(
                labelText: 'Payment Method',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _transactionType,
              items: [
                DropdownMenuItem(
                  value: 'Debit',
                  child: Text(
                    'Debit',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _transactionType = value!),
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: buildTextField(
              controller: _amountController,
              label: 'Amount',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (double.tryParse(value!) == null) return 'Invalid amount';
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
      if (_paymentMethod == 'Cheque') ..._buildChequeDetails(),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _saveEntry,
            child: Text(isEditMode ? 'Update' : 'Save'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildMobileForm() {
    return [
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
          icon: const Icon(Icons.calendar_today),
          onPressed: _selectDate,
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _paymentMethod,
        items: [
          DropdownMenuItem(
            value: 'Cash',
            child: Text('Cash', style: Theme.of(context).textTheme.bodyMedium),
          ),
          DropdownMenuItem(
            value: 'Cheque',
            child: Text(
              'Cheque',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        onChanged: (value) => setState(() => _paymentMethod = value!),
        decoration: InputDecoration(
          labelText: 'Payment Method',
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        initialValue: _transactionType,
        items: [
          DropdownMenuItem(
            value: 'Debit',
            child: Text('Debit', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
        onChanged: (value) => setState(() => _transactionType = value!),
        decoration: InputDecoration(
          labelText: 'Transaction Type',
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      const SizedBox(height: 16),
      buildTextField(
        controller: _amountController,
        label: 'Amount',
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (double.tryParse(value!) == null) return 'Invalid amount';
          return null;
        },
      ),
      const SizedBox(height: 16),
      buildTextField(controller: _descriptionController, label: 'Description'),
      const SizedBox(height: 16),
      if (_paymentMethod == 'Cheque') ..._buildChequeDetails(),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _saveEntry,
            child: Text(isEditMode ? 'Update' : 'Save'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildChequeDetails() {
    return [
      const Divider(),
      const SizedBox(height: 8),
      Text(
        'Cheque Details',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      const SizedBox(height: 16),
      Row(
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
      Row(
        children: [
          Expanded(
            child: buildTextField(
              controller: _chequeDateController,
              label: 'Cheque Date',
              readOnly: true,
              onTap: _selectChequeDate,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _selectChequeDate,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: bankList.contains(_bankNameController.text)
                  ? _bankNameController.text
                  : null,
              items: bankList
                  .map(
                    (bank) => DropdownMenuItem(
                      value: bank,
                      child: Text(
                        bank,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _bankNameController.text = value!),
              decoration: InputDecoration(
                labelText: 'Bank Name',
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];
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
