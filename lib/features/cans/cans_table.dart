import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Opening',
                                  widget.cans.openingBalanceCans
                                      .toStringAsFixed(2),
                                  context,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Current',
                                  widget.cans.currentCans.toStringAsFixed(2),
                                  context,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total',
                                  widget.cans.totalCans.toStringAsFixed(2),
                                  context,
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Received',
                                  widget.cans.receivedCans.toStringAsFixed(2),
                                  context,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 400,
                            child: SfDataGrid(
                              source: _CansDataSource(
                                controller.filteredCansEntries,
                                context,
                                controller,
                                widget.cans,
                              ),
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
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                GridColumn(
                                  columnName: 'type',
                                  label: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Type',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                GridColumn(
                                  columnName: 'actions',
                                  label: Container(
                                    padding: const EdgeInsets.all(8.0),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Actions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSummaryCard(
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

class _CansDataSource extends DataGridSource {
  final List<CansEntry> entries;
  final BuildContext context;
  final CansController controller;
  final Cans cans;

  _CansDataSource(this.entries, this.context, this.controller, this.cans) {
    buildDataGridRows();
  }

  List<DataGridRow> dataGridRows = [];

  void buildDataGridRows() {
    dataGridRows = entries.map<DataGridRow>((entry) {
      return DataGridRow(
        cells: [
          DataGridCell<String>(
            columnName: 'date',
            value: DateFormat('dd-MM-yyyy').format(entry.date),
          ),
          DataGridCell<String>(columnName: 'voucher', value: entry.voucherNo),
          DataGridCell<String>(
            columnName: 'type',
            value: entry.transactionType,
          ),
          DataGridCell<String>(
            columnName: 'current',
            value: entry.currentCans.toStringAsFixed(2),
          ),
          DataGridCell<String>(
            columnName: 'received',
            value: entry.receivedCans.toStringAsFixed(2),
          ),
          DataGridCell<String>(
            columnName: 'balance',
            value: entry.balance.toStringAsFixed(2),
          ),
          DataGridCell<CansEntry>(columnName: 'actions', value: entry),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => dataGridRows;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataGridCell) {
        if (dataGridCell.columnName == 'actions') {
          final entry = dataGridCell.value as CansEntry;
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => CansEntryAddEdit(
                      cans: cans,
                      controller: controller,
                      entry: entry,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => confirmDeleteDialog(
                    onConfirm: () => controller.deleteCansEntry(entry.id!),
                    context: context,
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            dataGridCell.value.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }).toList(),
    );
  }
}
