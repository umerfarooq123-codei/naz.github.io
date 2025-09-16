import 'package:flutter/material.dart';

import '../../core/models/customer.dart';
import '../../core/models/invoice.dart';
import '../../features/customer_vendor/customer_repository.dart';
import 'invoice_repository.dart';

class InvoiceAddEdit extends StatefulWidget {
  final Invoice? invoice;
  const InvoiceAddEdit({super.key, this.invoice});

  @override
  State<InvoiceAddEdit> createState() => _InvoiceAddEditState();
}

class _InvoiceAddEditState extends State<InvoiceAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Customer? _selectedCustomer;

  final InvoiceRepository _repo = InvoiceRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    if (widget.invoice != null) {
      _invoiceNumberController.text = widget.invoice!.invoiceNumber;
      _totalAmountController.text = widget.invoice!.totalAmount.toString();
      _paidAmountController.text = widget.invoice!.paidAmount.toString();
      _selectedDate = widget.invoice!.date;
      // Assign selected customer later after fetching list
    }
  }

  void _fetchCustomers() async {
    final data = await _customerRepo.getAllCustomers();
    setState(() {
      _customers = data;
      if (widget.invoice != null) {
        _selectedCustomer = _customers.firstWhere(
          (c) => c.id == widget.invoice!.customerId,
        );
      }
    });
  }

  void _saveInvoice() async {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      final invoice = Invoice(
        id: widget.invoice?.id,
        customerId: _selectedCustomer!.id!,
        invoiceNumber: _invoiceNumberController.text,
        date: _selectedDate,
        totalAmount: double.parse(_totalAmountController.text),
        paidAmount: double.parse(_paidAmountController.text),
      );
      if (widget.invoice == null) {
        await _repo.insertInvoice(invoice);
      } else {
        await _repo.updateInvoice(invoice);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.invoice == null ? 'Add Invoice' : 'Edit Invoice'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _customers.isEmpty
            ? const Center(child: Text('No customers available.'))
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<Customer>(
                      initialValue: _selectedCustomer,
                      items: _customers
                          .map(
                            (c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCustomer = val),
                      decoration: const InputDecoration(labelText: 'Customer'),
                      validator: (val) =>
                          val == null ? 'Select customer' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
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
                      onPressed: _saveInvoice,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
