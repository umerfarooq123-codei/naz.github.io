import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/inventory/inventory_repository.dart';
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
                                                'Debit: ₨${ledger.debit.toStringAsFixed(2)} ',
                                                ledgerController
                                                    .searchQuery
                                                    .value,
                                              ),
                                              buildHighlightedText(
                                                'Credit: ₨${ledger.credit.toStringAsFixed(2)}',
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
                label: 'Debit (₨)',
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
                label: 'Credit (₨)',
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
                label: 'Balance (₨)',
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
          label: 'Debit (₨)',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: controller.creditController,
          label: 'Credit (₨)',
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
          label: 'Balance (₨)',
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntries(ledger.ledgerNo);
    });

    return BaseLayout(
      appBarTitle: "Ledger Entries: ${ledger.accountName}",
      child: Obx(() {
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
                        onChanged: (value) => controller.filterLedgerEntries(),
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
                        controller.filterLedgerEntries();
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
                      controller.ledgerController.clearEntryForm();
                      await controller.ledgerController.loadLedgerEntry(
                        ledgerNo: ledger.ledgerNo,
                      );
                      if (context.mounted) {
                        NavigationHelper.push(
                          context,
                          LedgerEntryAddEdit(
                            ledgerNo: ledger.ledgerNo,
                            onEntrySaved: () => controller.loadLedgerEntries(
                              ledger.ledgerNo,
                            ), // ADD THIS
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
                    child: Stack(
                      children: [
                        SfDataGrid(
                          source: LedgerEntryDataSource(
                            controller.ledgerController.filteredLedgerEntries,
                            context,
                            selectedRows: controller.selectedRows.toSet(),
                            onRowSelectionChanged:
                                controller.handleRowSelection,
                            selectAll: controller.selectAll.value,
                            onSelectAllChanged: controller.handleSelectAll,
                          ),
                          columnWidthMode: ColumnWidthMode.auto,
                          gridLinesVisibility: GridLinesVisibility.both,
                          headerGridLinesVisibility: GridLinesVisibility.both,
                          // Proper placeholder when no data
                          placeholder: Center(
                            child: Text(
                              "No data available",
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),

                          columns: [
                            GridColumn(
                              columnName: 'checkbox',
                              width: 60,
                              label: Container(
                                alignment: Alignment.center,
                                child: Obx(
                                  () => Checkbox(
                                    value: controller.selectAll.value,
                                    onChanged: controller.handleSelectAll,
                                  ),
                                ),
                              ),
                            ),
                            GridColumn(
                              columnName: 'voucherNo',
                              label: headerText("Voucher No", context),
                            ),
                            GridColumn(
                              columnName: 'date',
                              label: headerText("Date", context),
                            ),
                            GridColumn(
                              columnName: 'item',
                              label: headerText("Item", context),
                            ),
                            GridColumn(
                              columnName: 'priceperkg',
                              label: headerText("Price", context),
                            ),
                            GridColumn(
                              columnName: 'canqty',
                              label: headerText("Can Qty", context),
                            ),
                            GridColumn(
                              columnName: 'canweight',
                              label: headerText("Can weight", context),
                            ),
                            GridColumn(
                              columnName: 'transactionType',
                              label: headerText("Type", context),
                            ),
                            GridColumn(
                              columnName: 'description',
                              label: headerText("Description", context),
                            ),
                            GridColumn(
                              columnName: 'referenceNo',
                              label: headerText("Ref", context),
                            ),
                            GridColumn(
                              columnName: 'createdBy',
                              label: headerText("Created By", context),
                            ),
                            GridColumn(
                              columnName: 'debit',
                              label: headerText("Debit", context),
                            ),
                            GridColumn(
                              columnName: 'credit',
                              label: headerText("Credit", context),
                            ),
                            GridColumn(
                              columnName: 'balance',
                              label: headerText("Balance", context),
                            ),
                          ],
                        ),
                        if (controller.selectedRows.isNotEmpty)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: _selectionBar(controller, context),
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
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );

  Widget _selectionBar(
    LedgerTableController controller,
    BuildContext context,
  ) => Container(
    padding: const EdgeInsets.all(8),
    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // if (controller.selectedRows.length == 1)
        //   ElevatedButton.icon(
        //     onPressed: () {
        //       final entry = controller.ledgerController.ledgerEntries
        //           .firstWhere((e) => e.id == controller.selectedRows.first);
        //       _editEntry(controller, entry, context);
        //     },
        //     icon: const Icon(Icons.edit),
        //     label: const Text("Edit"),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: Theme.of(context).colorScheme.primary,
        //       foregroundColor: Theme.of(context).colorScheme.onPrimary,
        //     ),
        //   ),
        // if (controller.selectedRows.isNotEmpty) const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _deleteEntries(
            controller,
            controller.selectedRows.toList(),
            context,
          ),
          icon: const Icon(Icons.delete),
          label: const Text("Delete"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );

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
        LedgerEntryAddEdit(entry: entry, ledgerNo: entry.ledgerNo),
      );
    }
  }

  Future<void> _deleteEntries(
    LedgerTableController controller,
    List<int> ids,
    BuildContext context,
  ) async {
    for (final id in ids) {
      await controller.ledgerController.deleteLedgerEntry(id, ledger.ledgerNo);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${ids.length} entries deleted')));
    }
    controller.selectedRows.clear();
    controller.selectAll.value = false;
  }
}

class LedgerEntryDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  final BuildContext context;
  final Set<int> selectedRows;
  final Function(int id, bool? selected) onRowSelectionChanged;
  final bool selectAll;
  final Function(bool? selected) onSelectAllChanged;

  LedgerEntryDataSource(
    List<LedgerEntry> entries,
    this.context, {
    required this.selectedRows,
    required this.onRowSelectionChanged,
    required this.selectAll,
    required this.onSelectAllChanged,
  }) {
    _rows = entries.map((entry) {
      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'checkbox', value: entry.id),
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
          DataGridCell(
            columnName: 'referenceNo',
            value: entry.referenceNo ?? '',
          ),
          DataGridCell(columnName: 'createdBy', value: entry.createdBy ?? ''),
          DataGridCell(columnName: 'debit', value: entry.debit),
          DataGridCell(columnName: 'credit', value: entry.credit),
          DataGridCell(columnName: 'balance', value: entry.balance),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'checkbox') {
          final id = cell.value as int;
          return Container(
            alignment: Alignment.center,
            child: Checkbox(
              value: selectedRows.contains(id),
              onChanged: (selected) => onRowSelectionChanged(id, selected),
            ),
          );
        } else if (cell.columnName == 'debit' ||
            cell.columnName == 'credit' ||
            cell.columnName == 'balance') {
          return Container(
            alignment: Alignment.center,
            child: Text(
              NumberFormat('#,##0.00', 'en_US').format(cell.value ?? 0),
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w500),
            ),
          );
        }
        return Container(
          alignment: Alignment.center,
          child: Text(
            cell.value.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }).toList(),
    );
  }
}

class LedgerEntryAddEdit extends StatefulWidget {
  final LedgerEntry? entry;
  final String ledgerNo;
  final VoidCallback? onEntrySaved; // ADD THIS

  const LedgerEntryAddEdit({
    super.key,
    this.entry,
    required this.ledgerNo,
    this.onEntrySaved, // ADD THIS
  });

  @override
  State<LedgerEntryAddEdit> createState() => _LedgerEntryAddEditState();
}

class _LedgerEntryAddEditState extends State<LedgerEntryAddEdit> {
  late final LedgerController controller;
  late final CustomerController customerController;
  late final LedgerTableController ledgerTableController;
  late TextEditingController _totalWeightController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LedgerController>();
    customerController = Get.find<CustomerController>();
    ledgerTableController = Get.find<LedgerTableController>();
    _totalWeightController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntry(
        entry: widget.entry,
        ledgerNo: widget.ledgerNo,
      );

      controller.addDescriptionListeners();

      controller.entryCanWeightController.addListener(_updateTotalWeight);
      controller.entryCansQuantityController.addListener(_updateTotalWeight);

      _updateTotalWeight();
    });
  }

  @override
  void dispose() {
    // Remove listeners when widget is disposed
    controller.removeDescriptionListeners();
    controller.entryCanWeightController.removeListener(_updateTotalWeight);
    controller.entryCansQuantityController.removeListener(_updateTotalWeight);
    _totalWeightController.dispose();
    super.dispose();
  }

  void _updateTotalWeight() {
    final canWeight =
        double.tryParse(controller.entryCanWeightController.text) ?? 0;
    final quantity =
        int.tryParse(controller.entryCansQuantityController.text) ?? 0;
    final totalWeight = canWeight * quantity;

    _totalWeightController.text = totalWeight.toStringAsFixed(2);

    // Also trigger UI update
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildTextField({
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

  Widget _buildTotalWeightField() {
    return TextFormField(
      readOnly: true,
      controller: _totalWeightController,
      decoration: InputDecoration(
        labelText: 'Total Weight (Kg/L)',
        labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchItems();
    });

    return Obx(
      () => BaseLayout(
        appBarTitle: widget.entry == null
            ? 'Add Ledger Entry'
            : 'Edit Ledger Entry',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.entryFormKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ledger Entry Details',
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
                          ? _buildDesktopLayout()
                          : _buildMobileLayout(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          controller.clearEntryForm();
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
                        onPressed: () async {
                          await controller.saveLedgerEntry(
                            context,
                            entry: widget.entry,
                            ledgerNo: widget.ledgerNo,
                          );
                          ledgerTableController.loadLedgerEntries(
                            widget.ledgerNo,
                          );
                          // Call the callback if provided
                          if (widget.onEntrySaved != null) {
                            widget.onEntrySaved!();
                          }
                        },
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

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.entryLedgerNoController,
                label: 'Ledger No',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.entryVoucherNoController,
                label: 'Voucher No',
                readOnly: true,
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
                controller: controller.entryAccountNameController,
                label: 'Account Name',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.entryAccountIdController,
                label: 'Account ID',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                readOnly: true,
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
                initialValue: controller.entryTransactionType.value,
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
                  controller.entryTransactionType.value = value;
                  controller.entryTransactionTypeController.text = value ?? '';
                  if (value == "Debit") {
                    controller._handleCreditInputForDebitTransaction();
                  }
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a transaction type'
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => controller.selectDate(context, isEntry: true),
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
                    ).format(controller.entrySelectedDate.value),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Item Selection Section
        const Divider(),
        Text(
          'Item Details',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<Item>(
                initialValue: widget.entry != null
                    ? controller.availableItems.firstWhere(
                        (item) => item.name == widget.entry!.itemName,
                      )
                    : null,
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
                  controller.selectedItem.value = item;
                  controller.updateDescription();
                  _updateTotalWeight();
                },
                selectedItemBuilder: (BuildContext context) {
                  return controller.availableItems.map<Widget>((Item item) {
                    return Text('${item.name} (Stock: ${item.availableStock})');
                  }).toList();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.entryCansQuantityController,
                label: 'Cans Quantity',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (controller.selectedItem.value != null &&
                      value != null &&
                      value.isNotEmpty) {
                    final quantity = int.tryParse(value) ?? 0;
                    final canWeight =
                        double.tryParse(
                          controller.entryCanWeightController.text,
                        ) ??
                        0;
                    final totalWeight = quantity * canWeight;

                    if (totalWeight >
                        controller.selectedItem.value!.availableStock) {
                      return 'Not enough stock. Available: ${controller.selectedItem.value!.availableStock}';
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
                controller: controller.entryItemPriceController,
                label: 'Price per Kg/L (₨)',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.entryCanWeightController,
                label: 'Can Weight (Kg/L)',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
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
                controller: controller.entrySellingPriceController,
                label: 'Selling Price (₨)',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildTotalWeightField()),
          ],
        ),
        const Divider(),
        const SizedBox(height: 16),

        // Debit/Credit Section
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.entryDebitController,
                label: 'Debit (₨)',
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
              child: _buildTextField(
                controller: controller.entryCreditController,
                label: 'Credit (₨)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.entryBalanceController,
                label: 'Balance (₨)',
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
                initialValue: controller.entryStatus.value,
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
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select status'
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
                controller: controller.entryDescriptionController,
                label: 'Description',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.entryReferenceNo,
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
                controller: controller.entryCategoryController,
                label: 'Category',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: controller.entryCreatedByController,
                label: 'Created By',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTextField(
          controller: controller.entryLedgerNoController,
          label: 'Ledger No',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryVoucherNoController,
          label: 'Voucher No',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryAccountNameController,
          label: 'Account Name',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryAccountIdController,
          label: 'Account ID',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          readOnly: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: controller.entryTransactionType.value,
          style: Theme.of(context).textTheme.bodySmall,
          decoration: InputDecoration(
            labelText: 'Transaction Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const ['Debit', 'Credit']
              .map((t) => DropdownMenuItem<String>(value: t, child: Text(t)))
              .toList(),
          onChanged: (value) {
            controller.entryTransactionType.value = value;
            controller.entryTransactionTypeController.text = value ?? '';
            if (value == "Debit") {
              controller._handleCreditInputForDebitTransaction();
            }
          },
          validator: (value) => value == null || value.isEmpty
              ? 'Please select a transaction type'
              : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => controller.selectDate(context, isEntry: true),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              DateFormat(
                'dd-MM-yyyy',
              ).format(controller.entrySelectedDate.value),
            ),
          ),
        ),

        // Item Selection Section
        const SizedBox(height: 16),
        const Divider(),
        Text(
          'Item Details',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Item>(
          initialValue:
              controller.availableItems.contains(controller.selectedItem.value)
              ? controller.selectedItem.value
              : null, // Handle case where value isn't in list
          style: Theme.of(context).textTheme.bodySmall,
          decoration: InputDecoration(
            labelText: 'Item',
            labelStyle: Theme.of(context).textTheme.bodySmall,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: controller.availableItems
              .map(
                (item) => DropdownMenuItem<Item>(
                  value: item,
                  child: Text('${item.name} (Stock: ${item.availableStock})'),
                ),
              )
              .toList(),
          onChanged: (item) {
            controller.selectedItem.value = item;
            controller.updateDescription();
            _updateTotalWeight();
          },
          selectedItemBuilder: (BuildContext context) {
            return controller.availableItems.map<Widget>((Item item) {
              return Text('${item.name} (Stock: ${item.availableStock})');
            }).toList();
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryCansQuantityController,
          label: 'Cans Quantity',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (controller.selectedItem.value != null &&
                value != null &&
                value.isNotEmpty) {
              final quantity = int.tryParse(value) ?? 0;
              final canWeight =
                  double.tryParse(controller.entryCanWeightController.text) ??
                  0;
              final totalWeight = quantity * canWeight;

              if (totalWeight > controller.selectedItem.value!.availableStock) {
                return 'Not enough stock. Available: ${controller.selectedItem.value!.availableStock}';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryItemPriceController,
          label: 'Price per Kg/L (₨)',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryCanWeightController,
          label: 'Can Weight (Kg/L)',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entrySellingPriceController,
          label: 'Selling Price (₨)',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTotalWeightField(),
        const Divider(),
        const SizedBox(height: 16),

        _buildTextField(
          controller: controller.entryDebitController,
          label: 'Debit (₨)',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryCreditController,
          label: 'Credit (₨)',
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
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

        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryBalanceController,
          label: 'Balance (₨)',
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          readOnly: true,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: controller.entryStatus.value,
          style: Theme.of(context).textTheme.bodySmall,
          decoration: InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: const ['Debit', 'Credit']
              .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
              .toList(),
          onChanged: null,
          validator: (value) =>
              value == null || value.isEmpty ? 'Please select status' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryDescriptionController,
          label: 'Description',
          readOnly: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(controller: controller.entryReferenceNo, label: 'Ref'),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryCategoryController,
          label: 'Category',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: controller.entryCreatedByController,
          label: 'Created By',
        ),
      ],
    );
  }
}

class LedgerController extends GetxController {
  final LedgerRepository repo;
  final InventoryRepository inventoryRepo = InventoryRepository();
  final ledgers = <Ledger>[].obs;
  final filteredLedgers = <Ledger>[].obs;
  final ledgerEntries = <LedgerEntry>[].obs;
  final filteredLedgerEntries = <LedgerEntry>[].obs;
  final isDarkMode = true.obs;
  final formKey = GlobalKey<FormState>();
  final entryFormKey = GlobalKey<FormState>();

  // Ledger Form controllers
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

  // LedgerEntry Form controllers
  final entryLedgerNoController = TextEditingController();
  final entryVoucherNoController = TextEditingController();
  final entryAccountNameController = TextEditingController();
  final entryAccountIdController = TextEditingController();
  final entryTransactionTypeController = TextEditingController();
  final entryDebitController = TextEditingController();
  final entryCreditController = TextEditingController();
  final entryBalanceController = TextEditingController();
  final entryDescriptionController = TextEditingController();
  final entryReferenceNo = TextEditingController();
  final entryCategoryController = TextEditingController();
  final entryTagsController = TextEditingController();
  final entryCreatedByController = TextEditingController();
  final entryStatusController = TextEditingController();

  // Item-related controllers for ledger entries
  final entryItemIdController = TextEditingController();
  final entryItemNameController = TextEditingController();
  final entryItemPriceController = TextEditingController();
  final entryCanWeightController = TextEditingController();
  final entryCansQuantityController = TextEditingController();
  final entrySellingPriceController = TextEditingController();

  final selectedDate = DateTime.now().obs;
  final entrySelectedDate = DateTime.now().obs;
  final transactionType = RxnString();
  final status = RxnString();
  final entryTransactionType = RxnString();
  final entryStatus = RxnString();
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;
  final selectedItem = Rxn<Item>();
  final availableItems = <Item>[].obs;

  // Track original entry for stock reversal when editing
  LedgerEntry? _originalEntry;

  LedgerController(this.repo);

  double oldDebit = 0;
  double oldCredit = 0;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
    fetchLedgers();
    loadRecentSearches();
    fetchItems();

    ever<String>(searchQuery, (_) => filterLedgers());
    ever<List<Ledger>>(ledgers, (_) => filterLedgers());
    ever<List<LedgerEntry>>(ledgerEntries, (_) => filterLedgerEntries());
    entryCreditController.addListener(_handleCreditInputForDebitTransaction);
    debitController.addListener(_onAmountOrAccountChanged);
    creditController.addListener(_onAmountOrAccountChanged);
    accountIdController.addListener(_onAmountOrAccountChanged);
    entryDebitController.addListener(_onEntryAmountOrAccountChanged);
    entryCreditController.addListener(_onEntryAmountOrAccountChanged);
    entryAccountIdController.addListener(_onEntryAmountOrAccountChanged);

    // Listen to item selection changes
    ever(selectedItem, (item) {
      if (item != null) {
        entryItemIdController.text = item.id.toString();
        entryItemNameController.text = item.name;
        entryItemPriceController.text = item.pricePerKg.toStringAsFixed(2);
        entryCanWeightController.text = item.canWeight.toStringAsFixed(2);
        _calculateSellingPrice();
      } else {
        entryItemIdController.clear();
        entryItemNameController.clear();
        entryItemPriceController.clear();
        entryCanWeightController.clear();
        entrySellingPriceController.clear();
      }
    });

    // Listen to quantity and weight changes for price calculation
    entryCansQuantityController.addListener(_calculateSellingPrice);
    entryCanWeightController.addListener(_calculateSellingPrice);
  }

  Future<void> refreshItems() async {
    await fetchItems();
    update(); // Notify listeners
  }

  void _updateTotalWeight() {
    // This will trigger UI updates when can weight or quantity changes
    update();
  }

  void _handleCreditInputForDebitTransaction() {
    if (entryTransactionType.value == "Debit") {
      final currentValue = entryCreditController.text;

      // Only add negative sign if the value is not empty, not zero, and doesn't already have a negative sign
      if (currentValue.isNotEmpty &&
          currentValue != "0" &&
          currentValue != "0.00" &&
          !currentValue.startsWith('-')) {
        final parsedValue = double.tryParse(currentValue);
        if (parsedValue != null && parsedValue > 0) {
          entryCreditController.text = (-parsedValue).toStringAsFixed(2);
        }
      }
    }
  }

  String generateItemDescription() {
    if (selectedItem.value == null ||
        entryCanWeightController.text.isEmpty ||
        entryCansQuantityController.text.isEmpty) {
      return '';
    }

    final itemName = selectedItem.value!.name;
    final canWeight = entryCanWeightController.text;
    final canQty = entryCansQuantityController.text;
    final totalWeight =
        (double.tryParse(canWeight) ?? 0) * (int.tryParse(canQty) ?? 0);
    final pricePerKg = entryItemPriceController.text;
    final totalAmount = entrySellingPriceController.text;

    return '$itemName (can of ${canWeight}Kgs*${canQty}cans = ${totalWeight}Kgs at Price ₨$pricePerKg/Kg and total amount is:₨$totalAmount)';
  }

  void addDescriptionListeners() {
    entryCanWeightController.addListener(updateDescription);
    entryCansQuantityController.addListener(updateDescription);
  }

  void ensureSelectedItemIsAvailable() {
    if (selectedItem.value != null) {
      final itemExists = availableItems.any(
        (item) => item.id == selectedItem.value!.id,
      );
      if (!itemExists) {
        selectedItem.value = null;
      }
    }
  }

  void removeDescriptionListeners() {
    entryCanWeightController.removeListener(updateDescription);
    entryCansQuantityController.removeListener(updateDescription);
  }

  void updateDescription() {
    final newDescription = generateItemDescription();
    if (newDescription.isNotEmpty) {
      entryDescriptionController.text = newDescription;
    }
  }

  Future<void> fetchItems() async {
    final items = await inventoryRepo.getAllItems();
    availableItems.assignAll(items);
    ensureSelectedItemIsAvailable();
  }

  void _calculateSellingPrice() {
    if (selectedItem.value == null) return;

    final pricePerKg = double.tryParse(entryItemPriceController.text) ?? 0;
    final canWeight = double.tryParse(entryCanWeightController.text) ?? 0;
    final quantity = int.tryParse(entryCansQuantityController.text) ?? 0;

    if (pricePerKg > 0 && canWeight > 0 && quantity > 0) {
      final sellingPrice = pricePerKg * canWeight * quantity;
      entrySellingPriceController.text = sellingPrice.toStringAsFixed(2);

      if (entryTransactionType.value == 'Debit') {
        entryDebitController.text = sellingPrice.toStringAsFixed(2);
      } else if (entryTransactionType.value == 'Credit') {
        entryCreditController.text = sellingPrice.toStringAsFixed(2);
      }
    }
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
      initialDate: isEntry ? entrySelectedDate.value : selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isEntry) {
        entrySelectedDate.value = picked;
      } else {
        selectedDate.value = picked;
      }
      if (isEntry) {
        _onEntryAmountOrAccountChanged();
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
    filterLedgerEntries();
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
      final lastLedgerNo = repo.getLedgerNo();
      ledgerNoController.text = lastLedgerNo;
      voucherNoController.text = _generateVoucherNo();
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
    final parentLedger = ledgers.firstWhere((l) => l.ledgerNo == ledgerNo);
    await fetchItems();

    if (entry == null) {
      clearEntryForm(keepDate: true);
      entryLedgerNoController.text = ledgerNo;
      entryVoucherNoController.text = _generateVoucherNo(isEntry: true);
      entrySelectedDate.value = DateTime.now();
      entryAccountNameController.text = parentLedger.accountName;
      entryAccountIdController.text = parentLedger.accountId?.toString() ?? '';
      selectedItem.value = null;
      _originalEntry = null;
    } else {
      _originalEntry = entry; // Store original for stock calculations
      entryLedgerNoController.text = entry.ledgerNo;
      entryVoucherNoController.text = entry.voucherNo;
      entryAccountNameController.text = entry.accountName;
      entryAccountIdController.text = entry.accountId?.toString() ?? '';
      entryTransactionTypeController.text = entry.transactionType;
      entryTransactionType.value = entry.transactionType;
      entryDebitController.text = entry.debit.toStringAsFixed(2);
      entryCreditController.text = entry.credit.toStringAsFixed(2);
      entryBalanceController.text = entry.balance.toStringAsFixed(2);
      entryDescriptionController.text = entry.description ?? '';
      entryReferenceNo.text = entry.referenceNo ?? '';
      entryCategoryController.text = entry.category ?? '';
      entryTagsController.text = entry.tags?.join(', ') ?? '';
      entryCreatedByController.text = entry.createdBy ?? '';
      entryStatusController.text = entry.status;
      entryStatus.value = entry.status;
      entrySelectedDate.value = entry.date;

      if (entry.itemId != null) {
        final item = availableItems.firstWhereOrNull(
          (item) => item.id == entry.itemId,
        );
        if (item != null) {
          selectedItem.value = item;
          entryItemIdController.text = entry.itemId.toString();
          entryItemNameController.text = entry.itemName ?? item.name;
          entryItemPriceController.text =
              (entry.itemPricePerUnit ?? item.pricePerKg).toStringAsFixed(2);
          entryCanWeightController.text = (entry.canWeight ?? item.canWeight)
              .toStringAsFixed(2);
          entryCansQuantityController.text =
              entry.cansQuantity?.toString() ?? '0';
          entrySellingPriceController.text = (entry.sellingPricePerCan ?? 0)
              .toStringAsFixed(2);
          updateDescription();
        } else {
          selectedItem.value = null;
        }
      } else {
        selectedItem.value = null;
      }
    }
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

  Future<void> saveLedgerEntry(
    BuildContext context, {
    LedgerEntry? entry,
    required String ledgerNo,
  }) async {
    if (!entryFormKey.currentState!.validate()) {
      return;
    }

    // Validate item stock based on weight
    if (selectedItem.value != null &&
        entryCansQuantityController.text.isNotEmpty &&
        entryCanWeightController.text.isNotEmpty) {
      final quantity = int.parse(entryCansQuantityController.text);
      final canWeight = double.parse(entryCanWeightController.text);

      if (!await _validateStockAvailability(
        selectedItem.value!,
        quantity,
        canWeight,
      )) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Not enough stock. Available: ${selectedItem.value!.availableStock} kgs, Required: ${quantity * canWeight} kgs',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    final parsedDebit = double.tryParse(entryDebitController.text) ?? 0.0;
    final parsedCredit = double.tryParse(entryCreditController.text) ?? 0.0;
    final parsedBalance = double.tryParse(entryBalanceController.text) ?? 0.0;

    final newEntry = LedgerEntry(
      id: entry?.id,
      ledgerNo: entryLedgerNoController.text,
      voucherNo: entryVoucherNoController.text,
      accountId: entryAccountIdController.text.isNotEmpty
          ? int.parse(entryAccountIdController.text)
          : null,
      accountName: entryAccountNameController.text.toUpperCase(),
      date: entrySelectedDate.value,
      transactionType:
          entryTransactionType.value ?? entryTransactionTypeController.text,
      debit: parsedDebit,
      credit: parsedCredit,
      balance: parsedBalance,
      status: entryStatus.value ?? entryStatusController.text,
      description: entryDescriptionController.text.isNotEmpty
          ? entryDescriptionController.text
          : null,
      referenceNo: entryReferenceNo.text.isNotEmpty
          ? entryReferenceNo.text
          : null,
      category: entryCategoryController.text.isNotEmpty
          ? entryCategoryController.text
          : null,
      tags: entryTagsController.text.isNotEmpty
          ? entryTagsController.text.split(',').map((t) => t.trim()).toList()
          : null,
      createdBy: entryCreatedByController.text.isNotEmpty
          ? entryCreatedByController.text
          : null,
      createdAt: entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      itemId: selectedItem.value?.id,
      itemName: selectedItem.value?.name,
      itemPricePerUnit: double.tryParse(entryItemPriceController.text),
      canWeight: double.tryParse(entryCanWeightController.text),
      cansQuantity: int.tryParse(entryCansQuantityController.text),
      sellingPricePerCan: double.tryParse(entrySellingPriceController.text),
    );

    final ledger = ledgers.firstWhere((l) => l.ledgerNo == ledgerNo);
    int? aid = ledger.accountId;

    try {
      if (entry == null) {
        // New entry
        await repo.insertLedgerEntry(newEntry, ledgerNo);
        await _handleItemStockForNewEntry(newEntry);
      } else {
        // Updated entry
        await _handleItemStockForUpdatedEntry(_originalEntry!, newEntry);
        await repo.updateLedgerEntry(newEntry, ledgerNo);
      }

      if (aid != null) {
        await recalculateBalancesForAccount(aid);
      }

      await updateLedgerTotals(ledgerNo);

      await fetchLedgerEntries(ledgerNo);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ledger entry saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        NavigationHelper.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
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

  Future<void> _onEntryAmountOrAccountChanged() async {
    double previous = await getLastBalanceForAccount(
      int.tryParse(entryAccountIdController.text),
    );
    double.tryParse(entryDebitController.text) ?? 0.0;
    final credit = double.tryParse(entryCreditController.text) ?? 0.0;
    final newBalance = previous + credit; // Updated to accumulate credits only
    entryBalanceController.text = newBalance.toStringAsFixed(2);
    entryStatus.value = newBalance > 0 ? 'Debit' : 'Credit';
    entryStatusController.text = entryStatus.value ?? '';
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
        );
        await repo.updateLedgerEntry(updatedEntry, t.ledgerNo);
      }
    }
    final customerController = Get.find<CustomerController>();
    final custList = customerController.customers;
    int index = custList.indexWhere((c) => c.id == aid);
    if (index != -1) {
      var cust = custList[index];
      cust = Customer(
        id: cust.id,
        name: cust.name,
        address: cust.address,
        customerNo: cust.customerNo,
        mobileNo: cust.mobileNo,
        ntnNo: cust.ntnNo,
      );
      await customerController.repo.updateCustomer(cust);
      customerController.customers[index] = cust;
    }
    await fetchLedgers();
  }

  String _generateVoucherNo({bool isEntry = false}) {
    final regex = RegExp(r'VN(\d+)');
    int max = 0;
    final source = isEntry ? ledgerEntries : ledgers;
    for (final item in source) {
      final m = regex.firstMatch(
        isEntry ? (item as LedgerEntry).voucherNo : (item as Ledger).voucherNo,
      );
      if (m != null) {
        final n = int.tryParse(m.group(1)!) ?? 0;
        if (n > max) max = n;
      }
    }
    if (max > 0) {
      return 'VN${max + 1}';
    }
    return 'VN${DateTime.now().millisecondsSinceEpoch}';
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

  void clearEntryForm({bool keepDate = false}) {
    entryLedgerNoController.clear();
    entryVoucherNoController.clear();
    entryAccountNameController.clear();
    entryAccountIdController.clear();
    entryTransactionTypeController.clear();
    entryDebitController.clear();
    entryCreditController.clear();
    entryBalanceController.clear();
    entryDescriptionController.clear();
    entryReferenceNo.clear();
    entryCategoryController.clear();
    entryTagsController.clear();
    entryCreatedByController.clear();
    entryStatusController.clear();
    entryTransactionType.value = null;
    entryStatus.value = null;

    // Clear item fields
    entryItemIdController.clear();
    entryItemNameController.clear();
    entryItemPriceController.clear();
    entryCanWeightController.clear();
    entryCansQuantityController.clear();
    entrySellingPriceController.clear();
    selectedItem.value = null;

    if (!keepDate) {
      entrySelectedDate.value = DateTime.now();
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

  void filterLedgerEntries({
    DateTime? fromDate,
    DateTime? toDate,
    String? transactionType,
    String? searchQuery,
  }) {
    filteredLedgerEntries.assignAll(
      ledgerEntries.where((entry) {
        bool matches = true;

        // Date filter
        if (fromDate != null && toDate != null) {
          matches =
              matches &&
              entry.date.isAfter(fromDate.subtract(Duration(days: 1))) &&
              entry.date.isBefore(toDate.add(Duration(days: 1)));
        }

        // Transaction type filter
        if (transactionType != null && transactionType.isNotEmpty) {
          matches = matches && entry.transactionType == transactionType;
        }

        // Search query filter
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase().trim();
          final voucherNoStr = entry.voucherNo.toLowerCase();
          final dateStr = formatDate(entry.date).toLowerCase();
          final refStr = entry.referenceNo?.toLowerCase() ?? '';
          final accountNameStr = entry.accountName.toLowerCase();
          final typeStr = entry.transactionType.toLowerCase();
          final descStr = entry.description?.toLowerCase() ?? '';
          final categoryStr = entry.category?.toLowerCase() ?? '';
          final tagsMatch =
              entry.tags?.any((tag) => tag.toLowerCase().contains(query)) ??
              false;

          matches =
              matches &&
              (voucherNoStr.contains(query) ||
                  dateStr.contains(query) ||
                  refStr.contains(query) ||
                  accountNameStr.contains(query) ||
                  typeStr.contains(query) ||
                  descStr.contains(query) ||
                  categoryStr.contains(query) ||
                  tagsMatch);
        }

        return matches;
      }).toList(),
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
    entryLedgerNoController.dispose();
    entryVoucherNoController.dispose();
    entryAccountNameController.dispose();
    entryAccountIdController.dispose();
    entryTransactionTypeController.dispose();
    entryDebitController.dispose();
    entryCreditController.dispose();
    entryBalanceController.dispose();
    entryDescriptionController.dispose();
    entryReferenceNo.dispose();
    entryCategoryController.dispose();
    entryTagsController.dispose();
    entryCreatedByController.dispose();
    entryStatusController.dispose();
    entryCreditController.removeListener(_handleCreditInputForDebitTransaction);
    // Item controllers
    entryItemIdController.dispose();
    entryItemNameController.dispose();
    entryItemPriceController.dispose();
    entryCanWeightController.dispose();
    entryCansQuantityController.dispose();
    entrySellingPriceController.dispose();
    entryCanWeightController.removeListener(_updateTotalWeight);
    entryCansQuantityController.removeListener(_updateTotalWeight);
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

class LedgerTableController extends GetxController {
  final LedgerController ledgerController = Get.find<LedgerController>();
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final searchController = TextEditingController();
  final selectedRows = <int>{}.obs;
  final selectAll = false.obs;
  final selectedTransactionType = RxnString();
  final isLoading = false.obs;
  final calculationAnalysis = ''.obs;
  final showCalculationAnalysis = false.obs;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    fromDateController.text = DateFormat(
      'dd-MM-yyyy',
    ).format(now.subtract(Duration(days: 30)));
    toDateController.text = DateFormat('dd-MM-yyyy').format(now);
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
    final picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? DateFormat('dd-MM-yyyy').parse(fromDateController.text)
          : DateFormat('dd-MM-yyyy').parse(toDateController.text),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (isFromDate) {
        fromDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      } else {
        toDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      }
      filterLedgerEntries();
    }
  }

  void filterLedgerEntries() {
    // First, get the filtered entries based on criteria (from correctly balanced full entries)
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

    // Sort filtered entries by date DESCENDING and id DESCENDING (for display order)
    // This will put newest entries at the top
    filtered.sort((a, b) {
      int dateComparison = b.date.compareTo(a.date); // REVERSED: b before a
      if (dateComparison != 0) return dateComparison;
      return (b.id ?? 0).compareTo(a.id ?? 0); // REVERSED: b before a
    });

    // IMPORTANT: Do NOT recalculate running balance here - preserve the historical balances from full entries
    // The balances already reflect the true accumulation up to each entry's date

    // Update the filtered entries in the ledger controller
    ledgerController.filteredLedgerEntries.assignAll(filtered);
  }

  void handleRowSelection(int id, bool? selected) {
    if (selected == true) {
      selectedRows.add(id);
    } else {
      selectedRows.remove(id);
    }

    if (selectedRows.length == ledgerController.filteredLedgerEntries.length) {
      selectAll.value = true;
    } else {
      selectAll.value = false;
    }
  }

  void handleSelectAll(bool? selected) {
    selectAll.value = selected ?? false;
    if (selectAll.value) {
      selectedRows.assignAll(
        ledgerController.filteredLedgerEntries.map((e) => e.id!),
      );
    } else {
      selectedRows.clear();
    }
  }

  double get totalDebit {
    return ledgerController.filteredLedgerEntries.fold(
      0.0,
      (sum, entry) => sum + entry.debit,
    );
  }

  double get totalCredit {
    return ledgerController.filteredLedgerEntries.fold(
      0.0,
      (sum, entry) => sum + entry.credit,
    );
  }

  double get netBalance {
    if (ledgerController.filteredLedgerEntries.isEmpty) return 0.0;

    // ALTERNATIVE FIX: Calculate net balance from the original entries
    // Find the most recent entry in the original (chronologically sorted) list
    final allEntries = ledgerController.ledgerEntries;
    if (allEntries.isEmpty) return 0.0;

    // Sort by date descending to get the most recent entry
    allEntries.sort((a, b) => b.date.compareTo(a.date));
    return allEntries.first.balance;
  }

  void analyzeCalculations() {
    final entries = ledgerController.filteredLedgerEntries;
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
