import 'package:flutter/material.dart';

import '../../core/models/purchase.dart';
import '../../core/models/vendor.dart';
import '../../features/customer_vendor/customer_repository.dart';
import 'purchase_expense_repository.dart';

class PurchaseAddEdit extends StatefulWidget {
  final Purchase? purchase;
  const PurchaseAddEdit({super.key, this.purchase});

  @override
  State<PurchaseAddEdit> createState() => _PurchaseAddEditState();
}

class _PurchaseAddEditState extends State<PurchaseAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _purchaseNumberController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Vendor? _selectedVendor;

  final PurchaseExpenseRepository _repo = PurchaseExpenseRepository();
  final CustomerRepository _vendorRepo =
      CustomerRepository(); // reuse repository for vendors
  final List<Vendor> _vendors = [];

  @override
  void initState() {
    super.initState();
    _fetchVendors();
    if (widget.purchase != null) {
      _purchaseNumberController.text = widget.purchase!.purchaseNumber;
      _totalAmountController.text = widget.purchase!.totalAmount.toString();
      _paidAmountController.text = widget.purchase!.paidAmount.toString();
    }
  }

  void _fetchVendors() async {
    // final data = await _vendorRepo.getAllVendors();
    // setState(() {
    //   _vendors = data;
    //   if (widget.purchase != null) {
    //     _selectedVendor = _vendors.firstWhere(
    //       (v) => v.id == widget.purchase!.vendorId,
    //     );
    //   }
    // });
  }

  void _savePurchase() async {
    if (_formKey.currentState!.validate() && _selectedVendor != null) {
      final purchase = Purchase(
        id: widget.purchase?.id,
        vendorId: _selectedVendor!.id!,
        purchaseNumber: _purchaseNumberController.text,
        date: _selectedDate,
        totalAmount: double.parse(_totalAmountController.text),
        paidAmount: double.parse(_paidAmountController.text),
      );
      if (widget.purchase == null) {
        await _repo.insertPurchase(purchase);
      } else {
        await _repo.updatePurchase(purchase);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchase == null ? 'Add Purchase' : 'Edit Purchase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _vendors.isEmpty
            ? const Center(child: Text('No vendors available.'))
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<Vendor>(
                      initialValue: _selectedVendor,
                      items: _vendors
                          .map(
                            (v) =>
                                DropdownMenuItem(value: v, child: Text(v.name)),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedVendor = val),
                      decoration: const InputDecoration(labelText: 'Vendor'),
                      validator: (val) => val == null ? 'Select vendor' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _purchaseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Purchase Number',
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _totalAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Amount',
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _paidAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Paid Amount',
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Date: ${_selectedDate.toLocal()}'.split(' ')[0],
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _savePurchase,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
