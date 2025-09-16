import 'package:flutter/material.dart';

import '../../core/models/employee.dart';
import 'payroll_repository.dart';

class PayrollAddEdit extends StatefulWidget {
  final Employee employee;
  const PayrollAddEdit({super.key, required this.employee});

  @override
  State<PayrollAddEdit> createState() => _PayrollAddEditState();
}

class _PayrollAddEditState extends State<PayrollAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _allowancesController = TextEditingController(text: '0');
  final _deductionsController = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  final PayrollRepository _repo = PayrollRepository();

  void _generatePayroll() async {
    if (_formKey.currentState!.validate()) {
      await _repo.generatePayroll(
        widget.employee.id!,
        double.parse(_allowancesController.text),
        double.parse(_deductionsController.text),
        _date,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Payroll')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Employee: ${widget.employee.name}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allowancesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Allowances'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deductionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Deductions'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${_date.toLocal()}'.split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generatePayroll,
                child: const Text('Generate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
