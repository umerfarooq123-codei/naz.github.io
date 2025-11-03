// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/core/utils/responsive.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/inventory/inventory_repository.dart';
import 'package:ledger_master/features/sales_invoicing/invoice_generator.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'ledger_repository.dart';

class LedgerHome extends StatelessWidget {
  const LedgerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final ledgerController = Get.find<LedgerController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final customerController = Get.find<CustomerController>();

    Widget buildHighlightedText(String text, String query) {
      if (query.isEmpty) {
        return Text(text, style: Theme.of(context).textTheme.bodySmall);
      }

      final textLower = text.toLowerCase();
      final queryLower = query.toLowerCase();
      if (!textLower.contains(queryLower)) {
        return Text(text, style: Theme.of(context).textTheme.bodySmall);
      }

      final regex = RegExp(RegExp.escape(queryLower));
      final matches = regex.allMatches(textLower).toList();

      final List<InlineSpan> spans = [];
      int currentIndex = 0;
      for (final match in matches) {
        if (currentIndex < match.start) {
          spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
        }
        spans.add(
          TextSpan(
            text: text.substring(match.start, match.end),
            style: TextStyle(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.3),
            ),
          ),
        );
        currentIndex = match.end;
      }
      if (currentIndex < text.length) {
        spans.add(TextSpan(text: text.substring(currentIndex)));
      }

