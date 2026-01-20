// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';
import 'package:ledger_master/core/utils/data_grid_extension.dart';
import 'package:ledger_master/core/utils/responsive.dart';
import 'package:ledger_master/core/utils/sentry_helper.dart';
import 'package:ledger_master/features/automation/automation_screen.dart';
import 'package:ledger_master/features/cans/cans_controller.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/inventory/inventory_repository.dart';
import 'package:ledger_master/features/sales_invoicing/invoice_generator.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
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
    customerController.fetchCustomers();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              backgroundColor: isDark
                  ? Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.3)
                  : const Color(
                      0xFFFFF59D,
                    ), // Soft yellow highlight for light theme
              fontWeight: FontWeight.w600,
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
        onBackButtonPressed: null,
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
                            style: Theme.of(context).textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText:
                                  'Search by ledger no, account, type, date, tags...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                                              ).colorScheme.onSurfaceVariant,
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
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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
                                childAspectRatio: isDesktop ? 2 : 1.4,
                              ),
                          itemCount: ledgerController.filteredLedgers.length,
                          itemBuilder: (context, index) {
                            final ledger =
                                ledgerController.filteredLedgers[index];
                            return Card(
                              elevation: isDark ? 4 : 0,
                              child: InkWell(
                                onTap: () async {
                                  try {
                                    SentryHelper.breadcrumbUIAction(
                                      action: 'Click ledger card',
                                      page: 'LedgerHome',
                                      data: {
                                        'ledgerNo': ledger.ledgerNo,
                                        'accountName': ledger.accountName,
                                        'accountId': ledger.accountId,
                                      },
                                    );

                                    // Show loading dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Loading Ledger...',
                                          ),
                                          content: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text('Fetching ledger data...'),
                                            ],
                                          ),
                                        );
                                      },
                                    );

                                    // Fetch fresh ledger data with timeout
                                    final freshLedger = await LedgerRepository()
                                        .getLedgerByNumber(ledger.ledgerNo)
                                        .timeout(
                                          const Duration(seconds: 15),
                                          onTimeout: () {
                                            throw TimeoutException(
                                              'Failed to fetch ledger after 15 seconds',
                                            );
                                          },
                                        );

                                    if (!context.mounted) return;

                                    // Get customer by ID (more reliable than by name)
                                    Customer? customer;
                                    if (ledger.accountId != null) {
                                      customer = await CustomerRepository()
                                          .getCustomer(
                                            ledger.accountId.toString(),
                                          )
                                          .timeout(
                                            const Duration(seconds: 15),
                                            onTimeout: () => null,
                                          );
                                    }

                                    // Fallback to name lookup if ID fails
                                    customer ??= await CustomerRepository()
                                        .getCustomerByName(ledger.accountName)
                                        .timeout(
                                          const Duration(seconds: 15),
                                          onTimeout: () => null,
                                        );

                                    if (!context.mounted) return;

                                    // Close loading dialog
                                    Navigator.of(context).pop();

                                    // Navigate
                                    if (customer != null) {
                                      SentryHelper.breadcrumbNavigation(
                                        from: 'LedgerHome',
                                        to: 'LedgerTablePage',
                                        data: {
                                          'ledgerNo': ledger.ledgerNo,
                                          'customerId': customer.id,
                                        },
                                      );

                                      NavigationHelper.push(
                                        context,
                                        LedgerTablePage(
                                          ledger: freshLedger ?? ledger,
                                          customer: customer,
                                        ),
                                      );
                                    } else {
                                      SentryHelper.breadcrumbUIAction(
                                        action: 'Customer not found',
                                        page: 'LedgerHome',
                                        data: {
                                          'ledgerNo': ledger.ledgerNo,
                                          'accountId': ledger.accountId,
                                          'accountName': ledger.accountName,
                                        },
                                      );

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            title: const Text(
                                              '⚠️ Customer Not Found',
                                            ),
                                            content: Text(
                                              'Ledger references customer:\n'
                                              'ID: ${ledger.accountId}\n'
                                              'Name: ${ledger.accountName}\n\n'
                                              'But customer no longer exists in database.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  dialogContext,
                                                ).pop(),
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  } on TimeoutException catch (e) {
                                    if (!context.mounted) return;

                                    // Close loading dialog if still open
                                    try {
                                      Navigator.of(context).pop();
                                    } catch (_) {}

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text('⏱️ Timeout Error'),
                                          content: Text(
                                            'Operation took too long:\n\n${e.message}',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    debugPrint('❌ Timeout Error: ${e.message}');
                                  } catch (e, stackTrace) {
                                    if (!context.mounted) return;

                                    // Close loading dialog if still open
                                    try {
                                      Navigator.of(context).pop();
                                    } catch (_) {}

                                    SentryHelper.captureException(
                                      exception: e,
                                      stackTrace: stackTrace,
                                      context: 'LedgerHome.ledgerCardClick',
                                      data: {
                                        'ledgerNo': ledger.ledgerNo,
                                        'accountId': ledger.accountId,
                                        'accountName': ledger.accountName,
                                      },
                                    );

                                    showDialog(
                                      context: context,
                                      builder: (BuildContext dialogContext) {
                                        return AlertDialog(
                                          title: const Text(
                                            '❌ Error Loading Ledger',
                                          ),
                                          content: SingleChildScrollView(
                                            child: Text(
                                              'Error: ${e.toString()}\n\nStack: ${stackTrace.toString()}',
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                    debugPrint(
                                      '❌ Error navigating to ledger:\nError: $e\nStack: $stackTrace',
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.table_chart,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    buildHighlightedText(
                                                      'Ledger No: ${ledger.ledgerNo}',
                                                      ledgerController
                                                          .searchQuery
                                                          .value,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    buildHighlightedText(
                                                      'Created: ${DateFormat('dd-MM-yyyy').format(ledger.createdAt)}',
                                                      ledgerController
                                                          .searchQuery
                                                          .value,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Divider(
                                            height: 8,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    buildHighlightedText(
                                                      'Name: ${ledger.accountName}',
                                                      ledgerController
                                                          .searchQuery
                                                          .value,
                                                    ),
                                                    const SizedBox(height: 3),

                                                    buildHighlightedText(
                                                      'Type: ${ledger.transactionType}',
                                                      ledgerController
                                                          .searchQuery
                                                          .value,
                                                    ),
                                                    const SizedBox(height: 3),

                                                    if (ledger.description !=
                                                        null) ...[
                                                      const SizedBox(height: 3),
                                                      buildHighlightedText(
                                                        'Desc: ${ledger.description}',
                                                        ledgerController
                                                            .searchQuery
                                                            .value,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  deleteButton(
                                                    context: context,
                                                    onPressed: () {
                                                      confirmDeleteDialog(
                                                        onConfirm: () {
                                                          ledgerController
                                                              .deleteLedger(
                                                                ledger.id!,
                                                              );
                                                        },
                                                        context: context,
                                                      );
                                                    },
                                                  ),
                                                  editButton(
                                                    context: context,
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
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'ledger-fab',
                onPressed: () async {
                  if (customerController.customers.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please add customers/vendors first.',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                color: Theme.of(context).colorScheme.onError,
                              ),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => BaseLayout(
        showBackButton: false,
        onBackButtonPressed: null,
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: isDark ? 4 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isDark
                            ? LinearGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.2),
                                  Theme.of(context).colorScheme.surface,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                      ),
                      child: isDesktop
                          ? buildDesktopLayout()
                          : buildMobileLayout(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  controller.isLedgerExists.value
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.error,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Theme.of(context).colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'A ledger already exists for ${controller.accountNameController.text}. Please choose a different name or check your existing ledgers to avoid duplication.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                controller.clearForm();
                                NavigationHelper.pop(context);
                              },
                              child: Text(
                                'Cancel',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => controller.saveLedger(
                                context,
                                ledger: widget.ledger,
                              ),
                              child: Text(
                                'Save',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  decoration: InputDecoration(
                    labelText: 'Account Name',
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
                          child: Text(
                            cust.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (cust) async {
                    if (cust != null) {
                      final balance = await CustomerRepository()
                          .getOpeningBalanceForCustomer(cust.name);

                      controller.accountNameController.text = cust.name;
                      controller.accountIdController.text =
                          cust.id?.toString() ?? '';
                      controller.debitController.text = '0.00';
                      controller.creditController.text = balance.toString();
                      controller.balanceController.text = balance.toString();
                      controller.isLedgerExists.value = await controller.repo
                          .ledgerExistsForCustomer(cust.name);
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
                style: Theme.of(context).textTheme.bodyMedium,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  labelText: 'Transaction Type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Debit', 'Credit']
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(
                          t,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
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
                    suffixIcon: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  child: Text(
                    DateFormat(
                      'dd-MM-yyyy',
                    ).format(controller.selectedDate.value),
                    style: Theme.of(context).textTheme.bodyMedium,
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
                style: Theme.of(context).textTheme.bodyMedium,
                dropdownColor: Theme.of(context).colorScheme.surface,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['Debit', 'Credit']
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s,
                        child: Text(
                          s,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
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
            style: Theme.of(context).textTheme.bodyMedium,
            dropdownColor: Theme.of(context).colorScheme.surface,
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
                    child: Text(
                      cust.name,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
                .toList(),
            onChanged: (cust) async {
              if (cust != null) {
                final balance = await CustomerRepository()
                    .getOpeningBalanceForCustomer(cust.name);

                controller.accountNameController.text = cust.name;
                controller.accountIdController.text = cust.id?.toString() ?? '';
                controller.debitController.text = '0.00';
                controller.creditController.text = balance.toString();
                controller.balanceController.text = balance.toString();
                controller.isLedgerExists.value = await controller.repo
                    .ledgerExistsForCustomer(cust.name);
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
          style: Theme.of(context).textTheme.bodyMedium,
          dropdownColor: Theme.of(context).colorScheme.surface,
          decoration: InputDecoration(
            labelText: 'Transaction Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: ['Debit', 'Credit']
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t,
                  child: Text(t, style: Theme.of(context).textTheme.bodyMedium),
                ),
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
              suffixIcon: Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            child: Text(
              DateFormat('dd-MM-yyyy').format(controller.selectedDate.value),
              style: Theme.of(context).textTheme.bodyMedium,
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
          style: Theme.of(context).textTheme.bodyMedium,
          dropdownColor: Theme.of(context).colorScheme.surface,
          decoration: InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: ['Debit', 'Credit']
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: Theme.of(context).textTheme.bodyMedium),
                ),
              )
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
  final Customer customer;

  const LedgerTablePage({
    super.key,
    required this.ledger,
    required this.customer,
  });
  LedgerTableController get controller => Get.find<LedgerTableController>();
  @override
  Widget build(BuildContext context) {
    final ledgerController = Get.find<LedgerController>();

    // Compute net balance locally to avoid side effects in getter (sort + refresh during build)
    // ignore: unused_local_variable
    double netBal = controller.openingBalance;
    final entries = controller.filteredLedgerEntries.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    for (final entry in entries) {
      final debitAmount = safeParseDouble(entry.debit);
      final creditAmount = safeParseDouble(entry.credit);
      // ✅ FIXED: Balance = previous + credit - debit
      netBal += creditAmount - debitAmount;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.isLoading.value = true;

      try {
        debugPrint('=== LEDGER TABLE PAGE INIT ===');

        // 1. Fetch fresh ledger data first
        final freshLedger = await controller.refreshLedgerData(ledger.ledgerNo);
        final ledgerToUse = freshLedger ?? ledger;

        debugPrint('Using ledger: ${ledgerToUse.ledgerNo}');
        debugPrint(
          'Fresh totals - Debit: ${ledgerToUse.debit}, Credit: ${ledgerToUse.credit}, Balance: ${ledgerToUse.balance}',
        );

        // 2. Fetch opening balance
        await controller.fetchOpeningBalanceIfNeeded(ledgerToUse.accountName);

        // 3. Load ledger entries
        await controller.loadLedgerEntries(ledgerToUse.ledgerNo);

        // 4. Fetch ledger entries for controller
        await ledgerController.fetchLedgerEntries(ledgerToUse.ledgerNo);

        // 5. Calculate totals immediately after loading
        await controller.calculateTotals(
          customerID: customer.id.toString(),
          customerName: customer.name,
        );

        // 6. Update reactive totals
        controller._updateReactiveTotals();

        debugPrint('=== LEDGER TABLE PAGE LOADED ===');
        debugPrint('Total entries: ${controller.filteredLedgerEntries.length}');
        debugPrint('Calculated totals: ${controller.map.value}');

        // 7. Scroll to bottom if entries exist
        if (controller.filteredLedgerEntries.isNotEmpty) {
          final lastIndex = controller.filteredLedgerEntries.length - 1;
          Future.delayed(Duration(milliseconds: 500), () async {
            await controller.dataGridController.scrollToRow(
              canAnimate: true,
              lastIndex.toDouble() + 1.0,
            );
          });
        }
      } catch (e) {
        debugPrint('❌ Error loading ledger data: $e');
      } finally {
        controller.isLoading.value = false;
      }
    });

    // Listen for when the page becomes visible again (after returning from add/edit)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: deprecated_member_use
      ModalRoute.of(context)?.addScopedWillPopCallback(() async {
        // This runs when returning to this page
        debugPrint('Returning to LedgerTablePage - refreshing data...');
        await controller.refreshLedgerData(ledger.ledgerNo);
        await controller.loadLedgerEntries(ledger.ledgerNo);
        await ledgerController.fetchLedgerEntries(ledger.ledgerNo);
        await controller.calculateTotals(
          customerID: customer.id.toString(),
          customerName: customer.name,
        );
        controller._updateReactiveTotals();
        return true;
      });
    });

    return BaseLayout(
      showBackButton: true,
      appBarTitle: "Ledger Entries of: ${ledger.accountName}",
      onBackButtonPressed: () {
        NavigationHelper.pushReplacement(context, LedgerHome());
      },
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
        // Compute net balance locally to avoid side effects in getter (sort + refresh during build)
        // double netBal = controller.openingBalance;
        final entries = controller.filteredLedgerEntries.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        for (final entry in entries) {
          final debitAmount = safeParseDouble(entry.debit);
          final creditAmount = safeParseDouble(entry.credit);
          final isDebit = entry.transactionType.toLowerCase() == 'debit';
          netBal += isDebit ? debitAmount : -creditAmount;
        }
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
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: "Search by Voucher No, Date or Ref No",
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
                      initialValue: ledger.accountName,
                      readOnly: true,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "Ledger Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.selectedTransactionType.value,
                      style: Theme.of(context).textTheme.bodyMedium,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(
                            "All Types",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Debit",
                          child: Text(
                            "Debit",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        DropdownMenuItem(
                          value: "Credit",
                          child: Text(
                            "Credit",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        controller.selectedTransactionType.value = value;
                      },
                      decoration: InputDecoration(
                        labelText: "Transaction Type",
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
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "From Date",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
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
                      style: Theme.of(context).textTheme.bodyMedium,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "To Date",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () =>
                              controller.selectDate(context, false),
                        ),
                      ),
                      onTap: () => controller.selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Refresh Button
                  ExportHelper.exportButton<LedgerEntry>(
                    context: context,
                    data: controller.filteredLedgerEntries,
                    fileName:
                        'Ledger entries for ${ledger.accountName} from ${controller.fromDateController.text} to ${controller.toDateController.text}',
                    tooltip:
                        'Export Ledger from ${controller.fromDateController.text} to ${controller.toDateController.text}',
                    customExtractor: LedgerEntry.createExtractor(),
                  ),
                  // IconButton(
                  //   onPressed: () async {
                  //     controller.isLoading.value = true;
                  //     await controller.loadLedgerEntries(ledger.ledgerNo);
                  //     await ledgerController.fetchLedgerEntries(
                  //       ledger.ledgerNo,
                  //     );
                  //     controller.isLoading.value = false;
                  //   },
                  //   icon: Icon(Icons.refresh),
                  //   tooltip: "Refresh Data",
                  // ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: 'ledger-fab',
                    onPressed: () async {
                      // Ensure all data is fresh before opening add entry dialog
                      controller.isLoading.value = true;
                      try {
                        // Refresh ledger data first
                        await controller.refreshLedgerData(ledger.ledgerNo);
                        await controller.loadLedgerEntries(ledger.ledgerNo);
                        await ledgerController.fetchLedgerEntries(
                          ledger.ledgerNo,
                        );
                      } catch (e) {
                        debugPrint('Error loading entries: $e');
                      } finally {
                        controller.isLoading.value = false;
                      }

                      if (context.mounted) {
                        // Get the latest ledger from controller (or use the original)
                        // The controller.currentLedger should now be defined
                        final currentLedger =
                            controller.currentLedger ?? ledger;

                        // ✅ Navigate to add/edit page
                        await NavigationHelper.push(
                          context,
                          LedgerEntryAddEdit(
                            ledgerNo: currentLedger.ledgerNo,
                            accountId: currentLedger.accountId!.toString(),
                            accountName: currentLedger.accountName,
                            customer: customer,
                            ledger: currentLedger, // Use the current ledger
                            onEntrySaved: () async {
                              // This callback runs when entry is saved
                              controller.isLoading.value = true;
                              try {
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );

                                // Refresh ALL data with fresh ledger
                                await controller.refreshLedgerData(
                                  ledger.ledgerNo,
                                );
                                await controller.loadLedgerEntries(
                                  ledger.ledgerNo,
                                );
                                await ledgerController.fetchLedgerEntries(
                                  ledger.ledgerNo,
                                );
                                await controller.calculateTotals(
                                  customerID: customer.id.toString(),
                                  customerName: customer.name,
                                );
                                controller._updateReactiveTotals();

                                // Also refresh the main ledger list
                                await ledgerController.fetchLedgers();
                              } catch (e) {
                                debugPrint('Error refreshing after save: $e');
                              } finally {
                                controller.isLoading.value = false;
                              }
                            },
                          ),
                        );

                        // ✅ After returning from add/edit page, refresh data again
                        controller.isLoading.value = true;
                        try {
                          await controller.refreshLedgerData(ledger.ledgerNo);
                          await controller.loadLedgerEntries(ledger.ledgerNo);
                          await controller.calculateTotals(
                            customerID: customer.id.toString(),
                            customerName: customer.name,
                          );
                          controller._updateReactiveTotals();
                        } catch (e) {
                          debugPrint('Error refreshing after navigation: $e');
                        } finally {
                          controller.isLoading.value = false;
                        }
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
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : Expanded(
                    child: SfDataGrid(
                      source: LedgerEntryDataSource(
                        controller.filteredLedgerEntries,
                        context,
                        onPrint: (entry, index) => printEntry(entry, index),
                        onDelete: (entry) =>
                            deleteEntry(controller, entry, context),
                        netBalance: controller.netBalance,
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
                      onCellTap: (DataGridCellTapDetails details) {
                        if (details.rowColumnIndex.rowIndex > 0) {
                          final entry =
                              controller.filteredLedgerEntries[details
                                      .rowColumnIndex
                                      .rowIndex -
                                  1];
                          showLedgerEntryDialog(context, entry);
                        }
                      },
                      // optional: persist width after resize ends (not strictly necessary)
                      onColumnResizeEnd: (ColumnResizeEndDetails details) {
                        final colName = details.column.columnName;
                        controller.columnWidths[colName] = details.width;
                      },
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
              width: MediaQuery.of(context).size.width,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Obx(
                  () => controller.calculatingTotals.value
                      ? SizedBox.shrink()
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            controller.map.value['openingBalance'] != 0
                                ? totalBox(
                                    "Opening Bal",
                                    controller.map.value['openingBalance']!,
                                    context,
                                  )
                                : SizedBox.shrink(),
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                controller.calculateTotals(
                                  customerID: customer.id.toString(),
                                  customerName: customer.name,
                                );
                              },
                              child: totalBox(
                                "Credit",
                                controller.map.value['credit']!,
                                context,
                              ),
                            ),
                            const SizedBox(width: 16),
                            totalBox(
                              "Debit",
                              controller.map.value['debit']!,
                              context,
                            ),
                            const SizedBox(width: 16),
                            totalBox(
                              "Net Balance",
                              controller.map.value['netBalance']!,
                              context,
                            ),
                          ],
                        ),
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
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

  Future<void> printEntry(LedgerEntry entry, int index) async {
    final ledgerTableController = Get.find<LedgerTableController>();
    final ledgerController = ledgerTableController.ledgerController;
    final customerController = Get.find<CustomerController>();
    final allEntries = ledgerController.ledgerEntries;
    final voucherNo = entry.voucherNo;

    // Get all entries with the same voucher number
    final voucherEntries = allEntries
        .where((e) => e.voucherNo == voucherNo)
        .toList();

    // Create receipt items from all voucher entries
    final items = voucherEntries.map((e) {
      return ReceiptItem(
        name: e.itemName ?? 'Unknown Item',
        price: e.itemPricePerUnit ?? 0,
        canQuantity: e.cansQuantity ?? 0,
        type: e.transactionType,
        description: e.description ?? '',
        amount: safeParseDouble(e.debit) > 0
            ? safeParseDouble(e.debit)
            : safeParseDouble(e.credit),
      );
    }).toList();

    var customer = await customerController.repo.getCustomer(
      ledger.accountId!.toString(),
    );

    // ✅ UPDATED: Use entry data directly for cans
    // Current cans = sum of cansQuantity from all entries with this voucher
    double currentCans = 0.0;
    for (var voucherEntry in voucherEntries) {
      currentCans += safeParseDouble(voucherEntry.cansQuantity ?? 0);
    }

    // Previous cans = balanceCans from BEFORE this transaction (from the entry before first voucher entry)
    // Find the index of the first entry with this voucher
    final voucherIndex = allEntries.indexWhere((e) => e.voucherNo == voucherNo);
    double previousCans = 0.0;
    if (voucherIndex > 0) {
      // Get balance cans from the entry before this voucher
      previousCans = safeParseDouble(
        allEntries[voucherIndex - 1].balanceCans ?? 0,
      );
    }

    // Total cans = previous + current
    final totalCans = previousCans + currentCans;

    // Received cans = 0 (not used in simple calculation)
    final receivedCans = 0.0;

    // Balance cans = total - received
    final balanceCans = totalCans - receivedCans;

    // Compute previous monetary amount based on date (using all entries)
    double previousAmount = ledgerTableController.openingBalance;
    final thisDate = entry.date;
    for (final prevEntry in allEntries) {
      if (prevEntry.date.isBefore(thisDate)) {
        final debitAmt = safeParseDouble(prevEntry.debit);
        final creditAmt = safeParseDouble(prevEntry.credit);
        previousAmount += creditAmt - debitAmt;
      }
    }

    // Sums for voucher
    final totalDebit = voucherEntries.fold(
      0.0,
      (sum, e) => sum + safeParseDouble(e.debit),
    );
    final totalCredit = voucherEntries.fold(
      0.0,
      (sum, e) => sum + safeParseDouble(e.credit),
    );

    // ✅ Net balance calculation: Opening + Credit - Debit (same as customer ledger)
    final netBalance =
        ledgerTableController.openingBalance +
        ledgerTableController.totalCredit -
        ledgerTableController.totalDebit;
    // Current amount from this transaction
    final currentAmount = totalDebit + totalCredit;

    // Ensure no negative values
    final displayPreviousAmount = previousAmount < 0 ? 0.0 : previousAmount;
    final displayCurrentAmount = currentAmount < 0 ? 0.0 : currentAmount;
    final displayNetBalance = netBalance < 0 ? 0.0 : netBalance;
    final displayPreviousCans = previousCans < 0 ? 0.0 : previousCans;
    final displayCurrentCans = currentCans < 0 ? 0.0 : currentCans;
    final displayTotalCans = totalCans < 0 ? 0.0 : totalCans;
    final displayBalanceCans = balanceCans < 0 ? 0.0 : balanceCans;

    final data = ReceiptData(
      companyName: 'NAZ ENTERPRISES',
      date: DateFormat('dd/MM/yyyy').format(entry.date),
      customerName: ledger.accountName,
      customerAddress: customer?.address ?? '',
      vehicleNumber: entry.referenceNo ?? 'N/A',
      items: items,
      previousCans: displayPreviousCans,
      currentCans: displayCurrentCans,
      totalCans: displayTotalCans,
      receivedCans: receivedCans,
      balanceCans: displayBalanceCans,
      currentAmount: displayCurrentAmount,
      previousAmount: displayPreviousAmount,
      netBalance: displayNetBalance,
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
          customer: customer,
          ledger: ledger,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Entry deleted',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
  final double netBalance;

  // Store the original entries to reference them later
  final List<LedgerEntry> _originalEntries;

  LedgerEntryDataSource(
    List<LedgerEntry> entries,
    this.context, {
    required this.onPrint,
    required this.onDelete,
    required this.onEdit,
    required this.netBalance,
  }) : _originalEntries = entries {
    // Calculate running balance for credit amounts
    double runningBalance = 0;

    _rows = entries.asMap().entries.map((entryWithIndex) {
      final entry = entryWithIndex.value;
      final index = entryWithIndex.key;

      // Calculate running balance for credit amounts
      runningBalance += entry.credit;
      final balanceValue = runningBalance;

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
          DataGridCell(columnName: 'balance', value: balanceValue),
          // Store the index or a reference to identify which entry this row represents
          DataGridCell(columnName: '_entryIndex', value: index),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    // Find the index of the entry from the hidden cell
    final indexCell = row.getCells().firstWhere(
      (cell) => cell.columnName == '_entryIndex',
      orElse: () => DataGridCell(columnName: '_entryIndex', value: -1),
    );

    final entryIndex = indexCell.value as int;
    final entry = _originalEntries[entryIndex];

    bool isHovered = false;

    return DataGridRowAdapter(
      cells: row
          .getCells()
          .where((cell) => cell.columnName != '_entryIndex')
          .map((cell) {
            final isLastCell =
                cell.columnName ==
                'balance'; // Now balance is the last visible cell

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                            ),
                            child: Text(
                              NumberFormat(
                                '#,##0',
                                'en_US',
                              ).format(cell.value ?? 0),
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
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
                                // Tooltip(
                                //   message: "print",
                                //   child: InkWell(
                                //     borderRadius: BorderRadius.circular(14),
                                //     onTap: () => onPrint(entry, rowIndex),
                                //     child: Padding(
                                //       padding: const EdgeInsets.only(
                                //         right: 4.0,
                                //       ),
                                //       child: Icon(
                                //         Icons.print_outlined,
                                //         size: 16,
                                //         color: Theme.of(
                                //           context,
                                //         ).colorScheme.primary,
                                //       ),
                                //     ),
                                //   ),
                                // ),
                                Tooltip(
                                  message: "delete",
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => confirmDeleteDialog(
                                      onConfirm: () => onDelete(entry),
                                      context: context,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 4.0,
                                      ),
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
                                    onTap: () => onEdit(entry),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 4.0,
                                      ),
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
                      ? NumberFormat('#,##0', 'en_US').format(cell.value ?? 0)
                      : cell.value.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight:
                        cell.columnName == 'debit' ||
                            cell.columnName == 'credit'
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }
}

class LedgerTableController extends GetxController {
  Ledger? currentLedger;
  LedgerController get ledgerController => Get.find<LedgerController>();
  final DataGridController dataGridController = DataGridController();
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final searchController = TextEditingController();
  final selectedRows = <int>{}.obs;
  final selectAll = false.obs;
  final selectedTransactionType = RxnString();
  final isLoading = false.obs;
  final calculatingTotals = false.obs;
  final isFetchingCustomer = false.obs;
  final calculationAnalysis = ''.obs;
  final showCalculationAnalysis = false.obs;
  final searchQuery = ''.obs;
  final fromDate = Rx<DateTime>(DateTime.now().subtract(Duration(days: 30)));
  final toDate = Rx<DateTime>(DateTime.now());
  final filteredLedgerEntries = <LedgerEntry>[].obs;
  final RxMap<String, double> columnWidths = <String, double>{}.obs;
  final CustomerRepository repo = CustomerRepository();

  var openingBalance = 0.0; // 👈 cache value for sync access
  Customer? customer;
  RxMap<String, double> map = <String, double>{
    'openingBalance': 0.0,
    'debit': 0.0,
    'credit': 0.0,
    'netBalance': 0.0,
    'customerLedgerDebit': 0.0,
  }.obs;
  // Add reactive totals to trigger UI updates
  final RxDouble rxTotalDebit = 0.0.obs;
  final RxDouble rxTotalCredit = 0.0.obs;
  final RxDouble rxNetBalance = 0.0.obs;

  // optional helper to set a default width only if not already set
  void ensureColumnWidth(String columnName, double width) {
    if (!columnWidths.containsKey(columnName)) {
      columnWidths[columnName] = width;
    }
  }

  Future<Ledger?> refreshLedgerData(String ledgerNo) async {
    try {
      final ledgerController = Get.find<LedgerController>();
      final freshLedger = await ledgerController.repo.getLedgerByNumber(
        ledgerNo,
      );
      if (freshLedger != null) {
        currentLedger = freshLedger; // <-- Use .value for Rx variables
        debugPrint('✅ Refreshed ledger data: ${freshLedger.ledgerNo}');
        debugPrint(
          '   Debit: ${freshLedger.debit}, Credit: ${freshLedger.credit}, Balance: ${freshLedger.balance}',
        );
      }
      return freshLedger;
    } catch (e) {
      debugPrint('❌ Error refreshing ledger data: $e');
      return null;
    }
  }

  Future<void> calculateTotals({
    required String customerName,
    required String customerID,
  }) async {
    debugPrint('=== CALCULATE TOTALS START ===');
    debugPrint('Customer: $customerName, ID: $customerID');

    calculatingTotals.value = true;

    try {
      // ✅ Add delay to ensure database is ready
      await Future.delayed(const Duration(milliseconds: 200));

      // ✅ Get fresh data from database
      map.value = await BalanceCalculator.getCustomerBalanceData(
        customerName: customerName,
        customerType: 'customer',
        customerId: int.parse(customerID),
      );

      debugPrint('=== CALCULATE TOTALS RESULT ===');
      debugPrint('Opening Balance: ${map.value['openingBalance']}');
      debugPrint('Credit: ${map.value['credit']}');
      debugPrint('Debit: ${map.value['debit']}');
      debugPrint('Net Balance: ${map.value['netBalance']}');
      debugPrint('Customer Ledger Debit: ${map.value['customerLedgerDebit']}');
    } catch (e) {
      debugPrint('❌ Error calculating totals: $e');
      // Set default values on error
      map.value = {
        'openingBalance': 0.0,
        'debit': 0.0,
        'credit': 0.0,
        'netBalance': 0.0,
        'customerLedgerDebit': 0.0,
      };
    } finally {
      calculatingTotals.value = false;
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
    ever(searchQuery, (_) {
      _applyFilters();
      _updateReactiveTotals();
    });
    ever(fromDate, (_) {
      _applyFilters();
      _updateReactiveTotals();
    });
    ever(toDate, (_) {
      _applyFilters();
      _updateReactiveTotals();
    });
    ever(selectedTransactionType, (_) {
      _applyFilters();
      _updateReactiveTotals();
    });
    ever(filteredLedgerEntries, (_) {
      _updateReactiveTotals();
    });
    // Apply initial filters
    _applyFilters();
    _updateReactiveTotals();
    currentLedger = null; // <-- Add this line
  }

  Future<void> getcustomer(String accountName) async {
    isFetchingCustomer.value = true;
    debugPrint('called');
    debugPrint('${isFetchingCustomer.value}');

    customer = await CustomerRepository().getCustomerByName(accountName);
    isFetchingCustomer.value = false;
    debugPrint('${isFetchingCustomer.value}');
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

  void _updateReactiveTotals() {
    rxTotalDebit.value = totalDebit;
    rxTotalCredit.value = totalCredit;
    rxNetBalance.value = netBalance;
  }

  Future<void> loadLedgerEntries(String ledgerNo) async {
    isLoading.value = true;
    try {
      // Clear old data first to force fresh load
      filteredLedgerEntries.clear();
      ledgerController.ledgerEntries.clear();

      // Fetch fresh data from database
      await ledgerController.fetchLedgerEntries(ledgerNo);

      // Reapply filters to update filteredLedgerEntries with new data
      _applyFilters();

      // Update reactive totals to trigger UI rebuild
      _updateReactiveTotals();

      // Calculate running balance after fetching entries
      calculateRunningBalance(ledgerNo);
    } catch (e) {
      debugPrint('Error loading ledger entries: $e');
    } finally {
      isLoading.value = false;
    }
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
      // ✅ FIXED: Balance = previous + credit - debit
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
        fromDateController.text = DateFormat('dd-MM-yyyy').format(picked);
        fromDate.value = picked; // ✅ This triggers the ever() listener
      } else {
        toDateController.text = DateFormat('dd-MM-yyyy').format(picked);
        toDate.value = picked; // ✅ This triggers the ever() listener
      }
      // ✅ Force immediate filter update
      _applyFilters();
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

  Future<void> fetchOpeningBalanceIfNeeded(String accountName) async {
    try {
      final result = await repo.getOpeningBalanceForCustomer(accountName);
      openingBalance = result;
      update(); // refresh UI if using GetBuilder
    } catch (e) {
      openingBalance = 0.0;
    }
  }

  double get totalDebit {
    // ✅ Use ALL ledger entries, not filtered ones (for accurate totals)
    return ledgerController.ledgerEntries.fold(
      0.0,
      (sum, entry) => sum + entry.debit,
    );
  }

  double get totalCredit {
    // ✅ Use ALL ledger entries, not filtered ones (for accurate totals)
    return ledgerController.ledgerEntries.fold(
      0.0,
      (sum, entry) => sum + entry.credit,
    );
  }

  double get netBalance {
    // ✅ FIXED: Net Balance = Opening Balance + Total Credit - Total Debit
    return openingBalance + totalCredit;
  }

  double get balanceCans {
    // Fetch cans data from the cans table for this customer
    final cansController = Get.find<CansController>();
    final ledger = ledgerController.ledgers.isNotEmpty
        ? ledgerController.ledgers.first
        : null;
    if (ledger == null) return 0.0;

    final cansRecord = cansController.getCansForCustomer(
      int.tryParse(ledger.accountId.toString()) ?? 0,
    );

    // Return the balance from the cans table for this customer
    // If no cans record exists, return 0
    return cansRecord?.totalCans ?? 0.0;
  }

  void analyzeCalculations() {
    final entries = filteredLedgerEntries;
    String analysis = "Calculation Analysis:\n\n";
    analysis += "All Entries:\n";
    for (var entry in entries) {
      analysis +=
          "Voucher: ${entry.voucherNo} | Debit: ${NumberFormat('#,##0', 'en_US').format(entry.debit)} | Credit: ${NumberFormat('#,##0', 'en_US').format(entry.credit)} | Balance: ${NumberFormat('#,##0', 'en_US').format(entry.balance)}\n";
    }
    analysis += "\nTotals:\n";
    analysis +=
        "Total Debit: ${NumberFormat('#,##0', 'en_US').format(totalDebit)}\n";
    analysis +=
        "Total Credit: ${NumberFormat('#,##0', 'en_US').format(totalCredit)}\n";
    analysis +=
        "Net Balance: ${NumberFormat('#,##0', 'en_US').format(netBalance)}\n\n";
    // Calculate expected net balance (credits only)
    double calculatedNetBalance = entries.fold(
      0.0,
      (sum, entry) => sum + entry.credit,
    );
    analysis +=
        "Calculated Net Balance (Sum of Credits): ${NumberFormat('#,##0', 'en_US').format(calculatedNetBalance)}\n";
    if ((netBalance - calculatedNetBalance).abs() < 0.01) {
      // Allow for floating point precision
      analysis += "✓ Balance calculation is CORRECT\n";
    } else {
      analysis += "✗ Balance calculation is INCORRECT\n";
      analysis +=
          "Difference: ${NumberFormat('#,##0', 'en_US').format(netBalance - calculatedNetBalance)}\n";
    }
    calculationAnalysis.value = analysis;
    showCalculationAnalysis.value = true;
  }
}

class LedgerController extends GetxController {
  final LedgerRepository repo;
  final InventoryRepository inventoryRepo = InventoryRepository();
  LedgerTableController get controller => Get.find<LedgerTableController>();
  final automationController = Get.put(AutomationController(), permanent: true);
  final CansRepository cansrepo = CansRepository();
  late final CansController cansController;
  final ledgers = <Ledger>[].obs;
  final filteredLedgers = <Ledger>[].obs;
  final ledgerEntries = <LedgerEntry>[].obs;
  final isDarkMode = true.obs;
  RxList<EntryFormData> entryForms = <EntryFormData>[].obs;
  final Map<String, int> _nextVoucherNums = <String, int>{};
  String? _sharedVoucherNo;
  final formKey = GlobalKey<FormState>();
  RxBool isLedgerExists = false.obs;
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
  // New cheque field controllers
  final chequeNoController = TextEditingController();
  final chequeAmountController = TextEditingController();
  final chequeDateController = TextEditingController();
  final bankNameController = TextEditingController();
  final selectedDate = DateTime.now().obs;
  final transactionType = RxnString();
  final status = RxnString();
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;
  final availableItems = <Item>[].obs;
  // Bank list for dropdown
  final List<String> bankList = [
    'Habib Bank Limited (HBL)',
    'United Bank Limited (UBL)',
    'MCB Bank Limited',
    'Allied Bank Limited (ABL)',
    'National Bank of Pakistan (NBP)',
    'Bank Alfalah',
    'Meezan Bank',
    'Faysal Bank',
    'Askari Bank',
    'Standard Chartered Bank (Pakistan)',
    'Bank of Punjab (BOP)',
    'Bank of Khyber',
    'Sindh Bank',
    'Habib Metropolitan Bank',
    'JS Bank',
    'Summit Bank',
    'First Women Bank Limited',
    'Dubai Islamic Bank Pakistan',
    'Samba Bank',
    'Soneri Bank',
    'Silk Bank',
  ];
  LedgerController(this.repo);
  double oldDebit = 0;
  double oldCredit = 0;
  RxDouble totalSales = 0.0.obs;
  RxDouble totalReceivables = 0.0.obs;
  RxList<Item> lowStockItems = <Item>[].obs;
  RxList<Map<String, dynamic>> expenseBreakdown = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> salesTrendLast6Months =
      <Map<String, dynamic>>[].obs;
  RxMap<String, double> expenses = <String, double>{}.obs;
  final List<String> monthShortNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
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
    cansController = Get.put(CansController(cansrepo), permanent: true);
  }

  // Add this method to clear cheque fields when switching to cash
  void clearChequeFields() {
    chequeNoController.clear();
    chequeAmountController.clear();
    chequeDateController.clear();
    bankNameController.clear();
  }

  // Add this method to clear cash fields when switching to cheque
  void clearCashFields() {
    // Add any cash-specific fields here if needed in future
  }
  Future<void> getStats() async {
    totalSales.value = await DBHelper().getTotalSales();
    totalReceivables.value = await DBHelper().getTotalReceivables();
    lowStockItems.value = await DBHelper().getTopThreeLowestStockItems();
    expenses.value = await DBHelper().getExpenseTotals();
    expenseBreakdown.value = await DBHelper().fetchExpenseBreakdown();
    salesTrendLast6Months.value = await DBHelper().fetchSalesTrendBetweenMonths(
      automationController.formattedFromMonth,
      automationController.formattedToMonth,
      type: 'both',
    );
  }

  Future<void> refreshItems() async {
    await fetchItems();
    update();
  }

  Future<void> addNewEntryForm(String ledgerNo) async {
    await fetchItems();
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
    newForm.paymentMethod.value = 'cash'; // Default to cash

    // Fetch all cans data first, then populate cans quantity from cans table for this customer
    await cansController.fetchCans();
    final accountId = parentLedger.accountId ?? 0;
    var cansRecord = cansController.getCansForCustomer(accountId);

    // Fallback: try by account name if accountId didn't work
    cansRecord ??= cansController.getCansForCustomerByName(
      parentLedger.accountName,
    );

    // Don't auto-fill cans quantity - user will enter this manually
    // if (cansRecord != null) {
    //   newForm.cansQuantityController.text = cansRecord.currentCans
    //       .toStringAsFixed(2);
    // }

    newForm.selectedItem.value = null;
    if (_sharedVoucherNo == null) {
      String voucherNo;
      if (_nextVoucherNums.containsKey(ledgerNo)) {
        final num = _nextVoucherNums[ledgerNo]!;
        voucherNo = 'VN${num.toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] = num + 1;
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
        _nextVoucherNums[ledgerNo] = num + 1;
      }
      _sharedVoucherNo = voucherNo;
    }
    newForm.voucherNoController.text = _sharedVoucherNo!;
    newForm.transactionType.value = "Debit";
    newForm.transactionTypeController.text = "Debit";
    newForm.status.value = "Debit";
    newForm.statusController.text = "Debit";
    await newForm._initPreviousBalance();
    entryForms.add(newForm);
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

  Future<void> selectChequeDateForForm(BuildContext context, int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: entryForms[index].chequeDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      entryForms[index].chequeDate.value = picked;
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
      final stockTx = StockTransaction(
        itemId: item.id!,
        quantity: weightChange.abs(),
        type: transactionType,
        date: DateTime.now(),
      );
      await inventoryRepo.insertStockTransaction(stockTx);
      await fetchItems();
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
      final newWeight = _calculateTotalWeight(newEntry);
      final weightChange = -newWeight;
      await updateItemStock(newItem, weightChange, 'OUT');
      return;
    }
    // Case 3: Item was changed or quantity/weight was modified
    if (oldEntry.itemId != null && newEntry.itemId != null) {
      if (oldEntry.itemId != newEntry.itemId) {
        final oldItem = availableItems.firstWhere(
          (item) => item.id == oldEntry.itemId,
          orElse: () => throw Exception('Item not found'),
        );
        final oldWeight = _calculateTotalWeight(oldEntry);
        final reverseWeight = oldWeight;
        await updateItemStock(oldItem, reverseWeight, 'IN');
        final newItem = availableItems.firstWhere(
          (item) => item.id == newEntry.itemId,
          orElse: () => throw Exception('Item not found'),
        );
        final newWeight = _calculateTotalWeight(newEntry);
        final weightChange = -newWeight;
        await updateItemStock(newItem, weightChange, 'OUT');
      } else if (oldEntry.cansQuantity != newEntry.cansQuantity ||
          oldEntry.canWeight != newEntry.canWeight) {
        final item = availableItems.firstWhere(
          (item) => item.id == newEntry.itemId,
          orElse: () => throw Exception('Item not found'),
        );
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
    final entry = ledgerEntries.firstWhere((e) => e.id == id);
    await repo.deleteLedgerEntry(id, ledgerNo);
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
    debugPrint('=== UPDATING LEDGER TOTALS ===');
    debugPrint('Ledger No: $ledgerNo');

    final ledger = ledgers.firstWhere((l) => l.ledgerNo == ledgerNo);
    final entries = await repo.getLedgerEntries(ledgerNo);

    final totalDebit = entries.fold<double>(0.0, (sum, e) => sum + e.debit);
    final totalCredit = entries.fold<double>(0.0, (sum, e) => sum + e.credit);
    final newBalance = totalCredit;

    debugPrint('Total Debit: $totalDebit');
    debugPrint('Total Credit: $totalCredit');
    debugPrint('New Balance: $newBalance');

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
      debugPrint('Updated ledger in list at index $index');
    }

    debugPrint('=== LEDGER TOTALS UPDATED ===');
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
    await fetchItems();
    final parentLedger = ledgers.firstWhere(
      (l) => l.ledgerNo == ledgerNo,
      orElse: () => throw Exception('Ledger with number $ledgerNo not found'),
    );
    entryForms.clear();
    _sharedVoucherNo = null;
    final newForm = EntryFormData();
    newForm.ledgerNoController.text = ledgerNo;
    newForm.accountNameController.text = parentLedger.accountName;
    newForm.accountIdController.text = parentLedger.accountId?.toString() ?? '';
    newForm.selectedDate.value = DateTime.now();
    newForm.currentStep.value = 0;
    newForm.paymentMethod.value = 'cash'; // Default to cash

    // Fetch cans data from the cans table for this customer
    final accountId = parentLedger.accountId;
    final cansRecord = accountId != null
        ? cansController.getCansForCustomer(accountId)
        : null;
    if (cansRecord != null) {
      newForm.balanceCans.text = cansRecord.totalCans.toStringAsFixed(2);
    } else {
      newForm.balanceCans.text = '0.00';
    }

    if (entry != null) {
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
      // Load payment method and cheque details if exists
      newForm.paymentMethod.value = entry.paymentMethod ?? 'cash';
      newForm.chequeNoController.text = entry.chequeNo ?? '';
      newForm.chequeAmountController.text =
          entry.chequeAmount?.toStringAsFixed(2) ?? '';
      newForm.chequeDate.value = entry.chequeDate;
      newForm.bankNameController.text = entry.bankName ?? '';
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
          newForm.selectedItem.value = null;
        }
      } else {
        newForm.selectedItem.value = null;
      }
      _sharedVoucherNo = entry.voucherNo;
    } else {
      newForm.originalEntry = null;
      newForm.transactionType.value = "Debit";
      newForm.transactionTypeController.text = "Debit";
      newForm.status.value = "Debit";
      newForm.statusController.text = "Debit";
      String voucherNo;
      if (_nextVoucherNums.containsKey(ledgerNo)) {
        final num = _nextVoucherNums[ledgerNo]!;
        voucherNo = 'VN${num.toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] = num + 1;
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
        _nextVoucherNums[ledgerNo] = num + 1;
      }
      newForm.voucherNoController.text = voucherNo;
      _sharedVoucherNo = voucherNo;
      await newForm._initPreviousBalance();
      entryForms.add(newForm);
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

  Future<SaveLedgerResult> saveAllLedgerEntries(
    BuildContext context, {
    required String ledgerNo,
  }) async {
    List<LedgerEntry> savedEntries = [];
    Future<Dialog?>? loadingDialogFuture;
    try {
      // First pass: Validate all forms without saving
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
          return SaveLedgerResult(ledgerEntries: [], receiptItems: []);
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
            return SaveLedgerResult(ledgerEntries: [], receiptItems: []);
          }
        }
      }
      // All validations passed, now show loading dialog
      if (context.mounted) {
        loadingDialogFuture = showDialog<Dialog?>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('Saving entries...'),
                ],
              ),
            );
          },
        );
      }
      if (_sharedVoucherNo == null) {
        final lastVoucherNo = await repo.getLastVoucherNo(ledgerNo);
        final regex = RegExp(r'VN(\d+)');
        final match = regex.firstMatch(lastVoucherNo);
        int maxNum = 0;
        if (match != null) {
          maxNum = int.tryParse(match.group(1)!) ?? 0;
        }
        _sharedVoucherNo = 'VN${(maxNum + 1).toString().padLeft(2, '0')}';
        _nextVoucherNums[ledgerNo] = maxNum + 2;
      }
      // Second pass: Save entries sequentially, awaiting each operation fully
      for (int i = 0; i < entryForms.length; i++) {
        final formData = entryForms[i];
        formData.voucherNoController.text = _sharedVoucherNo!;
        final parsedDebit =
            double.tryParse(formData.debitController.text) ?? 0.0;
        final parsedCredit =
            double.tryParse(formData.creditController.text) ?? 0.0;
        final newEntry = LedgerEntry(
          id: formData.originalEntry?.id,
          ledgerNo: formData.ledgerNoController.text,
          voucherNo: _sharedVoucherNo!,
          accountId: formData.accountIdController.text.isNotEmpty
              ? int.parse(formData.accountIdController.text)
              : null,
          accountName: formData.accountNameController.text.toUpperCase(),
          date: formData.selectedDate.value,
          transactionType: formData.transactionType.value,
          debit: parsedDebit,
          credit: parsedCredit,
          balance: controller.map.value['netBalance']! + parsedCredit,
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
          balanceCans: formData.balanceCans.text.toString(),
          receivedCans: formData.receivedCans.text.toString(),
          // ✅ FIXED: Cheque fields - only populate if payment method is cheque
          paymentMethod: formData.paymentMethod.value,
          chequeNo: formData.paymentMethod.value.toLowerCase() == 'cheque'
              ? (formData.chequeNoController.text.isNotEmpty
                    ? formData.chequeNoController.text
                    : null)
              : null,
          chequeAmount: formData.paymentMethod.value.toLowerCase() == 'cheque'
              ? (formData.chequeAmountController.text.isNotEmpty
                    ? double.tryParse(formData.chequeAmountController.text)
                    : null)
              : null,
          chequeDate: formData.paymentMethod.value.toLowerCase() == 'cheque'
              ? (formData.chequeDate.value != null
                    ? DateTime(
                        formData.chequeDate.value!.year,
                        formData.chequeDate.value!.month,
                        formData.chequeDate.value!.day,
                      )
                    : null)
              : null,
          bankName: formData.paymentMethod.value.toLowerCase() == 'cheque'
              ? (formData.bankNameController.text.isNotEmpty
                    ? formData.bankNameController.text
                    : null)
              : null,
        );
        debugPrint(
          "formData.paymentMethod.value.toLowerCase() == 'cheque'${formData.paymentMethod.value.toLowerCase() == 'cheque'}",
        );
        debugPrint(
          "formData.paymentMethod.value.toLowerCase() == 'cheque'${newEntry.toJson()}",
        );
        if (formData.originalEntry == null) {
          await repo.insertLedgerEntry(newEntry, ledgerNo);
          await _handleItemStockForNewEntry(newEntry);
          // ✅ FIXED: Use parsedCredit for credit and parsedDebit for debit
          if (parsedCredit > 0) {
            await repo.updateLedgerDebtOrCred("credit", ledgerNo, parsedCredit);
          } else if (parsedDebit > 0) {
            await repo.updateLedgerDebtOrCred("debit", ledgerNo, parsedDebit);
          }
        } else {
          await _handleItemStockForUpdatedEntry(
            formData.originalEntry!,
            newEntry,
          );
          await repo.updateLedgerEntry(newEntry, ledgerNo);
        }
        // Ensure full await between entries to release any potential locks
        await Future.delayed(const Duration(milliseconds: 100));
        savedEntries.add(newEntry);
      }

      // REMOVED: ReceiptItems creation code
      final List<ReceiptItem> receiptItems = savedEntries.map((entry) {
        final price = entry.sellingPricePerCan ?? entry.itemPricePerUnit ?? 0.0;
        final quantity = entry.cansQuantity ?? 0;
        // ✅ FIXED: Amount should be from debit or credit, not price * quantity
        final amount = entry.debit > 0 ? entry.debit : entry.credit;
        return ReceiptItem(
          name: entry.itemName ?? 'Unknown Item',
          price: price,
          canQuantity: quantity,
          type: entry.transactionType,
          description: entry.description ?? 'No description',
          amount: amount,
        );
      }).toList();

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
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }

      // CHANGED: Return savedEntries instead of receiptItems

      return SaveLedgerResult(
        ledgerEntries: savedEntries,
        receiptItems: receiptItems,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entries: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return SaveLedgerResult(ledgerEntries: [], receiptItems: []);
    } finally {
      // Dismiss loading dialog if shown (no need to await the future)
      if (loadingDialogFuture != null && context.mounted) {
        Navigator.of(context).pop();
      }
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
    final newBalance = previous + credit;
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
    double currentBalance = 0.0;
    for (var t in trans) {
      currentBalance += t.credit;
      t.balance = currentBalance;
      t.status = currentBalance > 0 ? 'Debit' : 'Credit';
    }
    // for (var t in trans) {
    //   if (t.type == 'ledger') {
    //     final original = ledgerMap[t.id]!;
    //     final updatedLedger = Ledger(
    //       id: original.id,
    //       ledgerNo: original.ledgerNo,
    //       accountId: aid,
    //       accountName: original.accountName,
    //       transactionType: original.transactionType,
    //       debit: t.debit,
    //       credit: t.credit,
    //       date: t.date,
    //       description: original.description,
    //       referenceNumber: original.referenceNumber,
    //       category: original.category,
    //       tags: original.tags,
    //       createdBy: original.createdBy,
    //       voucherNo: original.voucherNo,
    //       balance: t.balance,
    //       status: t.status,
    //       createdAt: original.createdAt,
    //       updatedAt: DateTime.now(),
    //     );
    //     await repo.updateLedger(updatedLedger);
    //   } else {
    //     final original = entryMap[t.id]!;
    //     final updatedEntry = LedgerEntry(
    //       id: original.id,
    //       ledgerNo: original.ledgerNo,
    //       voucherNo: original.voucherNo,
    //       accountId: aid,
    //       accountName: original.accountName,
    //       date: t.date,
    //       transactionType: original.transactionType,
    //       debit: t.debit,
    //       credit: t.credit,
    //       balance: t.balance,
    //       status: t.status,
    //       description: original.description,
    //       referenceNo: original.referenceNo,
    //       category: original.category,
    //       tags: original.tags,
    //       createdBy: original.createdBy,
    //       createdAt: original.createdAt,
    //       updatedAt: DateTime.now(),
    //       itemId: original.itemId,
    //       itemName: original.itemName,
    //       itemPricePerUnit: original.itemPricePerUnit,
    //       canWeight: original.canWeight,
    //       cansQuantity: original.cansQuantity,
    //       sellingPricePerCan: original.sellingPricePerCan,
    //       balanceCans: original.balanceCans.toString(),
    //       receivedCans: original.receivedCans.toString(),
    //       paymentMethod: original.paymentMethod,
    //       chequeNo: original.chequeNo,
    //       chequeAmount: original.chequeAmount,
    //       chequeDate: original.chequeDate,
    //       bankName: original.bankName,
    //     );
    //     await repo.updateLedgerEntry(updatedEntry, t.ledgerNo);
    //   }
    // }
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
    if (isEntry) {
      final lastVoucherNo = await repo.getLastVoucherNo(ledgerNo!);
      final match = regex.firstMatch(lastVoucherNo);
      if (match != null) {
        final number = int.tryParse(match.group(1)!) ?? 0;
        if (number > max) max = number;
      }
    }
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
    // Clear cheque fields
    clearChequeFields();
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
    // Dispose cheque field controllers
    chequeNoController.dispose();
    chequeAmountController.dispose();
    chequeDateController.dispose();
    bankNameController.dispose();
    for (var form in entryForms) {
      form.dispose();
    }
    entryForms.clear();
    _nextVoucherNums.clear();
    _sharedVoucherNo = null;
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
  final Ledger ledger;
  final Customer customer;
  final VoidCallback? onEntrySaved;

  const LedgerEntryAddEdit({
    super.key,
    required this.ledgerNo,
    required this.ledger,
    required this.customer,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntry(entry: entry, ledgerNo: ledgerNo);
      scrollController.jumpTo(0);
    });

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Obx(
      () => BaseLayout(
        showBackButton: true,
        onBackButtonPressed: () {
          NavigationHelper.pushReplacement(
            context,
            LedgerTablePage(ledger: ledger, customer: customer),
          );
        },
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
                    elevation: isDark ? 4 : 0,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isDark
                                ? LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      Theme.of(context).colorScheme.surface,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
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
                            top: 12,
                            right: 12,
                            child: IconButton(
                              tooltip: "Remove entry",
                              icon: Icon(
                                Icons.close,
                                color: Theme.of(context).colorScheme.error,
                              ),
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
                    TextButton.icon(
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
                      icon: Icon(
                        Icons.add,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'Add more',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          try {
                            debugPrint('=== SAVE PROCESS START ===');

                            // ✅ Step 1: Save all entries
                            final saveResult = await controller
                                .saveAllLedgerEntries(
                                  context,
                                  ledgerNo: ledgerNo,
                                );

                            if (saveResult.ledgerEntries.isEmpty) {
                              debugPrint('Save failed - no entries returned');
                              return;
                            }

                            debugPrint(
                              'Saved ${saveResult.ledgerEntries.length} entries',
                            );

                            // ✅ Step 3: Clear old data
                            ledgerTableController.filteredLedgerEntries.clear();
                            ledgerTableController.ledgerController.ledgerEntries
                                .clear();

                            debugPrint('Cleared old entries');

                            // ✅ Step 4: Reload fresh data from database
                            await ledgerTableController.loadLedgerEntries(
                              ledgerNo,
                            );
                            await ledgerTableController.ledgerController
                                .fetchLedgerEntries(ledgerNo);

                            debugPrint(
                              'Reloaded entries: ${ledgerTableController.filteredLedgerEntries.length}',
                            );

                            // ✅ Step 6: Calculate totals with fresh data
                            await ledgerTableController.calculateTotals(
                              customerID: customer.id.toString(),
                              customerName: customer.name,
                            );

                            debugPrint(
                              'Calculated totals: ${ledgerTableController.map.value}',
                            );

                            // ✅ Step 7: Update reactive totals
                            ledgerTableController._updateReactiveTotals();

                            // ✅ Step 8: Refresh main ledgers list
                            await controller.fetchLedgers();

                            // ✅ Step 9: Get fresh balance data for receipt using customer.name (not accountName)
                            final map =
                                await BalanceCalculator.getCustomerBalanceData(
                                  customerName: customer
                                      .name, // ✅ FIXED: Use customer.name instead of accountName
                                  customerType: 'customer',
                                  customerId: customer
                                      .id!, // ✅ FIXED: Use customer.id directly
                                );

                            debugPrint('=== FINAL BALANCE DATA ===');
                            debugPrint('Customer Name: ${customer.name}');
                            debugPrint(
                              'Opening Balance: ${map['openingBalance']}',
                            );
                            debugPrint('Credit: ${map['credit']}');
                            debugPrint('Debit: ${map['debit']}');
                            debugPrint('Net Balance: ${map['netBalance']}');

                            var currentCans = 0.0;
                            var balanceCans = 0.0;
                            for (var entry in saveResult.ledgerEntries) {
                              currentCans += entry.cansQuantity ?? 0;
                              balanceCans = double.parse(
                                entry.balanceCans ?? '0',
                              );
                            }

                            // ✅ Dispose scroll controller
                            scrollController.dispose();

                            // ✅ Show print dialog with fresh data OR navigate directly
                            if (saveResult.ledgerEntries.isNotEmpty &&
                                context.mounted) {
                              showPrintReceiptDialog(
                                context,
                                saveResult.receiptItems,
                                ledgerNo,
                                currentCans,
                                balanceCans,
                                map,
                              );
                            } else {
                              // ✅ FETCH FRESH LEDGER OBJECT
                              debugPrint(
                                '=== NO ENTRIES TO PRINT - FETCHING FRESH LEDGER ===',
                              );

                              await controller.fetchLedgers();
                              final freshLedger = controller.ledgers.firstWhere(
                                (l) => l.ledgerNo == ledgerNo,
                              );

                              debugPrint(
                                'Fresh ledger - Debit: ${freshLedger.debit}, Credit: ${freshLedger.credit}, Balance: ${freshLedger.balance}',
                              );

                              if (context.mounted) {
                                NavigationHelper.pushReplacement(
                                  context,
                                  LedgerHome(),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint('❌ Error during save: $e');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        controller.entryForms.length > 1 ? 'Save All' : 'Save',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
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

  void showPrintReceiptDialog(
    BuildContext context,
    List<ReceiptItem> entries,
    String ledgerNo,
    double currentCans,
    double balanceCans,
    Map<String, dynamic> map,
  ) {
    final EntryFormData formData = EntryFormData();
    final ledgerTableController = Get.find<LedgerTableController>();
    final ledgerController = Get.find<LedgerController>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String vehicleNumber = '';
        bool askPrint = true;
        bool includeLogo = true;
        bool includeamountDetails = true;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                'Print Receipt',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              content: askPrint
                  ? Text(
                      'Do you want to print the receipt?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: 'Vehicle Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              vehicleNumber = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: includeLogo,
                              activeColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              checkColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              onChanged: (val) {
                                setState(() {
                                  includeLogo = val ?? true;
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Include Company Logo on Receipt',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        // Row(
                        //   children: [
                        //     Checkbox(
                        //       value: includeamountDetails,
                        //       activeColor: Theme.of(
                        //         context,
                        //       ).colorScheme.primary,
                        //       checkColor: Theme.of(
                        //         context,
                        //       ).colorScheme.onPrimary,
                        //       onChanged: (val) {
                        //         setState(() {
                        //           includeamountDetails = val ?? true;
                        //         });
                        //       },
                        //     ),
                        //     Expanded(
                        //       child: Text(
                        //         'Include amount details on Receipt',
                        //         style: Theme.of(context).textTheme.bodyMedium,
                        //       ),
                        //     ),
                        //   ],
                        // ),
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
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (askPrint)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();

                      debugPrint('=== NO PRINT - REFRESHING DATA ===');

                      // ✅ Refresh data
                      await Future.delayed(const Duration(milliseconds: 300));
                      await ledgerTableController.loadLedgerEntries(ledgerNo);
                      await ledgerTableController.calculateTotals(
                        customerID: customer.id.toString(),
                        customerName: customer.name,
                      );
                      ledgerTableController._updateReactiveTotals();

                      // ✅ FETCH FRESH LEDGER OBJECT
                      await ledgerController.fetchLedgers();
                      final freshLedger = ledgerController.ledgers.firstWhere(
                        (l) => l.ledgerNo == ledgerNo,
                      );

                      debugPrint(
                        'Fresh ledger - Debit: ${freshLedger.debit}, Credit: ${freshLedger.credit}, Balance: ${freshLedger.balance}',
                      );

                      // ✅ Navigate with FRESH ledger object
                      if (context.mounted) {
                        NavigationHelper.pushReplacement(context, LedgerHome());
                      }
                    },
                    child: Text(
                      'No',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!askPrint)
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();

                      debugPrint('=== CANCEL - REFRESHING DATA ===');

                      // ✅ Refresh data
                      await Future.delayed(const Duration(milliseconds: 300));
                      await ledgerTableController.loadLedgerEntries(ledgerNo);
                      await ledgerTableController.calculateTotals(
                        customerID: customer.id.toString(),
                        customerName: customer.name,
                      );
                      ledgerTableController._updateReactiveTotals();

                      // ✅ FETCH FRESH LEDGER OBJECT
                      await ledgerController.fetchLedgers();
                      final freshLedger = ledgerController.ledgers.firstWhere(
                        (l) => l.ledgerNo == ledgerNo,
                      );

                      debugPrint(
                        'Fresh ledger - Debit: ${freshLedger.debit}, Credit: ${freshLedger.credit}, Balance: ${freshLedger.balance}',
                      );

                      // ✅ Navigate with FRESH ledger object
                      if (context.mounted) {
                        NavigationHelper.pushReplacement(context, LedgerHome());
                      }
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (!askPrint)
                  TextButton(
                    onPressed: vehicleNumber.trim().isEmpty
                        ? null
                        : () async {
                            Navigator.of(ctx).pop();

                            debugPrint('=== PRINTING RECEIPT ===');
                            debugPrint('Vehicle: $vehicleNumber');
                            debugPrint('Current totals in map: $map');

                            // ✅ Print the receipt with fresh data
                            await printEntry(
                              entries,
                              vehicleNumber,
                              context,
                              includeLogo,
                              true,
                              // includeamountDetails,
                              formData,
                              ledgerNo,
                              currentCans,
                              balanceCans,
                              map,
                            );

                            debugPrint('=== AFTER PRINT - REFRESHING DATA ===');

                            // ✅ Refresh all data
                            await Future.delayed(
                              const Duration(milliseconds: 300),
                            );
                            await ledgerTableController.loadLedgerEntries(
                              ledgerNo,
                            );
                            await ledgerTableController.calculateTotals(
                              customerID: customer.id.toString(),
                              customerName: customer.name,
                            );
                            ledgerTableController._updateReactiveTotals();

                            // ✅ FETCH FRESH LEDGER OBJECT
                            await ledgerController.fetchLedgers();
                            final freshLedger = ledgerController.ledgers
                                .firstWhere((l) => l.ledgerNo == ledgerNo);

                            debugPrint(
                              'Fresh ledger - Debit: ${freshLedger.debit}, Credit: ${freshLedger.credit}, Balance: ${freshLedger.balance}',
                            );

                            // ✅ Navigate with FRESH ledger object
                            if (context.mounted) {
                              NavigationHelper.pushReplacement(
                                context,
                                LedgerHome(),
                              );
                            }
                          },
                    child: Text(
                      'Print',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
    bool showLogo,
    bool includeamountDetails,
    EntryFormData formData,
    String ledgerNo,
    double currentCans,
    double balanceCans,
    Map<String, dynamic> map,
  ) async {
    final ledgerTableController = Get.find<LedgerTableController>();
    final customerController = Get.find<CustomerController>();

    // ✅ REFRESH ALL DATA FIRST
    await ledgerTableController.loadLedgerEntries(ledgerNo);

    var customer = await customerController.repo.getCustomer(
      accountId.toString(),
    );

    // Check if we have entries after refresh
    if (ledgerTableController.filteredLedgerEntries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No entries found to print'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Get all entries with the same voucher number
    final voucherNo =
        ledgerTableController.filteredLedgerEntries.last.voucherNo;
    final entriesWithSameVoucher = ledgerTableController.filteredLedgerEntries
        .where((e) => e.voucherNo == voucherNo)
        .toList();
    debugPrint(entriesWithSameVoucher[0].toJson().toString());
    // Sort by date to ensure correct order
    entriesWithSameVoucher.sort((a, b) => a.date.compareTo(b.date));

    // Calculate totals for all entries with this voucher

    double currentAmount = 0.0;
    double amountToAddinNetBalance = 0.0;
    for (var entry in entriesWithSameVoucher) {
      currentAmount += entry.transactionType.toLowerCase() == 'credit'
          ? entry.credit
          : entry.debit;

      amountToAddinNetBalance += entry.transactionType.toLowerCase() == 'credit'
          ? entry.credit
          : 0.0;
    }

    // Get the date of the first entry in this voucher
    final voucherDate = entriesWithSameVoucher.first.date;

    final netBalance = map['netBalance']!;

    final data = ReceiptData(
      companyName: 'NAZ ENTERPRISES',
      date: DateFormat('dd/MM/yyyy').format(voucherDate),
      customerName: accountName,
      customerAddress: customer!.address,
      vehicleNumber: vehicleNo,
      voucherNumber: voucherNo,
      items: items,
      previousCans: balanceCans,
      currentCans: currentCans,
      totalCans: balanceCans + currentCans,
      receivedCans: 0.0,
      balanceCans: 0.0,
      currentAmount: currentAmount,
      previousAmount: netBalance,
      netBalance: netBalance + amountToAddinNetBalance,
    );

    debugPrint(data.toString());

    await ReceiptPdfGenerator.generateAndPrint(
      data,
      showLogo: showLogo,
      showPrices: includeamountDetails,
    );
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

    return FutureBuilder<Map<String, dynamic>>(
      future: controller.cansController.getCansBalanceSummary(
        int.parse(accountId),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text('Error loading cans data');
        }

        final cansData =
            snapshot.data ??
            {
              'final_balance': '0.0',
              'total_current': '0.0',
              'total_received': '0.0',
            };

        final finalBalance =
            double.tryParse(cansData['balance'].toString()) ?? 0.0;
        final totalReceived =
            double.tryParse(cansData['received'].toString()) ?? 0.0;
        final previousCans =
            double.tryParse(cansData['previous'].toString()) ?? 0.0;

        // Update the form fields - only update balance cans, don't autofill cans quantity
        // formData.cansQuantityController.text = totalCurrent.toStringAsFixed(0);  // COMMENTED: User will enter this
        formData.balanceCans.text = finalBalance.toStringAsFixed(0);
        formData.receivedCans.text = totalReceived.toStringAsFixed(0);
        formData.previousCans.text = previousCans.toStringAsFixed(0);
        formData.balanceController.text = controller
            .controller
            .map
            .value['netBalance']!
            .toString();

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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                          // formData._updateBalance();
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
                        onTap: () =>
                            controller.selectDateForForm(context, index),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            labelStyle: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.8),
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
                const SizedBox(height: 16),

                // Payment Method Dropdown
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: formData.paymentMethod.value,
                        focusNode: formData.paymentMethodFocusNode,
                        style: Theme.of(context).textTheme.bodySmall,
                        decoration: InputDecoration(
                          labelText: 'Payment Type',
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
                        items: const ['cash', 'cheque']
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t,
                                child: Text(t == 'cash' ? 'Cash' : 'Cheque'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          formData.paymentMethod.value = value!;
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Transaction Type is required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Container()), // Empty container for layout
                  ],
                ),
                // Cheque Fields (conditionally shown)
                Obx(() {
                  if (formData.paymentMethod.value == 'cheque') {
                    return Column(
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                context: context,
                                controller: formData.chequeNoController,
                                focusNode: formData.chequeNoFocusNode,
                                label: 'Cheque No',
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Cheque No is required for cheque transactions'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                context: context,
                                controller: formData.chequeAmountController,
                                focusNode: formData.chequeAmountFocusNode,
                                label: 'Cheque Amount',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Cheque Amount is required for cheque transactions'
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
                              child: InkWell(
                                focusNode: formData.chequeDateFocusNode,
                                onTap: () => controller.selectChequeDateForForm(
                                  context,
                                  index,
                                ),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Cheque Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                  ),
                                  child: Text(
                                    formData.chequeDate.value != null
                                        ? DateFormat(
                                            'dd-MM-yyyy',
                                          ).format(formData.chequeDate.value!)
                                        : 'Select Cheque Date',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue:
                                    formData.bankNameController.text.isNotEmpty
                                    ? formData.bankNameController.text
                                    : null,
                                focusNode: formData.bankNameFocusNode,
                                style: Theme.of(context).textTheme.bodySmall,
                                decoration: InputDecoration(
                                  labelText: 'Bank Name',
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
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
                                items: controller.bankList
                                    .map(
                                      (bank) => DropdownMenuItem<String>(
                                        value: bank,
                                        child: Text(bank),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  formData.bankNameController.text = value!;
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Bank Name is required for cheque transactions'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
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
                        (t) =>
                            DropdownMenuItem<String>(value: t, child: Text(t)),
                      )
                      .toList(),
                  onChanged: (value) {
                    formData.transactionType.value = value!;
                    formData.transactionTypeController.text = value;
                    formData.status.value = value;
                    formData.statusController.text = value;
                    // formData._updateBalance();
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
                      DateFormat(
                        'dd-MM-yyyy',
                      ).format(formData.selectedDate.value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Method Dropdown (Mobile)
                DropdownButtonFormField<String>(
                  initialValue: formData.paymentMethod.value,
                  focusNode: formData.paymentMethodFocusNode,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const ['cash', 'cheque']
                      .map(
                        (t) => DropdownMenuItem<String>(
                          value: t,
                          child: Text(t == 'cash' ? 'Cash' : 'Cheque'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    formData.paymentMethod.value = value!;
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Transaction Type is required'
                      : null,
                ),

                // Cheque Fields (conditionally shown - Mobile)
                if (formData.paymentMethod.value == 'cheque') ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: formData.chequeNoController,
                    focusNode: formData.chequeNoFocusNode,
                    label: 'Cheque No',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Cheque No is required for cheque transactions'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: formData.chequeAmountController,
                    focusNode: formData.chequeAmountFocusNode,
                    label: 'Cheque Amount',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Cheque Amount is required for cheque transactions'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    focusNode: formData.chequeDateFocusNode,
                    onTap: () =>
                        controller.selectChequeDateForForm(context, index),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Cheque Date',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        formData.chequeDate.value != null
                            ? DateFormat(
                                'dd-MM-yyyy',
                              ).format(formData.chequeDate.value!)
                            : 'Select Cheque Date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: formData.bankNameController.text.isNotEmpty
                        ? formData.bankNameController.text
                        : null,
                    focusNode: formData.bankNameFocusNode,
                    style: Theme.of(context).textTheme.bodySmall,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: controller.bankList
                        .map(
                          (bank) => DropdownMenuItem<String>(
                            value: bank,
                            child: Text(bank),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      formData.bankNameController.text = value!;
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Bank Name is required for cheque transactions'
                        : null,
                  ),
                ],
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
                              formData.itemIdController.text = item.id
                                  .toString();
                              formData.itemNameController.text = item.name;
                              formData.itemPriceController.text = item
                                  .pricePerKg
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        readOnly: false,
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        readOnly: false,
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
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
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Balance Cans: ${formData.balanceCans.text}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.red,
                      ),
                    ),
                  ),
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
                    validator: (value) =>
                        value == null ? 'Item is required' : null,
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
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Cans Quantity is required';
                    }
                    if (formData.selectedItem.value != null) {
                      final quantity = int.tryParse(value) ?? 0;
                      final canWeight =
                          double.tryParse(formData.canWeightController.text) ??
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
                  controller: formData.cansQuantityController,
                  focusNode: formData.cansQuantityFocusNode,
                  label: 'Cans Quantity',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Cans Quantity is required';
                    }
                    if (formData.selectedItem.value != null) {
                      final quantity = int.tryParse(value) ?? 0;
                      final canWeight =
                          double.tryParse(formData.canWeightController.text) ??
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
                    // Expanded(
                    //   child: _buildTextField(
                    //     context: context,
                    //     controller: formData.balanceController,
                    //     focusNode: formData.balanceFocusNode,
                    //     label: 'Balance',
                    //     keyboardType: const TextInputType.numberWithOptions(
                    //       decimal: true,
                    //     ),
                    //     inputFormatters: [
                    //       FilteringTextInputFormatter.allow(
                    //         RegExp(r'^\d*\.?\d*'),
                    //       ),
                    //     ],
                    //     readOnly: true,
                    //     validator: (value) => value == null || value.isEmpty
                    //         ? 'Balance is required'
                    //         : null,
                    //   ),
                    // ),
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
                    const SizedBox(width: 16),
                    Expanded(child: Container()),
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
                  validator: (value) => value == null || value.isEmpty
                      ? 'Balance is required'
                      : null,
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
                        (s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      )
                      .toList(),
                  onChanged: null,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Status is required'
                      : null,
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
      },
    );
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
  final numberFormat = NumberFormat('#,##0', 'en_US');

  // Existing controllers
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

  // Item-related controllers
  late TextEditingController itemIdController;
  late TextEditingController itemNameController;
  late TextEditingController itemPriceController;
  late TextEditingController canWeightController;
  late TextEditingController cansQuantityController;
  late TextEditingController sellingPriceController;
  late TextEditingController totalWeightController;
  late TextEditingController balanceCans;
  late TextEditingController previousCans;
  late TextEditingController receivedCans;

  // New cheque field controllers
  late TextEditingController chequeNoController;
  late TextEditingController chequeAmountController;
  late TextEditingController bankNameController;

  final ledgerTableController = Get.find<LedgerTableController>();
  final RxString transactionType = RxString("Debit");
  final RxString status = RxString("Debit");
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<Item?> selectedItem = Rxn<Item?>(null);

  // New payment method field
  final RxString paymentMethod = RxString('cash');
  final Rx<DateTime?> chequeDate = Rxn<DateTime>();

  double? _previousBalance;
  late final GlobalKey<FormState> step1FormKey;
  late final GlobalKey<FormState> step2FormKey;
  late final GlobalKey<FormState> step3FormKey;
  final RxInt currentStep = 0.obs;

  // Existing focus nodes
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
  final previousCansFocusNode = FocusNode();
  final receivedCansFocusNode = FocusNode();
  final debitFocusNode = FocusNode();
  final creditFocusNode = FocusNode();
  final balanceFocusNode = FocusNode();
  final statusFocusNode = FocusNode();
  final descriptionFocusNode = FocusNode();
  final referenceNoFocusNode = FocusNode();
  final categoryFocusNode = FocusNode();
  final createdByFocusNode = FocusNode();

  // New cheque field focus nodes
  final paymentMethodFocusNode = FocusNode();
  final chequeNoFocusNode = FocusNode();
  final chequeAmountFocusNode = FocusNode();
  final chequeDateFocusNode = FocusNode();
  final bankNameFocusNode = FocusNode();

  bool _isUpdatingDebit = false;
  bool _isUpdatingCredit = false;

  // Bank list for dropdown
  final List<String> bankList = [
    'Habib Bank Limited (HBL)',
    'United Bank Limited (UBL)',
    'MCB Bank Limited',
    'Allied Bank Limited (ABL)',
    'National Bank of Pakistan (NBP)',
    'Bank Alfalah',
    'Meezan Bank',
    'Faysal Bank',
    'Askari Bank',
    'Standard Chartered Bank (Pakistan)',
    'Bank of Punjab (BOP)',
    'Bank of Khyber',
    'Sindh Bank',
    'Habib Metropolitan Bank',
    'JS Bank',
    'Summit Bank',
    'First Women Bank Limited',
    'Dubai Islamic Bank Pakistan',
    'Samba Bank',
    'Soneri Bank',
    'Silk Bank',
  ];

  EntryFormData() {
    // Initialize existing controllers
    ledgerNoController = TextEditingController();
    voucherNoController = TextEditingController();
    accountNameController = TextEditingController();
    accountIdController = TextEditingController();
    transactionTypeController = TextEditingController(text: "Debit");
    debitController = TextEditingController();
    creditController = TextEditingController();
    balanceController = TextEditingController();
    descriptionController = TextEditingController();
    referenceNoController = TextEditingController();
    categoryController = TextEditingController();
    tagsController = TextEditingController();
    createdByController = TextEditingController();
    statusController = TextEditingController(text: "Debit");

    // Item controllers
    itemIdController = TextEditingController();
    itemNameController = TextEditingController();
    itemPriceController = TextEditingController();
    canWeightController = TextEditingController();
    cansQuantityController = TextEditingController();
    sellingPriceController = TextEditingController();
    totalWeightController = TextEditingController();
    balanceCans = TextEditingController(text: '0.00');
    previousCans = TextEditingController(text: '0.00');
    receivedCans = TextEditingController();

    // Initialize new cheque controllers
    chequeNoController = TextEditingController();
    chequeAmountController = TextEditingController();
    bankNameController = TextEditingController();

    step1FormKey = GlobalKey<FormState>();
    step2FormKey = GlobalKey<FormState>();
    step3FormKey = GlobalKey<FormState>();

    // Existing listeners
    canWeightController.addListener(_onCanOrQtyChanged);
    cansQuantityController.addListener(_onCanOrQtyChanged);
    itemPriceController.addListener(_onCanOrQtyChanged);
    creditController.addListener(_handleCreditInputForDebitTransaction);
    debitController.addListener(_handleDebitInputForCreditTransaction);
    // creditController.addListener(_updateBalance);
    // debitController.addListener(_updateBalance);

    // Add listener to update cans quantity when account changes
    accountIdController.addListener(() {
      final accountId = int.tryParse(accountIdController.text) ?? 0;
      if (accountId > 0) {
        _updateCansQuantityFromCansTable(accountId);
      }
    });

    // New listener for payment method changes
    // In EntryFormData constructor, update the payment method listener:
    ever(paymentMethod, (method) {
      if (method == 'cash') {
        // Clear cheque fields when switching to cash
        chequeNoController.clear();
        chequeAmountController.clear();
        chequeDate.value =
            null; // ✅ Make sure to set to null, not just clear the controller
        bankNameController.clear();
      }
    });

    // Existing item listener
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

    // Existing transaction type listener
    ever(transactionType, (type) {
      if (type == "Debit") {
        _isUpdatingCredit = true;
        creditController.text = "0";
        _isUpdatingCredit = false;
        _isUpdatingDebit = true;
        debitController.text = sellingPriceController.text.isNotEmpty
            ? sellingPriceController.text
            : "";
        _isUpdatingDebit = false;
      } else if (type == "Credit") {
        _isUpdatingDebit = true;
        debitController.text = "0";
        _isUpdatingDebit = false;
        _isUpdatingCredit = true;
        creditController.text = sellingPriceController.text.isNotEmpty
            ? sellingPriceController.text
            : "";
        _isUpdatingCredit = false;
      }
      _calculateSellingPrice();
      // _updateBalance();
    });
  }

  void _onCanOrQtyChanged() {
    _updateTotalWeight();
    _calculateSellingPrice();
    updateDescription();
  }

  void _handleCreditInputForDebitTransaction() {
    if (_isUpdatingCredit) return;
    if (transactionType.value == "Debit") {
      final currentValue = creditController.text;
      if (currentValue.isNotEmpty &&
          currentValue != "0" &&
          currentValue != "0.00") {
        final parsedValue = double.tryParse(currentValue);
        if (parsedValue != null && parsedValue != 0) {
          _isUpdatingCredit = true;
          creditController.text = (-parsedValue).toStringAsFixed(2);
          _isUpdatingCredit = false;
        }
      }
    }
  }

  void _handleDebitInputForCreditTransaction() {
    if (_isUpdatingDebit) return;
    if (transactionType.value == "Credit") {
      final currentValue = debitController.text;
      if (currentValue.isNotEmpty &&
          currentValue != "0" &&
          currentValue != "0.00") {
        final parsedValue = double.tryParse(currentValue);
        if (parsedValue != null && parsedValue != 0) {
          _isUpdatingDebit = true;
          debitController.text = (-parsedValue).toStringAsFixed(2);
          _isUpdatingDebit = false;
        }
      }
    }
  }

  Future<void> _initPreviousBalance() async {
    _previousBalance = ledgerTableController.netBalance;
    // _updateBalanceFromPrevious();
  }

  void _calculateSellingPrice() {
    if (selectedItem.value == null) return;
    final pricePerKg = double.tryParse(itemPriceController.text) ?? 0;
    final canWeight = double.tryParse(canWeightController.text) ?? 0;
    final quantity = double.tryParse(cansQuantityController.text) ?? 0;
    if (pricePerKg > 0 && canWeight > 0 && quantity > 0) {
      final sellingPrice = pricePerKg * canWeight * quantity;
      sellingPriceController.text = sellingPrice.toStringAsFixed(2);
      if (transactionType.value == 'Debit') {
        _isUpdatingDebit = true;
        debitController.text = sellingPrice.toStringAsFixed(2);
        _isUpdatingDebit = false;
        _isUpdatingCredit = true;
        creditController.text = "0";
        _isUpdatingCredit = false;
      } else if (transactionType.value == 'Credit') {
        _isUpdatingCredit = true;
        creditController.text = sellingPrice.toStringAsFixed(2);
        _isUpdatingCredit = false;
        _isUpdatingDebit = true;
        debitController.text = "0";
        _isUpdatingDebit = false;
      }
      // _updateBalance();
    }
  }

  void _updateTotalWeight() {
    final canWeight = double.tryParse(canWeightController.text) ?? 0;
    final quantity = double.tryParse(cansQuantityController.text) ?? 0;
    final totalWeight = canWeight * quantity;
    totalWeightController.text = totalWeight.toStringAsFixed(2);
  }

  void _updateCansQuantityFromCansTable(int accountId) {
    final cansController = Get.find<CansController>();
    // First ensure cans data is loaded
    if (cansController.cans.isEmpty) {
      cansController.fetchCans();
    }
    // Don't auto-fill cans quantity - user will enter this manually
    // just clear it if no record found
    final cansRecord = cansController.getCansForCustomer(accountId);
    if (cansRecord == null) {
      cansQuantityController.clear();
    }
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
    final canQtyDouble = double.tryParse(canQty) ?? 0;
    final totalWeight = (double.tryParse(canWeight) ?? 0) * canQtyDouble;
    final pricePerKg = itemPriceController.text;
    final totalAmount = sellingPriceController.text;

    return '$itemName (can of ${canWeight}Kgs*$canQty${canQtyDouble > 1 ? 'cans' : 'can'} = ${totalWeight}Kgs at Price $pricePerKg/Kg and total amount is: $totalAmount)';
  }

  void updateDescription() {
    final newDescription = generateItemDescription();
    if (newDescription.isNotEmpty) {
      descriptionController.text = newDescription;
    }
  }

  void dispose() {
    // Dispose existing controllers
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
    previousCans.dispose();
    balanceCans.dispose();
    receivedCans.dispose();

    // Dispose new cheque controllers
    chequeNoController.dispose();
    chequeAmountController.dispose();
    bankNameController.dispose();

    // Dispose focus nodes
    ledgerNoFocusNode.dispose();
    voucherNoFocusNode.dispose();
    accountNameFocusNode.dispose();
    accountIdFocusNode.dispose();
    transactionTypeFocusNode.dispose();
    dateFocusNode.dispose();
    itemFocusNode.dispose();
    cansQuantityFocusNode.dispose();
    itemPriceFocusNode.dispose();
    canWeightFocusNode.dispose();
    sellingPriceFocusNode.dispose();
    totalWeightFocusNode.dispose();
    previousCansFocusNode.dispose();
    balanceCansFocusNode.dispose();
    receivedCansFocusNode.dispose();
    debitFocusNode.dispose();
    creditFocusNode.dispose();
    balanceFocusNode.dispose();
    statusFocusNode.dispose();
    descriptionFocusNode.dispose();
    referenceNoFocusNode.dispose();
    categoryFocusNode.dispose();
    createdByFocusNode.dispose();
    paymentMethodFocusNode.dispose();
    chequeNoFocusNode.dispose();
    chequeAmountFocusNode.dispose();
    chequeDateFocusNode.dispose();
    bankNameFocusNode.dispose();
  }
}

class BalanceCalculator {
  static Future<Map<String, double>> getCustomerBalanceData({
    required String customerName,
    required String customerType,
    required int customerId,
  }) async {
    try {
      debugPrint('=== BALANCE CALCULATOR START ===');
      debugPrint('Customer: $customerName, ID: $customerId');

      // ✅ Add delay to ensure database is ready
      await Future.delayed(const Duration(milliseconds: 100));

      final customerListController = Get.find<CustomerController>();

      // Run all 3 API calls in parallel for better performance
      final results = await Future.wait([
        // 1. Opening Balance
        CustomerRepository().getOpeningBalanceForCustomer(customerName),
        // 2. Debit/Credit Summary
        customerListController.getCustomerDebitCredit(
          customerName,
          customerType,
          customerId,
        ),
        // 3. Customer Ledger Summary
        CustomerLedgerRepository().fetchTotalDebitAndCredit(
          customerName,
          customerId,
        ),
      ]);

      // Extract results
      final openingBalance = results[0] as double;
      final summary = results[1] as DebitCreditSummary;
      final ledgerSummary = results[2] as DebitCreditSummary;

      debugPrint('Opening Balance: $openingBalance');
      debugPrint('Summary Debit: ${summary.debit}');
      debugPrint('Summary Credit: ${summary.credit}');
      debugPrint('Ledger Debit: ${ledgerSummary.debit}');

      // Parse values
      final totalDebit = double.parse(summary.debit);
      final totalCredit = double.parse(summary.credit);
      final customerLedgerDebit = double.parse(ledgerSummary.debit);

      // Calculate net balance
      final netBalance = ((totalCredit + openingBalance) - customerLedgerDebit)
          .clamp(0, double.infinity);

      var map = {
        'openingBalance': openingBalance,
        'debit': totalDebit,
        'credit': totalCredit,
        'netBalance': double.parse(netBalance.toStringAsFixed(2)),
        'customerLedgerDebit': customerLedgerDebit,
      };

      debugPrint('=== BALANCE CALCULATOR RESULT ===');
      debugPrint('Final Map: $map');

      return map;
    } catch (e) {
      debugPrint('❌ Error in BalanceCalculator: $e');
      throw Exception('Failed to calculate balance: $e');
    }
  }
}
