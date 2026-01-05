import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/cans.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';

import 'cans_controller.dart';

class CansEntryAddEdit extends StatefulWidget {
  final Cans cans;
  final CansController controller;
  final CansEntry? entry;

  const CansEntryAddEdit({
    super.key,
    required this.cans,
    required this.controller,
    this.entry,
  });

  @override
  State<CansEntryAddEdit> createState() => _CansEntryAddEditState();
}

class _CansEntryAddEditState extends State<CansEntryAddEdit> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _dateController;
  late TextEditingController _voucherController;
  late TextEditingController _currentCansController;
  late TextEditingController _receivedCansController;
  late TextEditingController _descriptionController;
  late Rx<String> _selectedType;
  late DateTime _selectedDate;
  late ValueNotifier<int> _balanceUpdate;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _dateController = TextEditingController();
    _voucherController = TextEditingController();
    _currentCansController = TextEditingController();
    _receivedCansController = TextEditingController();
    _descriptionController = TextEditingController();
    _balanceUpdate = ValueNotifier<int>(0);

    if (widget.entry != null) {
      _selectedDate = widget.entry!.date;
      _dateController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
      _voucherController.text = widget.entry!.voucherNo;
      _selectedType = widget.entry!.transactionType.obs;
      _currentCansController.text = widget.entry!.currentCans.toString();
      _receivedCansController.text = widget.entry!.receivedCans.toString();
      _descriptionController.text = widget.entry!.description ?? '';
    } else {
      _selectedDate = DateTime.now();
      _dateController.text = DateFormat('dd-MM-yyyy').format(_selectedDate);
      _selectedType = 'Received'.obs;
    }

    // Add listeners to update balance summary in real-time
    _currentCansController.addListener(_updateBalance);
    _receivedCansController.addListener(_updateBalance);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _voucherController.dispose();
    _currentCansController.dispose();
    _receivedCansController.dispose();
    _descriptionController.dispose();
    _balanceUpdate.dispose();
    super.dispose();
  }

  void _updateBalance() {
    _balanceUpdate.value = DateTime.now().millisecondsSinceEpoch;
  }

  /// Calculate the previous balance (running balance from all previous entries)
  double _calculatePreviousBalance() {
    double balance = widget.cans.openingBalanceCans;

    // Get entries sorted by createdAt ascending (oldest first for balance calculation)
    final sortedEntries = List<CansEntry>.from(widget.controller.cansEntries);
    sortedEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // If editing, calculate balance up to (but not including) this entry
    // If adding, calculate balance of all entries
    for (var entry in sortedEntries) {
      if (widget.entry != null && entry.id == widget.entry!.id) {
        // Stop at the current entry when editing
        break;
      }
      balance += entry.currentCans - entry.receivedCans;
    }

    return balance;
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 100), () {
      CansRepository().generateVoucherNoByCanId(widget.cans.id!).then((
        voucherNo,
      ) {
        if (widget.entry == null) {
          _voucherController.text = voucherNo;
        }
      });
    });
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth > 600
                ? 600
                : constraints.maxWidth * 0.9,
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
                        widget.entry == null
                            ? 'Add New Transaction'
                            : 'Edit Transaction',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      _buildSection('Basic Information', [
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                                _dateController.text = DateFormat(
                                  'dd-MM-yyyy',
                                ).format(picked);
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Date is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _voucherController,
                          decoration: InputDecoration(
                            labelText: 'Voucher No',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Voucher no is required';
                            }
                            return null;
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Cans Details', [
                        TextFormField(
                          controller: _currentCansController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Current Cans',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Current cans is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _receivedCansController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Received Cans',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Received cans is required';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Balance Summary', [
                        ValueListenableBuilder<int>(
                          valueListenable: _balanceUpdate,
                          builder: (context, _, __) {
                            // Calculate previous balance based on all existing entries
                            final previousCans = _calculatePreviousBalance();
                            final currentCans =
                                double.tryParse(_currentCansController.text) ??
                                0.0;
                            final totalCans = previousCans + currentCans;
                            final receivedCans =
                                double.tryParse(_receivedCansController.text) ??
                                0.0;
                            final finalBalance = totalCans - receivedCans;

                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildBalanceRow(
                                        'Previous Cans',
                                        previousCans.toStringAsFixed(2),
                                        context,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildBalanceRow(
                                        'Current Cans',
                                        currentCans.toStringAsFixed(2),
                                        context,
                                      ),
                                      const Divider(height: 16),
                                      _buildBalanceRow(
                                        'Total Cans',
                                        totalCans.toStringAsFixed(2),
                                        context,
                                        isBold: true,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildBalanceRow(
                                        'Received Cans',
                                        receivedCans.toStringAsFixed(2),
                                        context,
                                      ),
                                      const Divider(height: 16),
                                      _buildBalanceRow(
                                        'Final Balance',
                                        finalBalance.toStringAsFixed(2),
                                        context,
                                        isBold: true,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Additional', [
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Enter any notes or description',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextButton(
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  final entry = CansEntry(
                                    id: widget.entry?.id,
                                    cansId: widget.cans.id!,
                                    voucherNo: _voucherController.text,
                                    accountId: widget.cans.accountId,
                                    accountName: widget.cans.accountName,
                                    date: _selectedDate,
                                    transactionType: _selectedType.value,
                                    currentCans: double.parse(
                                      _currentCansController.text,
                                    ),
                                    receivedCans: double.parse(
                                      _receivedCansController.text,
                                    ),
                                    balance:
                                        widget.cans.openingBalanceCans +
                                        double.parse(
                                          _currentCansController.text,
                                        ) -
                                        double.parse(
                                          _receivedCansController.text,
                                        ),
                                    description:
                                        _descriptionController.text.isEmpty
                                        ? null
                                        : _descriptionController.text,
                                    createdAt:
                                        widget.entry?.createdAt ??
                                        DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  if (widget.entry == null) {
                                    await widget.controller.addCansEntry(entry);
                                  } else {
                                    await widget.controller.updateCansEntry(
                                      entry,
                                    );
                                  }

                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                widget.entry == null ? 'Add' : 'Update',
                                style: Theme.of(context).textTheme.labelLarge,
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

  Widget _buildBalanceRow(
    String label,
    String value,
    BuildContext context, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