      return RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: spans,
        ),
      );
    }

    return Obx(
      () => BaseLayout(
        showBackButton: false,
        appBarTitle: "General Ledger",
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) {
                        return ledgerController.recentSearches;
                      }
                      return ledgerController.recentSearches.where(
                        (search) => search.toLowerCase().contains(q),
                      );
                    },
                    onSelected: (String value) async {
                      ledgerController.searchQuery.value = value;
                      await ledgerController.saveRecentSearch(value);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            style: Theme.of(context).textTheme.bodySmall!,
                            decoration: InputDecoration(
                              hintText:
                                  'Search by ledger no, account, type, date, tags...',
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
                                    valueListenable: controller,
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
                                              controller.clear();
                                              ledgerController
                                                      .searchQuery
                                                      .value =
                                                  '';
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                            ),
                            onChanged: (value) {
                              ledgerController.searchQuery.value = value;
                            },
                            onSubmitted: (value) async {
                              onFieldSubmitted();
                              if (value.trim().isNotEmpty) {
                                await ledgerController.saveRecentSearch(
                                  value.trim(),
                                );
                              }
                            },
                          );
                        },
                  ),
                ),
                Expanded(
                  child: ledgerController.filteredLedgers.isEmpty
                      ? Center(
                          child: Text(
                            'No ledger entries found.',
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop
                                    ? 4
                                    : MediaQuery.of(context).size.width < 500
                                    ? 1
                                    : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 3.5 / 2,
                              ),
                          itemCount: ledgerController.filteredLedgers.length,
                          itemBuilder: (context, index) {
                            final ledger =
                                ledgerController.filteredLedgers[index];
                            return Card(
                              color: Colors.white30,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // 👈 rounded corners here
                                side: const BorderSide(
                                  color: Colors.grey,
                                ), // optional border
                              ),
                              child: InkWell(
                                onTap: () => NavigationHelper.push(
                                  context,
                                  LedgerTablePage(ledger: ledger),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.table_chart,
                                            color: Colors.white,
                                            size: 30,
                                          ), // darker for contrast
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              buildHighlightedText(
                                                'Ledger No: ${ledger.ledgerNo}',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                              buildHighlightedText(
                                                'Created: ${DateFormat('dd-MM-yyyy').format(ledger.createdAt)} by ${ledger.createdBy ?? "Unknown"}',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              buildHighlightedText(
                                                'Account: ${ledger.accountName}',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                              buildHighlightedText(
                                                'Type: ${ledger.transactionType}',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                              buildHighlightedText(
                                                'Debit: ${NumberFormat('#,##0.00').format(ledger.debit)} ',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                              buildHighlightedText(
                                                'Credit: ${NumberFormat('#,##0.00').format(ledger.credit)}',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                              if (ledger.description != null)
                                                buildHighlightedText(
                                                  'Description: ${ledger.description}',
                                                  ledgerController
                                                      .searchQuery
                                                      .value,
                                                ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                ),
                                                onPressed: () async {
                                                  await ledgerController
                                                      .loadLedgerNo(
                                                        ledger: ledger,
                                                      );
                                                  if (context.mounted) {
                                                    NavigationHelper.push(
                                                      context,
                                                      LedgerAddEdit(
                                                        ledger: ledger,
                                                      ),
                                                    );
                                                    await ledgerController
                                                        .fetchLedgers();
                                                  }
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                ),
                                                onPressed: () =>
                                                    ledgerController
                                                        .deleteLedger(
                                                          ledger.id!,
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
                ),
              ],
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: FloatingActionButton(
                heroTag: 'ledger-fab',
                onPressed: () async {
                  if (customerController.customers.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please add customers/vendors first.',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    ledgerController.clearForm();
                    await ledgerController.loadLedgerNo();
                    if (context.mounted) {
                      NavigationHelper.push(context, const LedgerAddEdit());
                      await ledgerController.fetchLedgers();
                    }
                  }
                },
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LedgerAddEdit extends StatefulWidget {
  final Ledger? ledger;
  const LedgerAddEdit({super.key, this.ledger});

  @override
  State<LedgerAddEdit> createState() => _LedgerAddEditState();
}

class _LedgerAddEditState extends State<LedgerAddEdit> {
  late final LedgerController controller;
  late final CustomerController customerController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LedgerController>();
    customerController = Get.find<CustomerController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerNo(ledger: widget.ledger);
    });
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        errorStyle: TextStyle(
          color: Colors.red[900],
          fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
        ),
      ),
      style: Theme.of(context).textTheme.bodySmall,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
    );
  }

  Customer? _findCustomerByName(String name) {
    for (final c in customerController.customers) {
      if (c.name == name) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Obx(
      () => BaseLayout(
        showBackButton: false,
        appBarTitle: widget.ledger == null
            ? 'Add Ledger Entry'
            : 'Edit Ledger Entry',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ledger Details',
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            (Theme.of(context).cardTheme.color ??
                                    Theme.of(context).colorScheme.surface)
                                .withValues(alpha: 1),
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
                          ? buildDesktopLayout()
                          : buildMobileLayout(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          controller.clearForm();
                          NavigationHelper.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => controller.saveLedger(
                          context,
                          ledger: widget.ledger,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(context).iconTheme.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDesktopLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildTextField(
                controller: controller.ledgerNoController,
                label: 'Ledger No',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(() {
                final selected = _findCustomerByName(
                  controller.accountNameController.text,
                );
                return DropdownButtonFormField<Customer>(
                  initialValue: selected,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
                    labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: customerController.customers
                      .where(
                        (cust) => cust.customerNo.toString().contains('CUST'),
                      )
                      .toList()
                      .map(
                        (cust) => DropdownMenuItem<Customer>(
                          value: cust,
                          child: Text(cust.name),
                        ),
                      )
                      .toList(),
                  onChanged: (cust) {
                    if (cust != null) {
                      controller.accountNameController.text = cust.name;
                      controller.accountIdController.text =
                          cust.id?.toString() ?? '';
                      controller.debitController.text = '0.00';
                      controller.creditController.text = '0.00';
                    }
                  },
                  validator: (value) {
                    if (value == null) return 'Please select an account';
                    return null;
                  },
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // account id + transaction type
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildTextField(
                controller: controller.accountIdController,
                label: 'Account ID',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: controller.transactionType.value,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Transaction Type',
                  labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const ['Debit', 'Credit']
                    .map(
                      (t) => DropdownMenuItem<String>(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (value) {
                  controller.transactionType.value = value;
                  controller.transactionTypeController.text = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a transaction type';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Debit / Credit
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildTextField(
                controller: controller.debitController,
                label: 'Debit',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a debit amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                controller: controller.creditController,
                label: 'Credit',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a credit amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date / Description
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => controller.selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    DateFormat(
                      'dd-MM-yyyy',
                    ).format(controller.selectedDate.value),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                controller: controller.descriptionController,
                label: 'Description',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reference / Category
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildTextField(
                controller: controller.referenceNumberController,
                label: 'Reference',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                controller: controller.categoryController,
                label: 'Category',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Balance & Status & Voucher
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildTextField(
                controller: controller.voucherNoController,
                label: 'Voucher No',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                controller: controller.balanceController,
                label: 'Balance',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter balance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: controller.status.value,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const ['Debit', 'Credit']
                    .map(
                      (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                    )
                    .toList(),
                onChanged: null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select status';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tags / Created By
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildTextField(
                controller: controller.tagsController,
                label: 'Tags (comma-separated)',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildTextField(
                controller: controller.createdByController,
                label: 'Created By',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildMobileLayout() {
    return Column(
      children: [
        buildTextField(
          controller: controller.ledgerNoController,
          label: 'Ledger No',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        Obx(() {
          final selected = _findCustomerByName(
            controller.accountNameController.text,
          );
          return DropdownButtonFormField<Customer>(
            initialValue: selected,
            style: Theme.of(context).textTheme.bodySmall,
            decoration: InputDecoration(
              labelText: 'Account Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: customerController.customers
                .where((cust) => cust.customerNo.toString().contains('CUST'))
                .toList()
                .map(
                  (cust) => DropdownMenuItem<Customer>(
                    value: cust,
                    child: Text(cust.name),
                  ),
                )
                .toList(),
            onChanged: (cust) {
              if (cust != null) {
                controller.accountNameController.text = cust.name;
                controller.accountIdController.text = cust.id?.toString() ?? '';
                controller.debitController.text = '0.00';
                controller.creditController.text = '0.00';
              }
            },
            validator: (value) {
              if (value == null) return 'Please select an account';
              return null;
            },
          );
        }),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.accountIdController,
          label: 'Account ID',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: controller.transactionType.value,
          style: Theme.of(context).textTheme.bodySmall,
          decoration: InputDecoration(
            labelText: 'Transaction Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const ['Debit', 'Credit']
              .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
              .toList(),
          onChanged: (value) {
            controller.transactionType.value = value;
            controller.transactionTypeController.text = value ?? '';
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a transaction type';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.debitController,
          label: 'Debit',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.creditController,
          label: 'Credit',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => controller.selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              DateFormat('dd-MM-yyyy').format(controller.selectedDate.value),
            ),
          ),
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.descriptionController,
          label: 'Description',
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.referenceNumberController,
          label: 'Reference',
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.categoryController,
          label: 'Category',
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.voucherNoController,
          label: 'Voucher No',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.balanceController,
          label: 'Balance',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          readOnly: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: controller.status.value,
          style: Theme.of(context).textTheme.bodySmall,
          decoration: InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const ['Debit', 'Credit']
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: null,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please select status';
            return null;
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.tagsController,
          label: 'Tags (comma-separated)',
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.createdByController,
          label: 'Created By',
        ),
      ],
    );
  }
}

class LedgerTablePage extends StatelessWidget {
  final Ledger ledger;

  const LedgerTablePage({super.key, required this.ledger});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LedgerTableController>();
    // Create the column sizer using current entries (recreated whenever entries change)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntries(ledger.ledgerNo).then((value) {
        if (controller.filteredLedgerEntries.isNotEmpty) {
          final lastIndex = controller.filteredLedgerEntries.length - 1;
          Future.delayed(Duration(milliseconds: 500), () {
            controller.dataGridController.scrollToRow(lastIndex.toDouble());
          });
        }
      });
    });

    return BaseLayout(
      showBackButton: true,
      appBarTitle: "Ledger Entries of: ${ledger.accountName}",
      child: Obx(() {
        final columnSizer = LedgerColumnSizer(
          entries: controller.filteredLedgerEntries,
          // optional tuning:
          maxColumnWidth: MediaQuery.of(context).size.width * 0.6, // cap width
          extraHorizontalPadding: 20.0,
        );
        controller.ensureColumnWidth('voucherNo', 94);
        controller.ensureColumnWidth('date', 86);
        controller.ensureColumnWidth('item', 115);
        controller.ensureColumnWidth('priceperkg', 90);
        controller.ensureColumnWidth('canqty', 70);
        controller.ensureColumnWidth('balcanqty', 80);
        controller.ensureColumnWidth('reccanqty', 80);
        controller.ensureColumnWidth('canweight', 90);
        controller.ensureColumnWidth('transactionType', 70);
        controller.ensureColumnWidth('description', 590);
        controller.ensureColumnWidth('createdBy', 90);
        controller.ensureColumnWidth('debit', 90);
        controller.ensureColumnWidth('credit', 90);
        controller.ensureColumnWidth('balance', 110);
        return Column(
          children: [
            // Search + Filters Row
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Search by Voucher No, Date or Ref No",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          hintStyle: Theme.of(context).textTheme.bodySmall,
                          labelStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: ledger.accountName,
                      readOnly: true,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Ledger Name",
                        border: OutlineInputBorder(),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.selectedTransactionType.value,
                      style: Theme.of(context).textTheme.bodySmall,
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
                        border: OutlineInputBorder(),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: controller.fromDateController,
                      readOnly: true,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "From Date",
                        border: const OutlineInputBorder(),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      readOnly: true,
                      decoration: InputDecoration(
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        labelText: "To Date",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () =>
                              controller.selectDate(context, false),
                        ),
                      ),
                      onTap: () => controller.selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: 'ledger-fab',
                    onPressed: () async {
                      if (context.mounted) {
                        NavigationHelper.push(
                          context,
                          LedgerEntryAddEdit(
                            ledgerNo: ledger.ledgerNo,
                            accountId: ledger.accountId!.toString(),
                            accountName: ledger.accountName,
                            onEntrySaved: () =>
                                controller.loadLedgerEntries(ledger.ledgerNo),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),

            // Ledger Entries Table
            controller.isLoading.value
                ? Expanded(
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: SfDataGrid(
                      source: LedgerEntryDataSource(
                        controller.filteredLedgerEntries,
                        context,
                        onPrint: (entry, index) => printEntry(entry, index),
                        onDelete: (entry) =>
                            deleteEntry(controller, entry, context),
                        onEdit: (entry) =>
                            editEntry(controller, entry, context),
                      ),
                      controller: controller.dataGridController,
                      columnSizer: columnSizer,
                      columnWidthMode: ColumnWidthMode.none,
                      gridLinesVisibility: GridLinesVisibility.both,
                      headerGridLinesVisibility: GridLinesVisibility.both,
                      allowColumnsResizing: true,
                      onColumnResizeUpdate: (ColumnResizeUpdateDetails details) {
                        final colName = details.column.columnName;
                        // update reactive map -> Obx rebuilds and GridColumn.width will pick this up
                        controller.columnWidths[colName] = details.width;
                        return true; // allow the change
                      },

                      // optional: persist width after resize ends (not strictly necessary)
                      onColumnResizeEnd: (ColumnResizeEndDetails details) {
                        final colName = details.column.columnName;
                        controller.columnWidths[colName] = details.width;
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
                          width: controller.columnWidths['voucherNo'] ?? 94,
                          label: headerText("Voucher No", context),
                        ),
                        GridColumn(
                          columnName: 'date',
                          width: controller.columnWidths['date'] ?? 86,
                          label: headerText("Date", context),
                        ),
                        GridColumn(
                          columnName: 'item',
                          width: controller.columnWidths['item'] ?? 150,
                          label: headerText("Item", context),
                        ),
                        GridColumn(
                          columnName: 'priceperkg',
                          width: controller.columnWidths['priceperkg'] ?? 100,
                          label: headerText("Price", context),
                        ),
                        GridColumn(
                          columnName: 'canqty',
                          width: controller.columnWidths['canqty'] ?? 90,
                          label: headerText("Can Qty", context),
                        ),
                        GridColumn(
                          columnName: 'balcanqty',
                          width: controller.columnWidths['balcanqty'] ?? 80,
                          label: headerText("Bln Cans", context),
                        ),
                        GridColumn(
                          columnName: 'reccanqty',
                          width: controller.columnWidths['reccanqty'] ?? 80,
                          label: headerText("Rec Cans", context),
                        ),
                        GridColumn(
                          columnName: 'canweight',
                          width: controller.columnWidths['canweight'] ?? 110,
                          label: headerText("Can weight", context),
                        ),
                        GridColumn(
                          columnName: 'transactionType',
                          width:
                              controller.columnWidths['transactionType'] ?? 110,
                          label: headerText("Type", context),
                        ),
                        GridColumn(
                          columnName: 'description',
                          width: controller.columnWidths['description'] ?? 180,
                          label: headerText("Description", context),
                        ),
                        GridColumn(
                          columnName: 'createdBy',
                          width: controller.columnWidths['createdBy'] ?? 120,
                          label: headerText("Created By", context),
                        ),
                        GridColumn(
                          columnName: 'debit',
                          width: controller.columnWidths['debit'] ?? 100,
                          label: headerText("Debit", context),
                        ),
                        GridColumn(
                          columnName: 'credit',
                          width: controller.columnWidths['credit'] ?? 100,
                          label: headerText("Credit", context),
                        ),
                        GridColumn(
                          columnName: 'balance',
                          width: controller.columnWidths['balance'] ?? 100,
                          label: headerText("Balance", context),
                        ),
                      ],
                    ),
                  ),
            // Totals row
            Container(
              alignment: Alignment.centerRight,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  totalBox("Total Debit", controller.totalDebit, context),
                  const SizedBox(width: 16),
                  totalBox("Net Balance", controller.netBalance, context),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget totalBox(String label, double value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Text(
        "$label: ${NumberFormat('#,##0.00', 'en_US').format(value)}",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget headerText(String text, context) => Container(
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    ),
  );

  Future<void> printEntry(LedgerEntry entry, int index) async {
    final ledgerTableController = Get.find<LedgerTableController>();
    final customerController = Get.find<CustomerController>();
    final items = [
      ReceiptItem(
        name: entry.itemName!,
        price: entry.itemPricePerUnit ?? 0,
        canQuantity: entry.cansQuantity ?? 0,
        type: entry.transactionType,
        description: entry.description ?? '',
        amount: (entry.debit) > 0 ? entry.debit : entry.credit,
      ),
    ];
    var customer = await customerController.repo.getCustomer(
      ledger.accountId!.toString(),
    );

    // ====== NEW: compute running previous balance by iterating up to `index` ======
    final list = ledgerTableController.filteredLedgerEntries;
    double runningPrevBalance = 0.0;

    // Sum net cans (added - received) for all entries before `index`
    for (int i = 0; i < index && i < list.length; i++) {
      final prevEntry = list[i];
      final prevCans = safeParseDouble(prevEntry.cansQuantity);
      final prevReceived = safeParseDouble(prevEntry.receivedCans);
      runningPrevBalance = runningPrevBalance + prevCans - prevReceived;
    }

    // Current entry values
    final currentCans = safeParseDouble(list[index].cansQuantity);
    final receivedCans = safeParseDouble(list[index].receivedCans);

    // Totals based on running previous balance
    final totalCans = runningPrevBalance + currentCans;
    final newBalanceCans = totalCans - receivedCans;
    final data = ReceiptData(
      companyName: 'NAZ ENTERPRISES',
      date: DateFormat('dd/MM/yyyy').format(entry.date),
      customerName: ledger.accountName,
      customerAddress: customer?.address ?? '',
      vehicleNumber: entry.referenceNo ?? 'N/A',
      items: items,

      // Use calculated values (instead of stored stale ones)
      previousCans: runningPrevBalance,
      currentCans: currentCans,
      totalCans: totalCans,

      receivedCans: receivedCans,
      balanceCans: newBalanceCans,

      currentAmount: entry.transactionType.toLowerCase() == 'debit'
          ? (entry.debit)
          : (entry.credit),

      netBalance: index == 0
          ? 0.0
          : ledgerTableController.filteredLedgerEntries[index - 1].balance,
      previousAmount: (index > 0
          ? ledgerTableController.filteredLedgerEntries[index - 1].balance
          : 0.0),
      voucherNumber: entry.voucherNo,
    );

    await ReceiptPdfGenerator.generateAndPrint(data);
  }

  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  int safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return 0;
    return int.tryParse(str) ?? (double.tryParse(str)?.toInt() ?? 0);
  }

  Future<void> editEntry(
    LedgerTableController controller,
    LedgerEntry entry,
    BuildContext context,
  ) async {
    await controller.ledgerController.loadLedgerEntry(
      entry: entry,
      ledgerNo: entry.ledgerNo,
    );
    if (context.mounted) {
      NavigationHelper.push(
        context,
        LedgerEntryAddEdit(
          entry: entry,
          ledgerNo: entry.ledgerNo,
          accountId: entry.accountId!.toString(),
          accountName: entry.accountName,
        ),
      );
    }
  }

  Future<void> deleteEntry(
    LedgerTableController controller,
    LedgerEntry entry,
    BuildContext context,
  ) async {
    await controller.ledgerController.deleteLedgerEntry(
      entry.id!,
      ledger.ledgerNo,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Entry deleted')));
    }
    controller.loadLedgerEntries(ledger.ledgerNo);
  }
}

class LedgerEntryDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  final BuildContext context;
  final Function(LedgerEntry, int) onPrint;
  final Function(LedgerEntry) onDelete;
  final Function(LedgerEntry) onEdit;

  LedgerEntryDataSource(
    List<LedgerEntry> entries,
    this.context, {
    required this.onPrint,
    required this.onDelete,
    required this.onEdit,
  }) {
    _rows = entries.map((entry) {
      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'voucherNo', value: entry.voucherNo),
          DataGridCell(
            columnName: 'date',
            value: DateFormat('dd-MM-yyyy').format(entry.date),
          ),
          DataGridCell(columnName: 'item', value: entry.itemName),
          DataGridCell(
            columnName: 'priceperkg',
            value: '${entry.itemPricePerUnit}/(Kg/L)',
          ),
          DataGridCell(columnName: 'canqty', value: entry.cansQuantity),
          DataGridCell(columnName: 'balcanqty', value: entry.balanceCans),
          DataGridCell(columnName: 'reccanqty', value: entry.receivedCans),
          DataGridCell(
            columnName: 'canweight',
            value: '${entry.canWeight}(Kg/L)',
          ),
          DataGridCell(
            columnName: 'transactionType',
            value: entry.transactionType,
          ),
          DataGridCell(
            columnName: 'description',
            value: entry.description ?? '',
          ),
          DataGridCell(columnName: 'createdBy', value: entry.createdBy ?? ''),
          DataGridCell(columnName: 'debit', value: entry.debit),
          DataGridCell(columnName: 'credit', value: entry.credit),
          DataGridCell(columnName: 'balance', value: entry),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final entry = (row.getCells().last.value as LedgerEntry);
    bool isHovered = false;

    return DataGridRowAdapter(
      cells: row.getCells().asMap().entries.map((cellEntry) {
        final cell = cellEntry.value;
        final isLastCell = cellEntry.key == row.getCells().length - 1;
        // final rowIndex = _rows.length - 1 - _rows.indexOf(row);
        final rowIndex = _rows.indexOf(row);
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
                          NumberFormat(
                            '#,##0.00',
                            'en_US',
                          ).format(cell.value.balance ?? 0),
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: "print",
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onPrint(entry, rowIndex),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: const Icon(Icons.print, size: 16),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: "delete",
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onDelete(entry),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: const Icon(Icons.delete, size: 16),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: "edit",
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onEdit(entry),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: const Icon(Icons.edit, size: 16),
                              ),
                            ),
                          ),
                        ],
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
              cell.columnName == 'debit' || cell.columnName == 'credit'
                  ? NumberFormat('#,##0.00', 'en_US').format(cell.value ?? 0)
                  : cell.value.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight:
                    cell.columnName == 'debit' || cell.columnName == 'credit'
                    ? FontWeight.w500
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class LedgerTableController extends GetxController {
  final LedgerController ledgerController = Get.find<LedgerController>();
  final DataGridController dataGridController = DataGridController();
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final searchController = TextEditingController();
  final selectedRows = <int>{}.obs;
  final selectAll = false.obs;
  final selectedTransactionType = RxnString();
  final isLoading = false.obs;
  final calculationAnalysis = ''.obs;
  final showCalculationAnalysis = false.obs;
  final searchQuery = ''.obs;
  final fromDate = Rx<DateTime>(DateTime.now().subtract(Duration(days: 30)));
  final toDate = Rx<DateTime>(DateTime.now());
  final filteredLedgerEntries = <LedgerEntry>[].obs;
  final RxMap<String, double> columnWidths = <String, double>{}.obs;

  // optional helper to set a default width only if not already set
  void ensureColumnWidth(String columnName, double width) {
    if (!columnWidths.containsKey(columnName)) {
      columnWidths[columnName] = width;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Initialize with proper dates
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));

    fromDate.value = thirtyDaysAgo;
    toDate.value = now;

    fromDateController.text = DateFormat('dd-MM-yyyy').format(thirtyDaysAgo);
    toDateController.text = DateFormat('dd-MM-yyyy').format(now);

    // React to changes in filter criteria
    ever(searchQuery, (_) => _applyFilters());
    ever(fromDate, (_) => _applyFilters());
    ever(toDate, (_) => _applyFilters());
    ever(selectedTransactionType, (_) => _applyFilters());

    // Apply initial filters
    _applyFilters();
  }

  void _applyFilters() {
    DateTime fromDateValue;
    DateTime toDateValue;

    try {
      // Handle empty or invalid fromDate
      if (fromDateController.text.isEmpty) {
        fromDateValue = DateTime.now().subtract(Duration(days: 30));
      } else {
        fromDateValue = DateFormat('dd-MM-yyyy').parse(fromDateController.text);
      }

      // Handle empty or invalid toDate
      if (toDateController.text.isEmpty) {
        toDateValue = DateTime.now();
      } else {
        toDateValue = DateFormat('dd-MM-yyyy').parse(toDateController.text);
      }
    } catch (e) {
      // Fallback to default dates if parsing fails
      fromDateValue = DateTime.now().subtract(Duration(days: 30));
      toDateValue = DateTime.now();

      // Update controllers with fallback values
      fromDateController.text = DateFormat('dd-MM-yyyy').format(fromDateValue);
      toDateController.text = DateFormat('dd-MM-yyyy').format(toDateValue);
    }

    final filtered = ledgerController.ledgerEntries.where((entry) {
      bool dateMatch =
          entry.date.isAfter(fromDateValue.subtract(Duration(days: 1))) &&
          entry.date.isBefore(toDateValue.add(Duration(days: 1)));

      bool typeMatch =
          selectedTransactionType.value == null ||
          entry.transactionType == selectedTransactionType.value;

      bool searchMatch =
          searchQuery.value.isEmpty ||
          entry.voucherNo.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          (entry.referenceNo?.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ) ??
              false);

      return dateMatch && typeMatch && searchMatch;
    }).toList();

    filtered.sort((a, b) {
      int dateComparison = b.date.compareTo(a.date);
      if (dateComparison != 0) return dateComparison;
      return (b.id ?? 0).compareTo(a.id ?? 0);
    });

    filteredLedgerEntries.assignAll(filtered);
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadLedgerEntries(String ledgerNo) async {
    isLoading.value = true;
    await ledgerController.fetchLedgerEntries(ledgerNo); // REMOVE THE DELAY
    // Calculate running balance after fetching entries (full chronological)
    calculateRunningBalance(ledgerNo);
    isLoading.value = false;
  }

  void calculateRunningBalance(String ledgerNo) {
    final allEntries = ledgerController.ledgerEntries;
    double runningBalance = 0.0;

    // Sort entries by date and id to ensure chronological order for calculations
    allEntries.sort((a, b) {
      int dateComparison = a.date.compareTo(b.date);
      if (dateComparison != 0) return dateComparison;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });

    for (var entry in allEntries) {
      // Update balance: previous balance + credit only (ignore debit)
      runningBalance += entry.credit;
      entry.balance = runningBalance;
    }

    // Trigger filter to update the view with correct balances and sorting
    filterLedgerEntries();
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
      if (isFromDate) {
        fromDate.value = picked;
        fromDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      } else {
        toDate.value = picked;
        toDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      }
    }
  }

  void filterLedgerEntries() {
    // Get filtered entries based on criteria
    final filtered = ledgerController.ledgerEntries.where((entry) {
      // Date filter
      final entryDate = entry.date;
      final fromDate = DateFormat('dd-MM-yyyy').parse(fromDateController.text);
      final toDate = DateFormat('dd-MM-yyyy').parse(toDateController.text);

      bool dateMatch =
          entryDate.isAfter(fromDate.subtract(Duration(days: 1))) &&
          entryDate.isBefore(toDate.add(Duration(days: 1)));

      // Transaction type filter
      bool typeMatch =
          selectedTransactionType.value == null ||
          entry.transactionType == selectedTransactionType.value;

      // Search filter
      bool searchMatch =
          searchController.text.isEmpty ||
          entry.voucherNo.toLowerCase().contains(
            searchController.text.toLowerCase(),
          ) ||
          (entry.referenceNo?.toLowerCase().contains(
                searchController.text.toLowerCase(),
              ) ??
              false) ||
          DateFormat(
            'dd-MM-yyyy',
          ).format(entry.date).contains(searchController.text);

      return dateMatch && typeMatch && searchMatch;
    }).toList();

    // Sort filtered entries by date ASCENDING and id ASCENDING (for display order)
    filtered.sort((a, b) {
      int dateComparison = a.date.compareTo(b.date); // ASCENDING: a before b
      if (dateComparison != 0) return dateComparison;
      return (a.id ?? 0).compareTo(b.id ?? 0); // ASCENDING: a before b
    });

    // Update the filtered entries in the ledger controller
    filteredLedgerEntries.assignAll(filtered);
  }

  void handleRowSelection(int id, bool? selected) {
    if (selected == true) {
      selectedRows.add(id);
    } else {
      selectedRows.remove(id);
    }

    if (selectedRows.length == filteredLedgerEntries.length) {
      selectAll.value = true;
    } else {
      selectAll.value = false;
    }
  }

  void handleSelectAll(bool? selected) {
    selectAll.value = selected ?? false;
    if (selectAll.value) {
      selectedRows.assignAll(filteredLedgerEntries.map((e) => e.id!));
    } else {
      selectedRows.clear();
    }
  }

  double get totalDebit {
    return filteredLedgerEntries.fold(0.0, (sum, entry) => sum + entry.debit);
  }

  double get totalCredit {
    return filteredLedgerEntries.fold(0.0, (sum, entry) => sum + entry.credit);
  }

  double get netBalance {
    if (filteredLedgerEntries.isEmpty) return 0.0;

    // ALTERNATIVE FIX: Calculate net balance from the original entries
    // Find the most recent entry in the original (chronologically sorted) list
    final allEntries = ledgerController.ledgerEntries;
    if (allEntries.isEmpty) return 0.0;

    // Sort by date descending to get the most recent entry
    allEntries.sort((a, b) => b.date.compareTo(a.date));
    return allEntries.first.balance;
  }

  double get balanceCans {
    // Sum cansQuantity of all filtered entries safely
    return filteredLedgerEntries.fold<double>(
      0.0,
      (sum, entry) =>
          (sum +
                  (entry.cansQuantity ?? 0) -
                  double.tryParse(entry.receivedCans!)!)
              .toDouble(),
    );
  }

  void analyzeCalculations() {
    final entries = filteredLedgerEntries;
    String analysis = "Calculation Analysis:\n\n";

    analysis += "All Entries:\n";
    for (var entry in entries) {
      analysis +=
          "Voucher: ${entry.voucherNo} | Debit: ${NumberFormat('#,##0.00', 'en_US').format(entry.debit)} | Credit: ${NumberFormat('#,##0.00', 'en_US').format(entry.credit)} | Balance: ${NumberFormat('#,##0.00', 'en_US').format(entry.balance)}\n";
    }

    analysis += "\nTotals:\n";
    analysis +=
        "Total Debit: ${NumberFormat('#,##0.00', 'en_US').format(totalDebit)}\n";
    analysis +=
        "Total Credit: ${NumberFormat('#,##0.00', 'en_US').format(totalCredit)}\n";
    analysis +=
        "Net Balance: ${NumberFormat('#,##0.00', 'en_US').format(netBalance)}\n\n";

    // Calculate expected net balance (credits only)
    double calculatedNetBalance = entries.fold(
      0.0,
      (sum, entry) => sum + entry.credit,
    );
    analysis +=
        "Calculated Net Balance (Sum of Credits): ${NumberFormat('#,##0.00', 'en_US').format(calculatedNetBalance)}\n";

    if ((netBalance - calculatedNetBalance).abs() < 0.01) {
      // Allow for floating point precision
      analysis += "✓ Balance calculation is CORRECT\n";
    } else {
      analysis += "✗ Balance calculation is INCORRECT\n";
      analysis +=
          "Difference: ${NumberFormat('#,##0.00', 'en_US').format(netBalance - calculatedNetBalance)}\n";
    }

    calculationAnalysis.value = analysis;
    showCalculationAnalysis.value = true;
  }
}

class LedgerController extends GetxController {
  final LedgerRepository repo;
  final InventoryRepository inventoryRepo = InventoryRepository();
  final ledgers = <Ledger>[].obs;
  final filteredLedgers = <Ledger>[].obs;
  final ledgerEntries = <LedgerEntry>[].obs;
  final isDarkMode = true.obs;
  RxList<EntryFormData> entryForms = <EntryFormData>[].obs;
  final Map<String, int> _nextVoucherNums = <String, int>{};
  String? _sharedVoucherNo;
  final formKey = GlobalKey<FormState>();

  // Ledger Form controllers (unchanged)
  final ledgerNoController = TextEditingController();
  final voucherNoController = TextEditingController();
  final accountNameController = TextEditingController();
  final accountIdController = TextEditingController();
  final transactionTypeController = TextEditingController();
  final debitController = TextEditingController();
  final creditController = TextEditingController();
  final balanceController = TextEditingController();
  final descriptionController = TextEditingController();
  final referenceNumberController = TextEditingController();
  final categoryController = TextEditingController();
  final tagsController = TextEditingController();
  final createdByController = TextEditingController();
  final statusController = TextEditingController();

  final selectedDate = DateTime.now().obs;
  final transactionType = RxnString();
  final status = RxnString();
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;
  final availableItems = <Item>[].obs;

  LedgerController(this.repo);

  double oldDebit = 0;
  double oldCredit = 0;
  RxDouble totalSales = 0.0.obs;
  RxDouble totalReceivables = 0.0.obs;
  RxList<Item> lowStockItems = <Item>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
    fetchLedgers();
    loadRecentSearches();
    fetchItems();

    ever<String>(searchQuery, (_) => filterLedgers());
    ever<List<Ledger>>(ledgers, (_) => filterLedgers());
    creditController.addListener(_onAmountOrAccountChanged);
    debitController.addListener(_onAmountOrAccountChanged);
    accountIdController.addListener(_onAmountOrAccountChanged);
    // Get total sales
  }

  Future<void> getStats() async {
    totalSales.value = await DBHelper().getTotalSales();

    // Get total receivables
    totalReceivables.value = await DBHelper().getTotalReceivables();

    // Get low stock items
    lowStockItems.value = await DBHelper().getTopThreeLowestStockItems();
  }

  Future<void> refreshItems() async {
    await fetchItems();
    update(); // Notify listeners
  }

  Future<void> addNewEntryForm(String ledgerNo) async {
    await fetchItems(); // Ensure items are loaded before creating the form

    final parentLedger = ledgers.firstWhere(
      (l) => l.ledgerNo == ledgerNo,
      orElse: () => throw Exception('Ledger with number $ledgerNo not found'),
    );
    final newForm = EntryFormData();
    newForm.ledgerNoController.text = ledgerNo;
    newForm.accountNameController.text = parentLedger.accountName;
    newForm.accountIdController.text = parentLedger.accountId?.toString() ?? '';
    newForm.selectedDate.value = DateTime.now();
    newForm.originalEntry = null;
    newForm.currentStep.value = 0;
    newForm.selectedItem.value = null; // Explicitly set to null

    // Ensure _sharedVoucherNo is set for all forms in the same session
    if (_sharedVoucherNo == null) {
      String voucherNo;
      if (_nextVoucherNums.containsKey(ledgerNo)) {
        final num = _nextVoucherNums[ledgerNo]!;
        voucherNo = 'VN${num.toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] = num + 1; // Increment for next session
      } else {
        final lastVoucherNo = await repo.getLastVoucherNo(ledgerNo);
        final regex = RegExp(r'VN(\d+)');
        final match = regex.firstMatch(lastVoucherNo);
        int maxNum = 0;
        if (match != null) {
          maxNum = int.tryParse(match.group(1)!) ?? 0;
        }
        final num = maxNum + 1;
        voucherNo = 'VN${num.toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] =
            num + 1; // Initialize and increment for next session
      }
      _sharedVoucherNo = voucherNo; // Set the shared voucher number
    }
    newForm.voucherNoController.text = _sharedVoucherNo!; // Safe to use now

    newForm.transactionType.value = "Debit";
    newForm.transactionTypeController.text = "Debit";
    newForm.status.value = "Debit";
    newForm.statusController.text = "Debit";

    await newForm._initPreviousBalance();
    entryForms.add(newForm);

    // Add listeners for auto-negative sign
    newForm.creditController.addListener(
      () => _handleInputSign(
        newForm.creditController,
        newForm.transactionType.value == "Debit",
      ),
    );
    newForm.debitController.addListener(
      () => _handleInputSign(
        newForm.debitController,
        newForm.transactionType.value == "Credit",
      ),
    );
  }

  void _handleInputSign(TextEditingController controller, bool shouldNegative) {
    if (!shouldNegative) return;
    String text = controller.text;
    if (text.isNotEmpty && !text.startsWith('-') && text != '0') {
      final newText = '-$text';
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  Future<void> selectDateForForm(BuildContext context, int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entryForms[index].selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      entryForms[index].selectedDate.value = picked;
    }
  }

  Future<void> fetchItems() async {
    final items = await inventoryRepo.getAllItems();
    availableItems.assignAll(items);
  }

  void ensureSelectedItemIsAvailable() {
    // This is now per form, but since shared items, no need
  }

  // ========== STOCK MANAGEMENT METHODS (WEIGHT-BASED) ==========

  Future<void> updateItemStock(
    Item item,
    double weightChange,
    String transactionType,
  ) async {
    try {
      // Get the latest item data from database to ensure we have current stock
      final db = await DBHelper().database;
      final itemMap = await db.query(
        'item',
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (itemMap.isEmpty) throw Exception('Item not found');

      final currentItem = Item.fromMap(itemMap.first);

      final newStock = currentItem.availableStock + weightChange;

      if (newStock < 0) {
        throw Exception(
          'Insufficient stock for item ${item.name}. Available: ${currentItem.availableStock} kgs, Required: ${weightChange.abs()} kgs',
        );
      }

      // Create stock transaction record
      final stockTx = StockTransaction(
        itemId: item.id!,
        quantity: weightChange.abs(), // This should be double, not int
        type: transactionType,
        date: DateTime.now(),
      );

      await inventoryRepo.insertStockTransaction(stockTx);

      await fetchItems();

      // Verify the update worked
      final verifyMap = await db.query(
        'item',
        where: 'id = ?',
        whereArgs: [item.id],
      );
      Item.fromMap(verifyMap.first);
    } catch (e) {
      rethrow;
    }
  }

  double _calculateTotalWeight(LedgerEntry entry) {
    if (entry.cansQuantity == null || entry.canWeight == null) return 0.0;
    final totalWeight = entry.cansQuantity! * entry.canWeight!;
    return totalWeight;
  }

  Future<void> _handleItemStockForNewEntry(LedgerEntry newEntry) async {
    if (newEntry.itemId == null ||
        newEntry.cansQuantity == null ||
        newEntry.canWeight == null) {
      return;
    }
    final item = availableItems.firstWhere(
      (item) => item.id == newEntry.itemId,
      orElse: () => throw Exception('Item not found in availableItems'),
    );

    final weightChange = -_calculateTotalWeight(newEntry);

    await updateItemStock(item, weightChange, 'OUT');
  }

  Future<void> _handleItemStockForUpdatedEntry(
    LedgerEntry oldEntry,
    LedgerEntry newEntry,
  ) async {
    if (oldEntry.itemId == null && newEntry.itemId == null) {
      return;
    }

    // Case 1: Item was removed from the entry
    if (oldEntry.itemId != null && newEntry.itemId == null) {
      final oldItem = availableItems.firstWhere(
        (item) => item.id == oldEntry.itemId,
        orElse: () => throw Exception('Item not found'),
      );

      // Reverse the stock change from the old entry (add back)
      final oldWeight = _calculateTotalWeight(oldEntry);
      final reverseWeight = oldWeight;

      await updateItemStock(oldItem, reverseWeight, 'IN');
      return;
    }

    // Case 2: Item was added to the entry
    if (oldEntry.itemId == null && newEntry.itemId != null) {
      final newItem = availableItems.firstWhere(
        (item) => item.id == newEntry.itemId,
        orElse: () => throw Exception('Item not found'),
      );

      // Apply stock change for the new item (decrease)
      final newWeight = _calculateTotalWeight(newEntry);
      final weightChange = -newWeight;

      await updateItemStock(newItem, weightChange, 'OUT');
      return;
    }

    // Case 3: Item was changed or quantity/weight was modified
    if (oldEntry.itemId != null && newEntry.itemId != null) {
      // If item changed completely
      if (oldEntry.itemId != newEntry.itemId) {
        // Reverse stock for old item (add back)
        final oldItem = availableItems.firstWhere(
          (item) => item.id == oldEntry.itemId,
          orElse: () => throw Exception('Item not found'),
        );

        final oldWeight = _calculateTotalWeight(oldEntry);
        final reverseWeight = oldWeight;

        await updateItemStock(oldItem, reverseWeight, 'IN');

        // Apply stock for new item (decrease)
        final newItem = availableItems.firstWhere(
          (item) => item.id == newEntry.itemId,
          orElse: () => throw Exception('Item not found'),
        );

        final newWeight = _calculateTotalWeight(newEntry);
        final weightChange = -newWeight;

        await updateItemStock(newItem, weightChange, 'OUT');
      }
      // If same item but quantity or weight changed
      else if (oldEntry.cansQuantity != newEntry.cansQuantity ||
          oldEntry.canWeight != newEntry.canWeight) {
        final item = availableItems.firstWhere(
          (item) => item.id == newEntry.itemId,
          orElse: () => throw Exception('Item not found'),
        );

        // Calculate net change in weight
        final oldWeight = _calculateTotalWeight(oldEntry);
        final newWeight = _calculateTotalWeight(newEntry);

        final netChange = oldWeight - newWeight;
        if (netChange != 0) {
          final txType = netChange > 0 ? 'IN' : 'OUT';

          await updateItemStock(item, netChange, txType);
        }
      }
    }
  }

  Future<void> _handleItemStockForDeletedEntry(LedgerEntry entry) async {
    if (entry.itemId == null) {
      return;
    }

    final item = availableItems.firstWhere(
      (item) => item.id == entry.itemId,
      orElse: () => throw Exception('Item not found'),
    );

    // Reverse the stock change (add back)
    final entryWeight = _calculateTotalWeight(entry);
    final reverseWeight = entryWeight;

    await updateItemStock(item, reverseWeight, 'IN');
  }

  Future<bool> _validateStockAvailability(
    Item item,
    int cansQuantity,
    double canWeight,
  ) async {
    final requiredWeight = cansQuantity * canWeight;

    // Get the latest stock from database
    final db = await DBHelper().database;
    final itemMap = await db.query(
      'item',
      where: 'id = ?',
      whereArgs: [item.id],
    );

    if (itemMap.isEmpty) {
      return false;
    }

    final currentItem = Item.fromMap(itemMap.first);
    final isAvailable = currentItem.availableStock >= requiredWeight;

    return isAvailable;
  }

  Future<void> saveRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    recentSearches.remove(q);
    recentSearches.insert(0, q);
    if (recentSearches.length > 5) {
      recentSearches.removeRange(5, recentSearches.length);
    }
    await prefs.setStringList('recentSearches', recentSearches.toList());
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
  }

  Future<void> selectDate(BuildContext context, {bool isEntry = false}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isEntry ? selectedDate.value : selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isEntry) {
        selectedDate.value = picked;
      } else {
        selectedDate.value = picked;
      }
      if (isEntry) {
        _onAmountOrAccountChanged();
      } else {
        _onAmountOrAccountChanged();
      }
    }
  }

  Future<void> fetchLedgers() async {
    final data = await repo.getAllLedgers();
    ledgers.assignAll(data);
  }

  Future<void> fetchLedgerEntries(String ledgerNo) async {
    final data = await repo.getLedgerEntries(ledgerNo);
    ledgerEntries.assignAll(data);
    // filterLedgerEntries();
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.assignAll(prefs.getStringList('recentSearches') ?? []);
  }

  Future<void> deleteLedger(int id) async {
    final ledger = ledgers.firstWhere((l) => l.id == id);
    final aid = ledger.accountId;
    await repo.deleteLedger(id);
    if (aid != null) {
      await recalculateBalancesForAccount(aid);
    }
    await fetchLedgers();
  }

  Future<void> deleteLedgerEntry(int id, String ledgerNo) async {
    // Get the entry before deleting it
    final entry = ledgerEntries.firstWhere((e) => e.id == id);

    await repo.deleteLedgerEntry(id, ledgerNo);

    // Handle stock reversal for deleted entry
    await _handleItemStockForDeletedEntry(entry);

    final ledger = ledgers.firstWhere((l) => l.ledgerNo == ledgerNo);
    final aid = ledger.accountId;
    if (aid != null) {
      await recalculateBalancesForAccount(aid);
    }
    await updateLedgerTotals(ledgerNo);
    await fetchLedgerEntries(ledgerNo);
  }

  Future<void> updateLedgerTotals(String ledgerNo) async {
    final ledger = ledgers.firstWhere((l) => l.ledgerNo == ledgerNo);
    final entries = await repo.getLedgerEntries(ledgerNo);

    final totalDebit = entries.fold<double>(0.0, (sum, e) => sum + e.debit);
    final totalCredit = entries.fold<double>(0.0, (sum, e) => sum + e.credit);
    final newBalance = totalCredit; // Updated to sum of credits only

    final updatedLedger = Ledger(
      id: ledger.id,
      ledgerNo: ledger.ledgerNo,
      accountId: ledger.accountId,
      accountName: ledger.accountName,
      transactionType: ledger.transactionType,
      debit: totalDebit,
      credit: totalCredit,
      balance: newBalance,
      date: ledger.date,
      description: ledger.description,
      referenceNumber: ledger.referenceNumber,
      category: ledger.category,
      tags: ledger.tags,
      createdBy: ledger.createdBy,
      voucherNo: ledger.voucherNo,
      status: newBalance >= 0 ? "Debit" : "Credit",
      createdAt: ledger.createdAt,
      updatedAt: DateTime.now(),
    );

    await repo.updateLedger(updatedLedger);

    final index = ledgers.indexWhere((l) => l.id == ledger.id);
    if (index != -1) {
      ledgers[index] = updatedLedger;
    }
  }

  Future<void> loadLedgerNo({Ledger? ledger}) async {
    if (ledger == null) {
      clearForm(keepDate: true);
      final lastLedgerNo = await repo.getLedgerNo();
      ledgerNoController.text = lastLedgerNo;
      voucherNoController.text = await _generateVoucherNo();
      selectedDate.value = DateTime.now();
    } else {
      ledgerNoController.text = ledger.ledgerNo;
      voucherNoController.text = ledger.voucherNo;
      accountNameController.text = ledger.accountName;
      accountIdController.text = ledger.accountId?.toString() ?? '';
      transactionTypeController.text = ledger.transactionType;
      transactionType.value = ledger.transactionType;
      debitController.text = ledger.debit.toStringAsFixed(2);
      creditController.text = ledger.credit.toStringAsFixed(2);
      balanceController.text = ledger.balance.toStringAsFixed(2);
      descriptionController.text = ledger.description ?? '';
      referenceNumberController.text = ledger.referenceNumber ?? '';
      categoryController.text = ledger.category ?? '';
      tagsController.text = ledger.tags?.join(', ') ?? '';
      createdByController.text = ledger.createdBy ?? '';
      statusController.text = ledger.status;
      status.value = ledger.status;
      selectedDate.value = _toDateTime(ledger.date);
    }
  }

  Future<void> loadLedgerEntry({
    LedgerEntry? entry,
    required String ledgerNo,
  }) async {
    await fetchItems(); // Ensure items are loaded first

    final parentLedger = ledgers.firstWhere(
      (l) => l.ledgerNo == ledgerNo,
      orElse: () => throw Exception('Ledger with number $ledgerNo not found'),
    );

    entryForms.clear();
    _sharedVoucherNo = null; // Reset shared voucher number for single entry

    final newForm = EntryFormData();
    newForm.ledgerNoController.text = ledgerNo;
    newForm.accountNameController.text = parentLedger.accountName;
    newForm.accountIdController.text = parentLedger.accountId?.toString() ?? '';
    newForm.selectedDate.value = DateTime.now();
    newForm.currentStep.value = 0;

    if (entry != null) {
      // Existing logic for editing an entry
      newForm.originalEntry = entry;
      newForm.voucherNoController.text = entry.voucherNo;
      newForm.transactionType.value = entry.transactionType;
      newForm.transactionTypeController.text = entry.transactionType;
      newForm.debitController.text = entry.debit.toStringAsFixed(2);
      newForm.creditController.text = entry.credit.toStringAsFixed(2);
      newForm.balanceController.text = entry.balance.toStringAsFixed(2);
      newForm.descriptionController.text = entry.description ?? '';
      newForm.referenceNoController.text = entry.referenceNo ?? '';
      newForm.categoryController.text = entry.category ?? '';
      newForm.tagsController.text = entry.tags?.join(', ') ?? '';
      newForm.createdByController.text = entry.createdBy ?? '';
      newForm.status.value = entry.status;
      newForm.statusController.text = entry.status;
      newForm.selectedDate.value = entry.date;

      if (entry.itemId != null) {
        final item = availableItems.firstWhereOrNull(
          (item) => item.id == entry.itemId,
        );
        if (item != null) {
          newForm.selectedItem.value = item;
          newForm.itemIdController.text = entry.itemId.toString();
          newForm.itemNameController.text = entry.itemName ?? item.name;
          newForm.itemPriceController.text =
              (entry.itemPricePerUnit ?? item.pricePerKg).toStringAsFixed(2);
          newForm.canWeightController.text = (entry.canWeight ?? item.canWeight)
              .toStringAsFixed(2);
          newForm.cansQuantityController.text =
              entry.cansQuantity?.toString() ?? '0';
          newForm.sellingPriceController.text = (entry.sellingPricePerCan ?? 0)
              .toStringAsFixed(2);
          newForm.updateDescription();
          newForm._updateTotalWeight();
        } else {
          newForm.selectedItem.value = null; // Item not found, reset to null
        }
      } else {
        newForm.selectedItem.value = null;
      }
      _sharedVoucherNo =
          entry.voucherNo; // Set for consistency in case 'Add more' is used
    } else {
      newForm.originalEntry = null;
      newForm.transactionType.value = "Debit";
      newForm.transactionTypeController.text = "Debit";
      newForm.status.value = "Debit";
      newForm.statusController.text = "Debit";

      // Generate unique voucherNo for new single entry
      String voucherNo;
      if (_nextVoucherNums.containsKey(ledgerNo)) {
        final num = _nextVoucherNums[ledgerNo]!;
        voucherNo = 'VN${num.toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] = num + 1; // Increment for next session
      } else {
        final lastVoucherNo = await repo.getLastVoucherNo(ledgerNo);
        final regex = RegExp(r'VN(\d+)');
        final match = regex.firstMatch(lastVoucherNo);
        int maxNum = 0;
        if (match != null) {
          maxNum = int.tryParse(match.group(1)!) ?? 0;
        }
        final num = maxNum + 1;
        voucherNo = 'VN${num.toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] =
            num + 1; // Initialize and increment for next session
      }
      newForm.voucherNoController.text = voucherNo;
      _sharedVoucherNo =
          voucherNo; // Set for consistency in case 'Add more' is used
      newForm.selectedItem.value = null; // Ensure no stale item
    }

    await newForm._initPreviousBalance();
    entryForms.add(newForm);

    // Add listeners for auto-negative sign
    newForm.creditController.addListener(
      () => _handleInputSign(
        newForm.creditController,
        newForm.transactionType.value == "Debit",
      ),
    );
    newForm.debitController.addListener(
      () => _handleInputSign(
        newForm.debitController,
        newForm.transactionType.value == "Credit",
      ),
    );
  }

  Future<void> saveLedger(BuildContext context, {Ledger? ledger}) async {
    if (!formKey.currentState!.validate()) return;

    final parsedDebit = double.tryParse(debitController.text) ?? 0.0;
    final parsedCredit = double.tryParse(creditController.text) ?? 0.0;
    final parsedBalance = double.tryParse(balanceController.text) ?? 0.0;

    final newLedger = Ledger(
      id: ledger?.id,
      ledgerNo: ledgerNoController.text.toString().replaceAll('-', '_'),
      accountId: accountIdController.text.isNotEmpty
          ? int.parse(accountIdController.text)
          : null,
      accountName: accountNameController.text.toUpperCase(),
      transactionType: transactionType.value ?? transactionTypeController.text,
      debit: parsedDebit,
      credit: parsedCredit,
      date: selectedDate.value,
      description: descriptionController.text.isNotEmpty
          ? descriptionController.text
          : null,
      referenceNumber: referenceNumberController.text.isNotEmpty
          ? referenceNumberController.text
          : null,
      category: categoryController.text.isNotEmpty
          ? categoryController.text
          : null,
      tags: tagsController.text.isNotEmpty
          ? tagsController.text.split(',').map((t) => t.trim()).toList()
          : null,
      createdBy: createdByController.text.isNotEmpty
          ? createdByController.text
          : null,
      voucherNo: voucherNoController.text,
      balance: parsedBalance,
      status: status.value ?? statusController.text,
      createdAt: ledger?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    int? aid = newLedger.accountId;
    if (ledger != null) {
      oldDebit = ledger.debit;
      oldCredit = ledger.credit;
      await repo.updateLedger(newLedger);
    } else {
      await repo.insertLedger(newLedger);
      await repo.createLedgerEntryTable(newLedger.ledgerNo);
    }
    if (aid != null) {
      await recalculateBalancesForAccount(aid);
    }
    clearForm();
    await fetchLedgers();
    if (context.mounted) NavigationHelper.pop(context);
  }

  Future<List<ReceiptItem>> saveAllLedgerEntries(
    BuildContext context, {
    required String ledgerNo,
  }) async {
    List<LedgerEntry> savedEntries = [];

    try {
      // Ensure _sharedVoucherNo is set
      if (_sharedVoucherNo == null) {
        final lastVoucherNo = await repo.getLastVoucherNo(ledgerNo);
        final regex = RegExp(r'VN(\d+)');
        final match = regex.firstMatch(lastVoucherNo);
        int maxNum = 0;
        if (match != null) {
          maxNum = int.tryParse(match.group(1)!) ?? 0;
        }
        _sharedVoucherNo = 'VN${(maxNum + 1).toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] = maxNum + 2; // Update cache for next entry
      }

      for (int i = 0; i < entryForms.length; i++) {
        final formData = entryForms[i];
        if (!formData.step1FormKey.currentState!.validate() ||
            !formData.step2FormKey.currentState!.validate() ||
            !formData.step3FormKey.currentState!.validate()) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please fix validation errors in all forms'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return [];
        }

        // Validate item stock based on weight
        if (formData.selectedItem.value != null &&
            formData.cansQuantityController.text.isNotEmpty &&
            formData.canWeightController.text.isNotEmpty) {
          final quantity = int.parse(formData.cansQuantityController.text);
          final canWeight = double.parse(formData.canWeightController.text);

          if (!await _validateStockAvailability(
            formData.selectedItem.value!,
            quantity,
            canWeight,
          )) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Not enough stock in form ${i + 1}. Available: ${formData.selectedItem.value!.availableStock} kgs, Required: ${quantity * canWeight} kgs',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return [];
          }
        }

        // Use the shared voucher number for all forms
        formData.voucherNoController.text = _sharedVoucherNo!;

        final parsedDebit =
            double.tryParse(formData.debitController.text) ?? 0.0;
        final parsedCredit =
            double.tryParse(formData.creditController.text) ?? 0.0;
        final parsedBalance =
            double.tryParse(formData.balanceController.text) ?? 0.0;

        final newEntry = LedgerEntry(
          id: formData.originalEntry?.id,
          ledgerNo: formData.ledgerNoController.text,
          voucherNo: _sharedVoucherNo!, // Use shared voucher number
          accountId: formData.accountIdController.text.isNotEmpty
              ? int.parse(formData.accountIdController.text)
              : null,
          accountName: formData.accountNameController.text.toUpperCase(),
          date: formData.selectedDate.value,
          transactionType: formData.transactionType.value,
          debit: parsedDebit,
          credit: parsedCredit,
          balance: parsedBalance,
          status: formData.status.value,
          description: formData.descriptionController.text.isNotEmpty
              ? formData.descriptionController.text
              : null,
          referenceNo: formData.referenceNoController.text.isNotEmpty
              ? formData.referenceNoController.text
              : null,
          category: formData.categoryController.text.isNotEmpty
              ? formData.categoryController.text
              : null,
          tags: formData.tagsController.text.isNotEmpty
              ? formData.tagsController.text
                    .split(',')
                    .map((t) => t.trim())
                    .toList()
              : null,
          createdBy: formData.createdByController.text.isNotEmpty
              ? formData.createdByController.text
              : null,
          createdAt: formData.originalEntry?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
          itemId: formData.selectedItem.value?.id,
          itemName: formData.selectedItem.value?.name,
          itemPricePerUnit: double.tryParse(formData.itemPriceController.text),
          canWeight: double.tryParse(formData.canWeightController.text),
          cansQuantity: int.tryParse(formData.cansQuantityController.text),
          sellingPricePerCan: double.tryParse(
            formData.sellingPriceController.text,
          ),
          balanceCans:
              ((double.tryParse(formData.balanceCans.text) ??
                          0.0 +
                              double.tryParse(
                                formData.cansQuantityController.text,
                              )!) -
                      (double.tryParse(formData.receivedCans.text) ?? 0.0))
                  .toString(),
          receivedCans: formData.receivedCans.text.toString(),
        );

        if (formData.originalEntry == null) {
          // New entry
          await repo.insertLedgerEntry(newEntry, ledgerNo);
          await _handleItemStockForNewEntry(newEntry);
          await repo.updateLedgerDebtOrCred(
            parsedCredit == 0 || parsedCredit == 0.0 ? "debit" : "credit",
            ledgerNo,
            parsedCredit == 0 || parsedCredit == 0.0
                ? parsedDebit
                : parsedCredit,
          );
        } else {
          // Updated entry
          await _handleItemStockForUpdatedEntry(
            formData.originalEntry!,
            newEntry,
          );
          await repo.updateLedgerEntry(newEntry, ledgerNo);
        }

        savedEntries.add(newEntry);
      }

      // Convert saved LedgerEntries to ReceiptItems
      final List<ReceiptItem> receiptItems = savedEntries.map((entry) {
        // Calculate amount: Use sellingPricePerCan if available, else fall back to itemPricePerUnit
        final price = entry.sellingPricePerCan ?? entry.itemPricePerUnit ?? 0.0;
        final quantity = entry.cansQuantity ?? 0;
        final amount = price;

        return ReceiptItem(
          name: entry.itemName ?? 'Unknown Item',
          price: price,
          canQuantity: quantity,
          type: entry.transactionType,
          description: entry.description ?? 'No description',
          amount: amount,
        );
      }).toList();

      // All saved successfully
      final ledger = ledgers.firstWhere(
        (l) => l.ledgerNo == ledgerNo,
        orElse: () => throw Exception('Ledger with number $ledgerNo not found'),
      );
      final aid = ledger.accountId;
      if (aid != null) {
        await recalculateBalancesForAccount(aid);
      }

      await updateLedgerTotals(ledgerNo);
      await fetchLedgerEntries(ledgerNo);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${savedEntries.length} ledger ${savedEntries.length == 1 ? 'entry' : 'entries'} saved successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      return receiptItems;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entries: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return [];
    } finally {
      // Clear _sharedVoucherNo and _nextVoucherNums to avoid stale voucher numbers
      _sharedVoucherNo = null;
      _nextVoucherNums.clear();
      entryForms.clear();
    }
  }

  Future<double> getLastBalanceForAccount(int? aid) async {
    if (aid == null) return 0.0;
    List<TransactionItem> trans = [];
    var ledgersForAccount = ledgers.where((l) => l.accountId == aid).toList();
    for (var l in ledgersForAccount) {
      trans.add(
        TransactionItem(
          id: l.id!,
          type: 'ledger',
          ledgerNo: l.ledgerNo,
          date: _toDateTime(l.date),
          debit: l.debit,
          credit: l.credit,
          balance: l.balance,
          status: l.status,
        ),
      );
      var entries = await repo.getLedgerEntries(l.ledgerNo);
      for (var e in entries) {
        trans.add(
          TransactionItem(
            id: e.id!,
            type: 'entry',
            ledgerNo: l.ledgerNo,
            date: e.date,
            debit: e.debit,
            credit: e.credit,
            balance: e.balance,
            status: e.status,
          ),
        );
      }
    }
    if (trans.isEmpty) return 0.0;
    trans.sort((a, b) => a.date.compareTo(b.date));
    return trans.last.balance;
  }

  Future<void> _onAmountOrAccountChanged() async {
    double previous = await getLastBalanceForAccount(
      int.tryParse(accountIdController.text),
    );
    double.tryParse(debitController.text) ?? 0.0;
    final credit = double.tryParse(creditController.text) ?? 0.0;
    final newBalance = previous + credit; // Updated to accumulate credits only
    balanceController.text = newBalance.toStringAsFixed(2);
    status.value = newBalance > 0 ? 'Debit' : 'Credit';
    statusController.text = status.value ?? '';
  }

  Future<void> recalculateBalancesForAccount(int aid) async {
    List<TransactionItem> trans = [];
    var ledgersForAccount = ledgers.where((l) => l.accountId == aid).toList();

    Map<int, Ledger> ledgerMap = {for (var l in ledgersForAccount) l.id!: l};
    Map<int, LedgerEntry> entryMap = {};

    for (var l in ledgersForAccount) {
      trans.add(
        TransactionItem(
          id: l.id!,
          type: 'ledger',
          ledgerNo: l.ledgerNo,
          date: _toDateTime(l.date),
          debit: l.debit,
          credit: l.credit,
          balance: l.balance,
          status: l.status,
        ),
      );
      var entries = await repo.getLedgerEntries(l.ledgerNo);
      for (var e in entries) {
        entryMap[e.id!] = e;
        trans.add(
          TransactionItem(
            id: e.id!,
            type: 'entry',
            ledgerNo: l.ledgerNo,
            date: e.date,
            debit: e.debit,
            credit: e.credit,
            balance: e.balance,
            status: e.status,
          ),
        );
      }
    }
    if (trans.isEmpty) return;
    trans.sort((a, b) => a.date.compareTo(b.date));
    double currentBalance = 0.0; // Start from 0 for first row
    for (var t in trans) {
      currentBalance += t.credit; // Accumulate only credits
      t.balance = currentBalance;
      t.status = currentBalance > 0 ? 'Debit' : 'Credit';
    }
    for (var t in trans) {
      if (t.type == 'ledger') {
        final original = ledgerMap[t.id]!;
        final updatedLedger = Ledger(
          id: original.id,
          ledgerNo: original.ledgerNo,
          accountId: aid,
          accountName: original.accountName,
          transactionType: original.transactionType,
          debit: t.debit,
          credit: t.credit,
          date: t.date,
          description: original.description,
          referenceNumber: original.referenceNumber,
          category: original.category,
          tags: original.tags,
          createdBy: original.createdBy,
          voucherNo: original.voucherNo,
          balance: t.balance,
          status: t.status,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
        );
        await repo.updateLedger(updatedLedger);
      } else {
        final original = entryMap[t.id]!;
        final updatedEntry = LedgerEntry(
          id: original.id,
          ledgerNo: original.ledgerNo,
          voucherNo: original.voucherNo,
          accountId: aid,
          accountName: original.accountName,
          date: t.date,
          transactionType: original.transactionType,
          debit: t.debit,
          credit: t.credit,
          balance: t.balance,
          status: t.status,
          description: original.description,
          referenceNo: original.referenceNo,
          category: original.category,
          tags: original.tags,
          createdBy: original.createdBy,
          createdAt: original.createdAt,
          updatedAt: DateTime.now(),
          // Item fields
          itemId: original.itemId,
          itemName: original.itemName,
          itemPricePerUnit: original.itemPricePerUnit,
          canWeight: original.canWeight,
          cansQuantity: original.cansQuantity,
          sellingPricePerCan: original.sellingPricePerCan,
          balanceCans: original.balanceCans.toString(),
          receivedCans: original.receivedCans.toString(),
        );
        await repo.updateLedgerEntry(updatedEntry, t.ledgerNo);
      }
    }
    await fetchLedgers();
  }

  Future<String> _generateVoucherNo({
    bool isEntry = false,
    String? ledgerNo,
  }) async {
    if (isEntry && ledgerNo == null) {
      throw Exception('ledgerNo must be provided when isEntry is true');
    }

    final regex = RegExp(r'VN(\d+)');
    int max = 0;

    // Check in-memory voucher numbers
    final source = isEntry ? ledgerEntries : ledgers;
    for (final item in source) {
      final voucherNo = isEntry
          ? (item as LedgerEntry).voucherNo
          : (item as Ledger).voucherNo;
      final match = regex.firstMatch(voucherNo);
      if (match != null) {
        final number = int.tryParse(match.group(1)!) ?? 0;
        if (number > max) max = number;
      }
    }

    // For ledger entries, also check the database
    if (isEntry) {
      final lastVoucherNo = await repo.getLastVoucherNo(ledgerNo!);
      final match = regex.firstMatch(lastVoucherNo);
      if (match != null) {
        final number = int.tryParse(match.group(1)!) ?? 0;
        if (number > max) max = number;
      }
    }

    // Return the next voucher number with leading zeros
    final result = 'VN${(max + 1).toString().padLeft(2, '0')}';
    return result;
  }

  void clearForm({bool keepDate = false}) {
    ledgerNoController.clear();
    voucherNoController.clear();
    accountNameController.clear();
    accountIdController.clear();
    transactionTypeController.clear();
    debitController.clear();
    creditController.clear();
    balanceController.clear();
    descriptionController.clear();
    referenceNumberController.clear();
    categoryController.clear();
    tagsController.clear();
    createdByController.clear();
    statusController.clear();
    transactionType.value = null;
    status.value = null;
    if (!keepDate) {
      selectedDate.value = DateTime.now();
    }
  }

  void filterLedgers() {
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isEmpty) {
      filteredLedgers.assignAll(ledgers);
      return;
    }

    filteredLedgers.assignAll(
      ledgers.where((ledger) {
        final ledgerNoStr = ledger.ledgerNo.toLowerCase();
        final voucherNoStr = ledger.voucherNo.toLowerCase();
        final accountIdStr = ledger.accountId?.toString().toLowerCase() ?? '';
        final accountNameStr = ledger.accountName.toLowerCase();
        final typeStr = ledger.transactionType.toLowerCase();
        final dateStr = formatDate(ledger.date).toLowerCase();
        final descStr = ledger.description?.toLowerCase() ?? '';
        final refStr = ledger.referenceNumber?.toLowerCase() ?? '';
        final tagsMatch =
            ledger.tags?.any((tag) => tag.toLowerCase().contains(query)) ??
            false;

        return ledgerNoStr.contains(query) ||
            voucherNoStr.contains(query) ||
            accountIdStr.contains(query) ||
            accountNameStr.contains(query) ||
            typeStr.contains(query) ||
            dateStr.contains(query) ||
            descStr.contains(query) ||
            refStr.contains(query) ||
            tagsMatch;
      }),
    );
  }

  @override
  void onClose() {
    ledgerNoController.dispose();
    voucherNoController.dispose();
    accountNameController.dispose();
    accountIdController.dispose();
    transactionTypeController.dispose();
    debitController.dispose();
    creditController.dispose();
    balanceController.dispose();
    descriptionController.dispose();
    referenceNumberController.dispose();
    categoryController.dispose();
    tagsController.dispose();
    createdByController.dispose();
    statusController.dispose();
    for (var form in entryForms) {
      form.dispose();
    }
    entryForms.clear();
    _nextVoucherNums.clear();
    _sharedVoucherNo = null; // Clear shared voucher number
    super.onClose();
  }

  DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final s = value.trim();
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;
      final fmts = <DateFormat>[
        DateFormat('dd-MM-yyyy'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM-dd-yyyy'),
        DateFormat('MM/dd/yyyy'),
        DateFormat('yyyy-MM-dd'),
        DateFormat('yyyy/MM/dd'),
      ];
      for (final f in fmts) {
        try {
          return f.parseStrict(s);
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  String formatDate(dynamic value, {String pattern = 'dd-MM-yyyy'}) {
    final dt = _toDateTime(value);
    return DateFormat(pattern).format(dt);
  }
}

class LedgerEntryAddEdit extends StatelessWidget {
  final String ledgerNo;
  final String accountId;
  final String accountName;
  final LedgerEntry? entry;
  final VoidCallback? onEntrySaved;

  const LedgerEntryAddEdit({
    super.key,
    required this.ledgerNo,
    this.entry,
    required this.accountId,
    required this.accountName,
    this.onEntrySaved,
  });

  @override
  Widget build(BuildContext context) {
    final LedgerController controller = Get.find<LedgerController>();
    final LedgerTableController ledgerTableController =
        Get.find<LedgerTableController>();
    final ScrollController scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntry(entry: entry, ledgerNo: ledgerNo);
      scrollController.jumpTo(0);
    });

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Obx(
      () => BaseLayout(
        showBackButton: true,
        appBarTitle: entry == null ? 'Add Ledger Entry' : 'Edit Ledger Entry',
        child: SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ...List.generate(controller.entryForms.length, (index) {
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.2),
                                (Theme.of(context).cardTheme.color ??
                                        Theme.of(context).colorScheme.surface)
                                    .withValues(alpha: 1),
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
                          child: buildForm(
                            index,
                            isDesktop,
                            controller,
                            context,
                            scrollController,
                          ),
                        ),
                        if (controller.entryForms.length > 1)
                          Positioned(
                            top: 16,
                            right: 0,
                            child: IconButton(
                              tooltip: "Remove entry",
                              icon: Icon(Icons.clear, color: Colors.red),
                              onPressed: () {
                                controller.entryForms.removeAt(index);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await controller.addNewEntryForm(ledgerNo);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          scrollController.animateTo(
                            scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        });
                      },
                      child: Text(
                        'Add more',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {
                        NavigationHelper.pop(context);
                        controller.entryForms.clear();
                        controller._nextVoucherNums.clear();
                        scrollController.dispose();
                      },
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        bool allValid = true;
                        for (var formData in controller.entryForms) {
                          // Validate Step 1
                          if (formData.step1FormKey.currentState != null &&
                              !formData.step1FormKey.currentState!.validate()) {
                            allValid = false;
                            _requestFocusForInvalidFieldStep1(
                              formData,
                              context,
                            );
                            continue;
                          }
                          // Validate Step 2
                          if (formData.step2FormKey.currentState != null &&
                              !formData.step2FormKey.currentState!.validate()) {
                            allValid = false;
                            _requestFocusForInvalidFieldStep2(
                              formData,
                              context,
                            );
                            continue;
                          }
                          // Validate Step 3
                          if (formData.step3FormKey.currentState != null &&
                              !formData.step3FormKey.currentState!.validate()) {
                            allValid = false;
                            _requestFocusForInvalidFieldStep3(
                              formData,
                              context,
                            );
                            continue;
                          }
                        }
                        if (allValid) {
                          final entries = await controller.saveAllLedgerEntries(
                            context,
                            ledgerNo: ledgerNo,
                          );
                          ledgerTableController.loadLedgerEntries(ledgerNo);
                          showPrintReceiptDialog(context, entries);
                          if (onEntrySaved != null) {
                            onEntrySaved!();
                          }
                          scrollController.dispose();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).iconTheme.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        controller.entryForms.length > 1 ? 'Save All' : 'Save',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _requestFocusForInvalidFieldStep1(
    EntryFormData formData,
    BuildContext context,
  ) {
    if (formData.ledgerNoController.text.isEmpty) {
      formData.ledgerNoFocusNode.requestFocus();
    } else if (formData.voucherNoController.text.isEmpty) {
      formData.voucherNoFocusNode.requestFocus();
    } else if (formData.accountNameController.text.isEmpty) {
      formData.accountNameFocusNode.requestFocus();
    } else if (formData.accountIdController.text.isEmpty) {
      formData.accountIdFocusNode.requestFocus();
    } else if (formData.transactionType.value.isEmpty) {
      formData.transactionTypeFocusNode.requestFocus();
    }
  }

  void _requestFocusForInvalidFieldStep2(
    EntryFormData formData,
    BuildContext context,
  ) {
    if (formData.selectedItem.value == null) {
      formData.itemFocusNode.requestFocus();
    } else if (formData.cansQuantityController.text.isEmpty) {
      formData.cansQuantityFocusNode.requestFocus();
    } else if (formData.itemPriceController.text.isEmpty) {
      formData.itemPriceFocusNode.requestFocus();
    } else if (formData.canWeightController.text.isEmpty) {
      formData.canWeightFocusNode.requestFocus();
    } else if (formData.sellingPriceController.text.isEmpty) {
      formData.sellingPriceFocusNode.requestFocus();
    } else if (formData.totalWeightController.text.isEmpty) {
      formData.totalWeightFocusNode.requestFocus();
    } else if (formData.balanceCans.text.isEmpty) {
      formData.balanceCansFocusNode.requestFocus();
    } else if (formData.receivedCans.text.isEmpty) {
      formData.receivedCansFocusNode.requestFocus();
    }
  }

  void _requestFocusForInvalidFieldStep3(
    EntryFormData formData,
    BuildContext context,
  ) {
    if (formData.debitController.text.isEmpty ||
        double.tryParse(formData.debitController.text) == null) {
      formData.debitFocusNode.requestFocus();
    } else if (formData.creditController.text.isEmpty ||
        double.tryParse(formData.creditController.text) == null) {
      formData.creditFocusNode.requestFocus();
    } else if (formData.balanceController.text.isEmpty) {
      formData.balanceFocusNode.requestFocus();
    } else if (formData.status.value.isEmpty) {
      formData.statusFocusNode.requestFocus();
    } else if (formData.descriptionController.text.isEmpty) {
      formData.descriptionFocusNode.requestFocus();
    } else if (formData.createdByController.text.isEmpty) {
      formData.createdByFocusNode.requestFocus();
    }
  }

  void showPrintReceiptDialog(BuildContext context, List<ReceiptItem> entries) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String vehicleNumber = '';
        bool askPrint = true;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Print Receipt',
                style: TextStyle(color: Colors.white),
              ),
              content: askPrint
                  ? Text(
                      'Do you want to print the receipt?',
                      style: TextStyle(color: Colors.white),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Vehicle Number',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              vehicleNumber = val;
                            });
                          },
                        ),
                      ],
                    ),
              actions: [
                if (askPrint)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        askPrint = false;
                      });
                    },
                    child: Text('Yes', style: TextStyle(color: Colors.blue)),
                  ),
                if (askPrint)
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'No',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                if (!askPrint)
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      NavigationHelper.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                if (!askPrint)
                  TextButton(
                    onPressed: vehicleNumber.trim().isEmpty
                        ? null
                        : () {
                            printEntry(entries, vehicleNumber, context);
                          },
                    child: Text('Print', style: TextStyle(color: Colors.green)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> printEntry(
    List<ReceiptItem> items,
    String vehicleNo,
    BuildContext context,
  ) async {
    final ledgerTableController = Get.find<LedgerTableController>();
    final ledgerController = Get.find<LedgerController>();
    final customerController = Get.find<CustomerController>();

    double currentAmount = 0.0;
    double currentCans = 0.0;
    double receivedCans = 0.0;

    var customer = await customerController.repo.getCustomer(
      accountId.toString(),
    );

    for (var i = 0; i < items.length; i++) {
      final entryIndex =
          ledgerTableController.filteredLedgerEntries.length - 1 - i;
      final entry =
          ledgerTableController.filteredLedgerEntries[entryIndex.toInt()];

      currentAmount += safeParseDouble(
        entry.credit > 0 ? entry.credit.toString() : entry.debit.toString(),
      );

      currentCans += safeParseDouble(entry.cansQuantity ?? '0');
      receivedCans += safeParseDouble(entry.receivedCans ?? '0');
    }

    final previousCans = safeParseDouble(
      ledgerTableController.balanceCans + receivedCans - currentCans,
    );

    final balanceCans = (previousCans + currentCans) - receivedCans;

    int prevIndex =
        ledgerTableController.filteredLedgerEntries.length - 1 - items.length;

    double previousAmount = 0.0;
    if (prevIndex >= 0 &&
        prevIndex < ledgerTableController.filteredLedgerEntries.length) {
      previousAmount =
          ledgerTableController.filteredLedgerEntries[prevIndex].balance;
    }

    final data = ReceiptData(
      companyName: 'NAZ ENTERPRISES',
      date: DateFormat(
        'dd/MM/yyyy',
      ).format(ledgerTableController.filteredLedgerEntries.last.date),
      customerName: accountName,
      customerAddress: customer?.address ?? '',
      vehicleNumber: vehicleNo,
      voucherNumber: ledgerTableController.filteredLedgerEntries.last.voucherNo,
      items: items,
      previousCans: previousCans,
      currentCans: currentCans,
      totalCans: safeParseDouble(ledgerTableController.balanceCans),
      receivedCans: receivedCans,
      balanceCans: balanceCans,
      currentAmount: currentAmount,
      previousAmount: previousAmount,
      netBalance: getNetBalance(ledgerTableController, ledgerController),
    );

    await ReceiptPdfGenerator.generateAndPrint(data).then((value) {
      Navigator.of(context).pop();
      NavigationHelper.pop(context);
    });
  }

  double getNetBalance(
    LedgerTableController ledgerTableController,
    LedgerController ledgerController,
  ) {
    if (ledgerTableController.filteredLedgerEntries.isEmpty) {
      return 0.0;
    }

    final allEntries = ledgerController.ledgerEntries;

    if (allEntries.isEmpty) {
      return 0.0;
    }

    allEntries.sort((a, b) => b.date.compareTo(a.date));

    return allEntries.first.balance;
  }

  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }

  int safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    final str = value.toString().trim();
    if (str.isEmpty) return 0;
    return int.tryParse(str) ?? (double.tryParse(str)?.toInt() ?? 0);
  }

  Widget buildForm(
    int index,
    bool isDesktop,
    LedgerController controller,
    BuildContext context,
    ScrollController scrollController,
  ) {
    final formData = controller.entryForms[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Information
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: formData.step1FormKey,
          child: buildStepFields(
            index,
            1,
            isDesktop,
            controller,
            context,
            scrollController,
          ),
        ),
        const Divider(height: 32),
        // Item Details
        Text(
          'Item Details',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: formData.step2FormKey,
          child: buildStepFields(
            index,
            2,
            isDesktop,
            controller,
            context,
            scrollController,
          ),
        ),
        const Divider(height: 32),
        // Financial Details
        Text(
          'Financial Details',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: formData.step3FormKey,
          child: buildStepFields(
            index,
            3,
            isDesktop,
            controller,
            context,
            scrollController,
          ),
        ),
      ],
    );
  }

  Widget buildStepFields(
    int index,
    int stepNum,
    bool isDesktop,
    LedgerController controller,
    BuildContext context,
    ScrollController scrollController,
  ) {
    final formData = controller.entryForms[index];

    if (stepNum == 1) {
      if (isDesktop) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.ledgerNoController,
                    focusNode: formData.ledgerNoFocusNode,
                    label: 'Ledger No',
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Ledger No is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.voucherNoController,
                    focusNode: formData.voucherNoFocusNode,
                    label: 'Voucher No',
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Voucher No is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.accountNameController,
                    focusNode: formData.accountNameFocusNode,
                    label: 'Account Name',
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Account Name is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.accountIdController,
                    focusNode: formData.accountIdFocusNode,
                    label: 'Account ID',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Account ID is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: formData.transactionType.value.isNotEmpty
                        ? formData.transactionType.value
                        : null,
                    focusNode: formData.transactionTypeFocusNode,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Transaction Type',
                      labelStyle: Theme.of(context).textTheme.bodySmall!
                          .copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const ['Debit', 'Credit']
                        .map(
                          (t) => DropdownMenuItem<String>(
                            value: t,
                            child: Text(t),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      formData.transactionType.value = value!;
                      formData.transactionTypeController.text = value;
                      formData.status.value = value;
                      formData.statusController.text = value;
                      formData._updateBalance();
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Transaction Type is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    focusNode: formData.dateFocusNode,
                    onTap: () => controller.selectDateForForm(context, index),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: Theme.of(context).textTheme.bodySmall!
                            .copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                      ),
                      child: Text(
                        DateFormat(
                          'dd-MM-yyyy',
                        ).format(formData.selectedDate.value),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        return Column(
          children: [
            _buildTextField(
              context: context,
              controller: formData.ledgerNoController,
              focusNode: formData.ledgerNoFocusNode,
              label: 'Ledger No',
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Ledger No is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.voucherNoController,
              focusNode: formData.voucherNoFocusNode,
              label: 'Voucher No',
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Voucher No is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.accountNameController,
              focusNode: formData.accountNameFocusNode,
              label: 'Account Name',
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Account Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.accountIdController,
              focusNode: formData.accountIdFocusNode,
              label: 'Account ID',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Account ID is required'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formData.transactionType.value.isNotEmpty
                  ? formData.transactionType.value
                  : null,
              focusNode: formData.transactionTypeFocusNode,
              style: Theme.of(context).textTheme.bodySmall,
              decoration: InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const ['Debit', 'Credit']
                  .map(
                    (t) => DropdownMenuItem<String>(value: t, child: Text(t)),
                  )
                  .toList(),
              onChanged: (value) {
                formData.transactionType.value = value!;
                formData.transactionTypeController.text = value;
                formData.status.value = value;
                formData.statusController.text = value;
                formData._updateBalance();
              },
              validator: (value) => value == null || value.isEmpty
                  ? 'Transaction Type is required'
                  : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              focusNode: formData.dateFocusNode,
              onTap: () => controller.selectDateForForm(context, index),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  DateFormat('dd-MM-yyyy').format(formData.selectedDate.value),
                ),
              ),
            ),
          ],
        );
      }
    } else if (stepNum == 2) {
      if (isDesktop) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Obx(() {
                    Item? selectedItem = formData.selectedItem.value != null
                        ? controller.availableItems.firstWhereOrNull(
                            (item) =>
                                item.id == formData.selectedItem.value!.id,
                          )
                        : null;

                    return DropdownButtonFormField<Item>(
                      initialValue: selectedItem,
                      focusNode: formData.itemFocusNode,
                      style: Theme.of(context).textTheme.bodySmall,
                      decoration: InputDecoration(
                        labelText: 'Item',
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: controller.availableItems
                          .map(
                            (item) => DropdownMenuItem<Item>(
                              value: item,
                              child: Text(
                                '${item.name} (Stock: ${item.availableStock})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (item) {
                        formData.selectedItem.value = item;
                        if (item != null) {
                          formData.itemIdController.text = item.id.toString();
                          formData.itemNameController.text = item.name;
                          formData.itemPriceController.text = item.pricePerKg
                              .toStringAsFixed(2);
                          formData.canWeightController.text = item.canWeight
                              .toStringAsFixed(2);
                          formData.updateDescription();
                          formData._updateTotalWeight();
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Item is required' : null,
                    );
                  }),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.cansQuantityController,
                    focusNode: formData.cansQuantityFocusNode,
                    label: 'Cans Quantity',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Cans Quantity is required';
                      }
                      if (formData.selectedItem.value != null) {
                        final quantity = int.tryParse(value) ?? 0;
                        final canWeight =
                            double.tryParse(
                              formData.canWeightController.text,
                            ) ??
                            0;
                        final totalWeight = quantity * canWeight;
                        if (totalWeight >
                            formData.selectedItem.value!.availableStock) {
                          return 'Not enough stock. Available: ${formData.selectedItem.value!.availableStock}';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.itemPriceController,
                    focusNode: formData.itemPriceFocusNode,
                    label: 'Price per Kg/L',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Price per Kg/L is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.canWeightController,
                    focusNode: formData.canWeightFocusNode,
                    label: 'Can Weight (Kg/L)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Can Weight is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.sellingPriceController,
                    focusNode: formData.sellingPriceFocusNode,
                    label: 'Selling Price',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selling Price is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTotalWeightField(
                    controller: formData.totalWeightController,
                    focusNode: formData.totalWeightFocusNode,
                    context: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.balanceCans,
                    focusNode: formData.balanceCansFocusNode,
                    label: 'Balance Cans',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Balance Cans is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.receivedCans,
                    focusNode: formData.receivedCansFocusNode,
                    label: 'Received Cans',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    readOnly: false,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Received Cans is required'
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        return Column(
          children: [
            Obx(() {
              Item? selectedItem = formData.selectedItem.value != null
                  ? controller.availableItems.firstWhereOrNull(
                      (item) => item.id == formData.selectedItem.value!.id,
                    )
                  : null;

              return DropdownButtonFormField<Item>(
                initialValue: selectedItem,
                focusNode: formData.itemFocusNode,
                style: Theme.of(context).textTheme.bodySmall,
                decoration: InputDecoration(
                  labelText: 'Item',
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: controller.availableItems
                    .map(
                      (item) => DropdownMenuItem<Item>(
                        value: item,
                        child: Text(
                          '${item.name} (Stock: ${item.availableStock})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (item) {
                  formData.selectedItem.value = item;
                  if (item != null) {
                    formData.itemIdController.text = item.id.toString();
                    formData.itemNameController.text = item.name;
                    formData.itemPriceController.text = item.pricePerKg
                        .toStringAsFixed(2);
                    formData.canWeightController.text = item.canWeight
                        .toStringAsFixed(2);
                    formData.updateDescription();
                    formData._updateTotalWeight();
                  }
                },
                validator: (value) => value == null ? 'Item is required' : null,
              );
            }),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.cansQuantityController,
              focusNode: formData.cansQuantityFocusNode,
              label: 'Cans Quantity',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Cans Quantity is required';
                }
                if (formData.selectedItem.value != null) {
                  final quantity = int.tryParse(value) ?? 0;
                  final canWeight =
                      double.tryParse(formData.canWeightController.text) ?? 0;
                  final totalWeight = quantity * canWeight;
                  if (totalWeight >
                      formData.selectedItem.value!.availableStock) {
                    return 'Not enough stock. Available: ${formData.selectedItem.value!.availableStock}';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.itemPriceController,
              focusNode: formData.itemPriceFocusNode,
              label: 'Price per Kg/L',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Price per Kg/L is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.canWeightController,
              focusNode: formData.canWeightFocusNode,
              label: 'Can Weight (Kg/L)',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) => value == null || value.isEmpty
                  ? 'Can Weight is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.sellingPriceController,
              focusNode: formData.sellingPriceFocusNode,
              label: 'Selling Price',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Selling Price is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTotalWeightField(
              controller: formData.totalWeightController,
              focusNode: formData.totalWeightFocusNode,
              context: context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.balanceCans,
              focusNode: formData.balanceCansFocusNode,
              label: 'Balance Cans',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Balance Cans is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: formData.receivedCans,
              focusNode: formData.receivedCansFocusNode,
              label: 'Received Cans',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              readOnly: false,
              validator: (value) => value == null || value.isEmpty
                  ? 'Received Cans is required'
                  : null,
            ),
          ],
        );
      }
    } else {
      if (isDesktop) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.debitController,
                    focusNode: formData.debitFocusNode,
                    label: 'Debit',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Debit is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.creditController,
                    focusNode: formData.creditFocusNode,
                    label: 'Credit',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*'),
                      ),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Credit is required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.balanceController,
                    focusNode: formData.balanceFocusNode,
                    label: 'Balance',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Balance is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: formData.status.value.isNotEmpty
                        ? formData.status.value
                        : null,
                    focusNode: formData.statusFocusNode,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const ['Debit', 'Credit']
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: null,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Status is required'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.descriptionController,
                    focusNode: formData.descriptionFocusNode,
                    label: 'Description',
                    readOnly: true,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Description is required'
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.referenceNoController,
                    focusNode: formData.referenceNoFocusNode,
                    label: 'Ref',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.categoryController,
                    focusNode: formData.categoryFocusNode,
                    label: 'Category',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context: context,
                    controller: formData.createdByController,
                    focusNode: formData.createdByFocusNode,
                    label: 'Created By',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Created By is required'
                        : null,
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        return Column(
          children: [
            _buildTextField(
              controller: formData.debitController,
              focusNode: formData.debitFocusNode,
              context: context,
              label: 'Debit',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Debit is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: formData.creditController,
              focusNode: formData.creditFocusNode,
              label: 'Credit',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
              ],
              context: context,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Credit is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: formData.balanceController,
              focusNode: formData.balanceFocusNode,
              context: context,
              label: 'Balance',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              readOnly: true,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Balance is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: formData.status.value.isNotEmpty
                  ? formData.status.value
                  : null,
              focusNode: formData.statusFocusNode,
              style: Theme.of(context).textTheme.bodySmall,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const ['Debit', 'Credit']
                  .map(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                  )
                  .toList(),
              onChanged: null,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Status is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: formData.descriptionController,
              focusNode: formData.descriptionFocusNode,
              label: 'Description',
              readOnly: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Description is required'
                  : null,
              context: context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: formData.referenceNoController,
              focusNode: formData.referenceNoFocusNode,
              label: 'Ref',
              context: context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: formData.categoryController,
              focusNode: formData.categoryFocusNode,
              label: 'Category',
              context: context,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: formData.createdByController,
              focusNode: formData.createdByFocusNode,
              label: 'Created By',
              validator: (value) => value == null || value.isEmpty
                  ? 'Created By is required'
                  : null,
              context: context,
            ),
          ],
        );
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      validator: validator,
      style: Theme.of(context).textTheme.bodySmall,
      onChanged: (value) {
        if (value.isNotEmpty) {
          controller.notifyListeners();
        }
      },
    );
  }

  Widget _buildTotalWeightField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Total Weight',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Total Weight is required' : null,
      style: Theme.of(context).textTheme.bodySmall,
      onChanged: (value) {
        if (value.isNotEmpty) {
          controller.notifyListeners();
        }
      },
    );
  }
}

class EntryFormData {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  LedgerEntry? originalEntry;
  final numberFormat = NumberFormat('#,##0.00', 'en_US');
  late TextEditingController ledgerNoController;
  late TextEditingController voucherNoController;
  late TextEditingController accountNameController;
  late TextEditingController accountIdController;
  late TextEditingController transactionTypeController;
  late TextEditingController debitController;
  late TextEditingController creditController;
  late TextEditingController balanceController;
  late TextEditingController descriptionController;
  late TextEditingController referenceNoController;
  late TextEditingController categoryController;
  late TextEditingController tagsController;
  late TextEditingController createdByController;
  late TextEditingController statusController;
  // Item-related
  late TextEditingController itemIdController;
  late TextEditingController itemNameController;
  late TextEditingController itemPriceController;
  late TextEditingController canWeightController;
  late TextEditingController cansQuantityController;
  late TextEditingController sellingPriceController;
  late TextEditingController totalWeightController;
  late TextEditingController balanceCans;
  late TextEditingController receivedCans;
  final ledgerTableController = Get.find<LedgerTableController>();
  final RxString transactionType = RxString("Debit");
  final RxString status = RxString("Debit");
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<Item?> selectedItem = Rxn<Item?>(null);
  double? _previousBalance;
  late final GlobalKey<FormState> step1FormKey;
  late final GlobalKey<FormState> step2FormKey;
  late final GlobalKey<FormState> step3FormKey;
  final RxInt currentStep = 0.obs;
  final ledgerNoFocusNode = FocusNode();
  final voucherNoFocusNode = FocusNode();
  final accountNameFocusNode = FocusNode();
  final accountIdFocusNode = FocusNode();
  final transactionTypeFocusNode = FocusNode();
  final dateFocusNode = FocusNode();
  final itemFocusNode = FocusNode();
  final cansQuantityFocusNode = FocusNode();
  final itemPriceFocusNode = FocusNode();
  final canWeightFocusNode = FocusNode();
  final sellingPriceFocusNode = FocusNode();
  final totalWeightFocusNode = FocusNode();
  final balanceCansFocusNode = FocusNode();
  final receivedCansFocusNode = FocusNode();
  final debitFocusNode = FocusNode();
  final creditFocusNode = FocusNode();
  final balanceFocusNode = FocusNode();
  final statusFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();
  final referenceNoFocusNode = FocusNode();
  final categoryFocusNode = FocusNode();
  final createdByFocusNode = FocusNode();
  bool _isUpdatingDebit = false; // Flag to prevent recursive updates
  bool _isUpdatingCredit = false; // Flag to prevent recursive updates

  EntryFormData() {
    ledgerNoController = TextEditingController();
    voucherNoController = TextEditingController();
    accountNameController = TextEditingController();
    accountIdController = TextEditingController();
    transactionTypeController = TextEditingController(text: "Debit");
    debitController = TextEditingController(text: "0.00"); // Initialize to 0
    creditController = TextEditingController(text: "0.00"); // Initialize to 0
    balanceController = TextEditingController();
    descriptionController = TextEditingController();
    referenceNoController = TextEditingController();
    categoryController = TextEditingController();
    tagsController = TextEditingController();
    createdByController = TextEditingController();
    statusController = TextEditingController(text: "Debit");
    // Item
    itemIdController = TextEditingController();
    itemNameController = TextEditingController();
    itemPriceController = TextEditingController();
    canWeightController = TextEditingController();
    cansQuantityController = TextEditingController();
    sellingPriceController = TextEditingController();
    totalWeightController = TextEditingController();
    balanceCans = TextEditingController(
      text: ledgerTableController.balanceCans.toStringAsFixed(2),
    );
    receivedCans = TextEditingController();
    step1FormKey = GlobalKey<FormState>();
    step2FormKey = GlobalKey<FormState>();
    step3FormKey = GlobalKey<FormState>();

    // Listeners
    canWeightController.addListener(_onCanOrQtyChanged);
    cansQuantityController.addListener(_onCanOrQtyChanged);
    creditController.addListener(_handleCreditInputForDebitTransaction);
    debitController.addListener(_handleDebitInputForCreditTransaction);
    creditController.addListener(_updateBalance);
    debitController.addListener(_updateBalance);

    // Ever for selectedItem
    ever(selectedItem, (item) {
      if (item != null) {
        itemIdController.text = item.id.toString();
        itemNameController.text = item.name;
        itemPriceController.text = item.pricePerKg.toStringAsFixed(2);
        canWeightController.text = item.canWeight.toStringAsFixed(2);
        _onCanOrQtyChanged();
      } else {
        itemIdController.clear();
        itemNameController.clear();
        itemPriceController.clear();
        canWeightController.clear();
        sellingPriceController.clear();
        totalWeightController.clear();
        descriptionController.clear();
      }
    });

    // Ever for transactionType to handle initialization and updates
    ever(transactionType, (type) {
      if (type == "Debit") {
        _isUpdatingCredit = true;
        creditController.text = "0.00";
        _isUpdatingCredit = false;
        _isUpdatingDebit = true;
        debitController.text = sellingPriceController.text.isNotEmpty
            ? sellingPriceController.text
            : "0.00";
        _isUpdatingDebit = false;
      } else if (type == "Credit") {
        _isUpdatingDebit = true;
        debitController.text = "0.00";
        _isUpdatingDebit = false;
        _isUpdatingCredit = true;
        creditController.text = sellingPriceController.text.isNotEmpty
            ? sellingPriceController.text
            : "0.00";
        _isUpdatingCredit = false;
      }
      _calculateSellingPrice();
      _updateBalance();
    });
  }

  void _onCanOrQtyChanged() {
    _updateTotalWeight();
    _calculateSellingPrice();
    updateDescription();
  }

  void _handleCreditInputForDebitTransaction() {
    if (_isUpdatingCredit) return; // Prevent recursive updates
    if (transactionType.value == "Debit") {
      final currentValue = creditController.text;
      if (currentValue.isNotEmpty &&
          currentValue != "0" &&
          currentValue != "0.00") {
        final parsedValue = double.tryParse(currentValue);
        if (parsedValue != null) {
          _isUpdatingCredit = true;
          creditController.text = parsedValue == 0
              ? "0.00"
              : (-parsedValue).toStringAsFixed(2);
          _isUpdatingCredit = false;
        }
      }
    }
  }

  void _handleDebitInputForCreditTransaction() {
    if (_isUpdatingDebit) return; // Prevent recursive updates
    if (transactionType.value == "Credit") {
      final currentValue = debitController.text;
      if (currentValue.isNotEmpty &&
          currentValue != "0" &&
          currentValue != "0.00") {
        final parsedValue = double.tryParse(currentValue);
        if (parsedValue != null) {
          _isUpdatingDebit = true;
          debitController.text = parsedValue == 0
              ? "0.00"
              : (-parsedValue).toStringAsFixed(2);
          _isUpdatingDebit = false;
        }
      }
    }
  }

  Future<void> _initPreviousBalance() async {
    _previousBalance = ledgerTableController.netBalance; // Use netBalance
    _updateBalanceFromPrevious();
  }

  void _updateBalanceFromPrevious() {
    if (_previousBalance == null) return;
    final credit = double.tryParse(creditController.text) ?? 0.0;
    final newBalance = _previousBalance! + credit;
    balanceController.text = newBalance.toStringAsFixed(2);
  }

  void _updateBalance() {
    _updateBalanceFromPrevious();
  }

  void _calculateSellingPrice() {
    if (selectedItem.value == null) return;

    final pricePerKg = double.tryParse(itemPriceController.text) ?? 0;
    final canWeight = double.tryParse(canWeightController.text) ?? 0;
    final quantity = int.tryParse(cansQuantityController.text) ?? 0;

    if (pricePerKg > 0 && canWeight > 0 && quantity > 0) {
      final sellingPrice = pricePerKg * canWeight * quantity;
      sellingPriceController.text = sellingPrice.toStringAsFixed(2);

      if (transactionType.value == 'Debit') {
        _isUpdatingDebit = true;
        debitController.text = sellingPrice.toStringAsFixed(2);
        _isUpdatingDebit = false;
        _isUpdatingCredit = true;
        creditController.text = "0.00"; // Ensure credit is 0 for Debit
        _isUpdatingCredit = false;
      } else if (transactionType.value == 'Credit') {
        _isUpdatingCredit = true;
        creditController.text = sellingPrice.toStringAsFixed(2);
        _isUpdatingCredit = false;
        _isUpdatingDebit = true;
        debitController.text = "0.00"; // Ensure debit is 0 for Credit
        _isUpdatingDebit = false;
      }
      _updateBalance();
    }
  }

  void _updateTotalWeight() {
    final canWeight = double.tryParse(canWeightController.text) ?? 0;
    final quantity = int.tryParse(cansQuantityController.text) ?? 0;
    final totalWeight = canWeight * quantity;

    totalWeightController.text = totalWeight.toStringAsFixed(2);
  }

  String generateItemDescription() {
    if (selectedItem.value == null ||
        canWeightController.text.isEmpty ||
        cansQuantityController.text.isEmpty) {
      return '';
    }

    final itemName = selectedItem.value!.name;
    final canWeight = canWeightController.text;
    final canQty = cansQuantityController.text;
    final totalWeight =
        (double.tryParse(canWeight) ?? 0) * (int.tryParse(canQty) ?? 0);
    final pricePerKg = itemPriceController.text;
    final totalAmount = sellingPriceController.text;

    return '$itemName (can of ${canWeight}Kgs*$canQty${int.parse(canQty) > 1 ? 'cans' : 'can'} = ${totalWeight}Kgs at Price $pricePerKg/Kg and total amount is: $totalAmount)';
  }

  void updateDescription() {
    final newDescription = generateItemDescription();
    if (newDescription.isNotEmpty) {
      descriptionController.text = newDescription;
    }
  }

  void dispose() {
    ledgerNoController.dispose();
    voucherNoController.dispose();
    accountNameController.dispose();
    accountIdController.dispose();
    transactionTypeController.dispose();
    debitController.dispose();
    creditController.dispose();
    balanceController.dispose();
    descriptionController.dispose();
    referenceNoController.dispose();
    categoryController.dispose();
    tagsController.dispose();
    createdByController.dispose();
    statusController.dispose();
    itemIdController.dispose();
    itemNameController.dispose();
    itemPriceController.dispose();
    canWeightController.dispose();
    cansQuantityController.dispose();
    sellingPriceController.dispose();
    totalWeightController.dispose();
    balanceCans.dispose();
    receivedCans.dispose();
  }
}
