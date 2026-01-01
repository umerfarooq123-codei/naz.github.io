import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/features/cans/cans_list.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'cans_controller.dart';
import 'cans_entry_add_edit.dart';

class CansTable extends StatefulWidget {
  final Cans cans;

  const CansTable({super.key, required this.cans});

  @override
  State<CansTable> createState() => _CansTableState();
}

class _CansTableState extends State<CansTable> {
  @override
  void initState() {
    super.initState();
    // Fetch entries after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<CansController>();
      controller.fetchCansEntries(widget.cans.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CansController>();

    return Obx(
      () => BaseLayout(
        appBarTitle: "${widget.cans.accountName} - Cans Transactions",
        onBackButtonPressed: () {
          NavigationHelper.pushReplacement(context, CansList());
        },
        showBackButton: true,
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) => controller.searchQuery.value = value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by voucher no or date...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  controller.searchQuery.value = '',
                            )
                          : null,
                    ),
                  ),
                ),
                if (controller.isLoading.value)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.filteredCansEntries.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No transactions found.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SfDataGrid(
                            source: CansDataSource(
                              controller.filteredCansEntries,
                              context,
                              controller,
                              widget.cans,
                            ),
                            columnWidthMode: ColumnWidthMode.fill,
                            gridLinesVisibility: GridLinesVisibility.both,
                            headerGridLinesVisibility: GridLinesVisibility.both,
                            placeholder: Center(
                              child: Text(
                                "No data available",
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),

                            shrinkWrapRows: true,
                            columns: [
                              GridColumn(
                                columnName: 'date',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Date',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              GridColumn(
                                columnName: 'voucher',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Voucher No',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              GridColumn(
                                columnName: 'previous',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Previous',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              GridColumn(
                                columnName: 'current',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Current',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              GridColumn(
                                columnName: 'total',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Total',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              GridColumn(
                                columnName: 'received',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Received',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              GridColumn(
                                columnName: 'balance',
                                label: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Balance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: buildSummaryCard(
                        //         'Previous Cans',
                        //         widget.cans.openingBalanceCans.toStringAsFixed(
                        //           2,
                        //         ),
                        //         context,
                        //         Colors.blue,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: buildSummaryCard(
                        //         'Current Cans',
                        //         controller.filteredCansEntries
                        //             .fold(
                        //               0.0,
                        //               (sum, entry) => sum + entry.currentCans,
                        //             )
                        //             .toStringAsFixed(2),
                        //         context,
                        //         Colors.green,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: buildSummaryCard(
                        //         'Total Cans',
                        //         (widget.cans.openingBalanceCans +
                        //                 controller.filteredCansEntries.fold(
                        //                   0.0,
                        //                   (sum, entry) =>
                        //                       sum + entry.currentCans,
                        //                 ))
                        //             .toStringAsFixed(2),
                        //         context,
                        //         Colors.purple,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: buildSummaryCard(
                        //         'Received Cans',
                        //         controller.filteredCansEntries
                        //             .fold(
                        //               0.0,
                        //               (sum, entry) => sum + entry.receivedCans,
                        //             )
                        //             .toStringAsFixed(2),
                        //         context,
                        //         Colors.orange,
                        //       ),
                        //     ),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //       child: buildSummaryCard(
                        //         'Balance Cans',
                        //         (widget.cans.openingBalanceCans +
                        //                 controller.filteredCansEntries.fold(
                        //                   0.0,
                        //                   (sum, entry) =>
                        //                       sum + entry.currentCans,
                        //                 ) -
                        //                 controller.filteredCansEntries.fold(
                        //                   0.0,
                        //                   (sum, entry) =>
                        //                       sum + entry.receivedCans,
                        //                 ))
                        //             .toStringAsFixed(2),
                        //         context,
                        //         Colors.red,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => CansEntryAddEdit(
                    cans: widget.cans,
                    controller: controller,
                  ),
                ),
                tooltip: 'Add New Transaction',
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryCard(
    String title,
    String value,
    BuildContext context,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CansDataSource extends DataGridSource {
  final List<CansEntry> entries;
  final BuildContext context;
  final CansController controller;
  final Cans cans;

  CansDataSource(this.entries, this.context, this.controller, this.cans) {
    buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void buildDataGridRows() {
    dataGridRows = entries.asMap().entries.map<DataGridRow>((mapEntry) {
      final index = mapEntry.key;
      final entry = mapEntry.value;

      // Calculate previous balance: for first entry show opening balance,
      // for others show the balance of the previous entry
      double previousCans = _calculatePreviousBalance(index);
      final currentCans = entry.currentCans;
      final totalCans = previousCans + currentCans;
      final receivedCans = entry.receivedCans;

      return DataGridRow(
        cells: [
          DataGridCell<String>(
            columnName: 'date',
            value: DateFormat('dd-MM-yyyy hh:mm:ss').format(entry.date),
          ),
          DataGridCell<String>(columnName: 'voucher', value: entry.voucherNo),
          DataGridCell<String>(
            columnName: 'previous',
            value: previousCans.toStringAsFixed(2),
          ),
          DataGridCell<String>(
            columnName: 'current',
            value: currentCans.toStringAsFixed(2),
          ),
          DataGridCell<String>(
            columnName: 'total',
            value: totalCans.toStringAsFixed(2),
          ),
          DataGridCell<String>(
            columnName: 'received',
            value: receivedCans.toStringAsFixed(2),
          ),
          DataGridCell<CansEntry>(columnName: 'balance', value: entry),
        ],
      );
    }).toList();
  }

  /// Calculate the previous balance (balance of the previous entry)
  double _calculatePreviousBalance(int currentIndex) {
    if (currentIndex == 0) {
      // First entry: previous is opening balance
      return cans.openingBalanceCans;
    } else {
      // Not first entry: previous is the balance up to previous entry
      return _calculateBalance(currentIndex - 1);
    }
  }

  /// Calculate the running balance up to a given index
  double _calculateBalance(int upToIndex) {
    double balance = cans.openingBalanceCans;
    for (int i = 0; i <= upToIndex && i < entries.length; i++) {
      balance += entries[i].currentCans - entries[i].receivedCans;
    }
    return balance;
  }

  @override
  List<DataGridRow> get rows {
    // Rebuild on every access to ensure real-time updates
    buildDataGridRows();
    return dataGridRows;
  }

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    final entry = (row.getCells().last.value as CansEntry);
    bool isHovered = false;
    return DataGridRowAdapter(
      cells: row.getCells().asMap().entries.map((cellEntry) {
        final cell = cellEntry.value;
        final isLastCell = cellEntry.key == row.getCells().length - 1;
        if (isLastCell) {
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
                          _calculateBalance(
                            entries.indexOf(entry),
                          ).toStringAsFixed(2),
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Container(
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
                              message: "edit",
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () =>
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => CansEntryAddEdit(
                                        cans: cans,
                                        controller: controller,
                                        entry: entry,
                                      ),
                                    ).then((_) {
                                      // Refresh data after dialog closes
                                      controller.fetchCansEntries(cans.id!);
                                    }),
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
                            Tooltip(
                              message: "delete",
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => confirmDeleteDialog(
                                  onConfirm: () async {
                                    await controller.deleteCansEntry(entry.id!);
                                  },
                                  context: context,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
