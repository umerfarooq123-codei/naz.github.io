import 'package:flutter/material.dart';

import '../../core/models/bank_transaction.dart';
import 'bank_repository.dart';

class BankTransactionAddEdit extends StatefulWidget {
  final BankTransaction? tx;
  const BankTransactionAddEdit({super.key, this.tx});

  @override
  State<BankTransactionAddEdit> createState() => _BankTransactionAddEditState();
}

class _BankTransactionAddEditState extends State<BankTransactionAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'CREDIT';
  DateTime _selectedDate = DateTime.now();
  final BankRepository _repo = BankRepository();

  @override
  void initState() {
    super.initState();
    if (widget.tx != null) {
      _descController.text = widget.tx!.description;
      _amountController.text = widget.tx!.amount.toString();
      _type = widget.tx!.type;
      _selectedDate = widget.tx!.date;
    }
  }

  void _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      final tx = BankTransaction(
        id: widget.tx?.id,
        description: _descController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        type: _type,
        cleared: widget.tx?.cleared ?? false,
      );
      if (widget.tx == null) {
        await _repo.insertTransaction(tx);
      } else {
        await _repo.updateTransaction(tx);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tx == null ? 'Add Bank Transaction' : 'Edit Bank Transaction',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: ['CREDIT', 'DEBIT']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _type = val!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveTransaction,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
