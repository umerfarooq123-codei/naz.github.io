import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/main.dart';

import '../../core/models/customer.dart';

class CustomerAddEdit extends StatelessWidget {
  final Customer? customer;
  const CustomerAddEdit({super.key, this.customer});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CustomerController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // 🧮 Ensure default value 0 for opening balance controller
    controller.openingBalanceController.text =
        customer?.openingBalance.toString() ?? '0';

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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
        inputFormatters: inputFormatters,
      );
    }

    return Obx(() {
      return BaseLayout(
        showBackButton: true,
        appBarTitle: customer == null
            ? 'Add ${controller.type.value}'
            : 'Edit ${controller.type.value}',
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${controller.type.value} Details',
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
                                // 🧩 Type + Customer No
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Obx(() {
                                        return DropdownButtonFormField<String>(
                                          initialValue: controller.type.value,
                                          items: [
                                            DropdownMenuItem(
                                              value: "Customer",
                                              child: Text(
                                                "Customer",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: "Vendor",
                                              child: Text(
                                                "Vendor",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) async {
                                            controller.type.value = value ?? '';
                                            controller
                                                .customerNoController
                                                .text = await controller.repo
                                                .getLastCustNVendNo(
                                                  controller.type.value,
                                                );
                                          },
                                          decoration: InputDecoration(
                                            labelText: 'Type',
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTextField(
                                        controller:
                                            controller.customerNoController,
                                        label: 'Customer No',
                                        readOnly: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 🧩 Name + Address
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: buildTextField(
                                        controller: controller.nameController,
                                        label: 'Name',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a name';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTextField(
                                        controller:
                                            controller.addressController,
                                        label: 'Address',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter an address';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 🧩 Mobile + NTN
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: buildTextField(
                                        controller:
                                            controller.mobileNoController,
                                        label: 'Mobile No',
                                        keyboardType: TextInputType.phone,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a mobile number';
                                          }
                                          if (int.tryParse(value) == null) {
                                            return 'Please enter a valid number';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: buildTextField(
                                        controller: controller.ntnNoController,
                                        label: 'NTN No',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 💰 Opening Balance Field
                                Row(
                                  children: [
                                    Expanded(
                                      child: buildTextField(
                                        controller:
                                            controller.openingBalanceController,
                                        label: 'Opening Balance',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter opening balance';
                                          }
                                          if (double.tryParse(value) == null) {
                                            return 'Enter a valid number';
                                          }
                                          return null;
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d{0,2}'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              controller.clearForm();
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
                                            onPressed: () =>
                                                controller.saveCustomer(
                                                  context,
                                                  customer: customer,
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              foregroundColor: Theme.of(
                                                context,
                                              ).iconTheme.color,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Save',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                buildTextField(
                                  controller: controller.customerNoController,
                                  label: 'Customer No',
                                  readOnly: true,
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: controller.nameController,
                                  label: 'Name',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: controller.addressController,
                                  label: 'Address',
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: controller.mobileNoController,
                                  label: 'Mobile No',
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a mobile number';
                                    }
                                    if (int.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller: controller.ntnNoController,
                                  label: 'NTN No',
                                ),
                                const SizedBox(height: 16),
                                buildTextField(
                                  controller:
                                      controller.openingBalanceController,
                                  label: 'Opening Balance',
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter opening balance';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Enter a valid number';
                                    }
                                    return null;
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        controller.clearForm();
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
                                      onPressed: () => controller.saveCustomer(
                                        context,
                                        customer: customer,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).iconTheme.color,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Save',
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
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
