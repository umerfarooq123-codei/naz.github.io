import 'package:flutter/material.dart';

import '../../core/models/employee.dart';
import 'payroll_repository.dart';

class EmployeeAddEdit extends StatefulWidget {
  final Employee? emp;
  const EmployeeAddEdit({super.key, this.emp});

  @override
  State<EmployeeAddEdit> createState() => _EmployeeAddEditState();
}

class _EmployeeAddEditState extends State<EmployeeAddEdit> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _salaryController = TextEditingController();

  final PayrollRepository _repo = PayrollRepository();

  @override
  void initState() {
    super.initState();
    if (widget.emp != null) {
      _nameController.text = widget.emp!.name;
      _positionController.text = widget.emp!.position;
      _salaryController.text = widget.emp!.basicSalary.toString();
    }
  }

  void _saveEmployee() async {
    if (_formKey.currentState!.validate()) {
      final emp = Employee(
        id: widget.emp?.id,
        name: _nameController.text,
        position: _positionController.text,
        basicSalary: double.parse(_salaryController.text),
      );
      if (widget.emp == null) {
        await _repo.insertEmployee(emp);
      } else {
        await _repo.updateEmployee(emp);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.emp == null ? 'Add Employee' : 'Edit Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Basic Salary'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEmployee,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
