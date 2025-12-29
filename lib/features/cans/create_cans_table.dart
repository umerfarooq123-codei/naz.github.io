import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';

import 'cans_controller.dart';

class CreateCansTable extends StatefulWidget {
  const CreateCansTable({super.key});

  @override
  State<CreateCansTable> createState() => _CreateCansTableState();
}

class _CreateCansTableState extends State<CreateCansTable> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _accountNameController;
  late TextEditingController _accountIdController;
  late TextEditingController _openingBalanceController;
  final customerRepo = CustomerRepository();
  late RxList<Customer> customers;
  Rx<Customer?> selectedCustomer = Rx<Customer?>(null);

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _accountNameController = TextEditingController();
    _accountIdController = TextEditingController();
    _openingBalanceController = TextEditingController();
    customers = <Customer>[].obs;
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final loadedCustomers = await customerRepo.getAllCustomers();
      // Filter only customers, exclude vendors
      final filteredCustomers = loadedCustomers
          .where((customer) => customer.type.toLowerCase() == 'customer')
          .toList();
      customers.assignAll(filteredCustomers);
      debugPrint(
        'Loaded ${filteredCustomers.length} customers (filtered from ${loadedCustomers.length} total)',
      );
    } catch (e) {
      debugPrint('Error loading customers: $e');
      Get.snackbar('Error', 'Failed to load customers: $e');
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountIdController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CansController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth > 800
                ? constraints.maxWidth / 3
                : constraints.maxWidth,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New Cans Table',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a new cans tracking table for an account',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection('Account Information', [
                        Obx(
                          () => DropdownButtonFormField<Customer>(
                            initialValue: selectedCustomer.value,
                            items: customers.map((customer) {
                              return DropdownMenuItem<Customer>(
                                value: customer,
                                child: Text(customer.name),
                              );
                            }).toList(),
                            onChanged: (customer) {
                              if (customer != null) {
                                selectedCustomer.value = customer;
                                _accountNameController.text = customer.name;
                                _accountIdController.text =
                                    customer.id?.toString() ?? '';
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Select Customer',
                              hintText: 'Choose a customer',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a customer';
                              }
                              return null;
                            },
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountNameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Account Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _accountIdController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Account ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSection('Initial Settings', [
                        TextFormField(
                          controller: _openingBalanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Opening Balance (Cans)',
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Opening balance is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            final balance = double.parse(value);
                            if (balance < 0) {
                              return 'Opening balance cannot be negative';
                            }
                            return null;
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                if (selectedCustomer.value == null) {
                                  Get.snackbar(
                                    'Error',
                                    'Please select a customer',
                                  );
                                  return;
                                }
                                try {
                                  final cans = Cans(
                                    accountName: selectedCustomer.value!.name,
                                    accountId: selectedCustomer.value!.id,
                                    openingBalanceCans: double.parse(
                                      _openingBalanceController.text,
                                    ),
                                    currentCans: 0,
                                    totalCans: 0,
                                    receivedCans: 0,
                                    insertedDate: DateTime.now(),
                                    updatedDate: DateTime.now(),
                                  );

                                  debugPrint(
                                    'Creating cans table: ${cans.accountName} (ID: ${cans.accountId})',
                                  );
                                  await controller.addCansTable(cans);
                                  debugPrint('Cans table created successfully');
                                  if (mounted) {
                                    NavigationHelper.pop(context);
                                    Get.snackbar(
                                      'Success',
                                      'Cans table created successfully',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.green.withAlpha(
                                        200,
                                      ),
                                      colorText: Colors.white,
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error creating cans table: $e');
                                  Get.snackbar(
                                    'Error',
                                    'Failed to create cans table: $e',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red.withAlpha(200),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 5),
                                  );
                                }
                              }
                            },
                            child: Text(
                              'Create',
                              style: Theme.of(context).textTheme.labelLarge,
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
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
