import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/employee.dart';
import '../../core/models/payroll.dart';
import 'payroll_add_edit.dart';
import 'payroll_repository.dart';

class PayrollList extends StatefulWidget {
  final Employee employee;
  const PayrollList({super.key, required this.employee});

  @override
  State<PayrollList> createState() => _PayrollListState();
}

class _PayrollListState extends State<PayrollList> {
  final PayrollRepository _repo = PayrollRepository();
  List<Payroll> _payrolls = [];

  @override
  void initState() {
    super.initState();
    _fetchPayrolls();
  }

  void _fetchPayrolls() async {
    final all = await _repo.getAllPayrolls();
    setState(() {
      _payrolls = all.where((p) => p.employeeId == widget.employee.id).toList();
    });
  }

  void _deletePayroll(int id) async {
    await _repo.deletePayroll(id);
    _fetchPayrolls();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.employee.name} Payroll')),
      body: _payrolls.isEmpty
          ? const Center(child: Text('No payroll records.'))
          : ListView.builder(
              itemCount: _payrolls.length,
              itemBuilder: (context, index) {
                final p = _payrolls[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      'Net Salary: ₹${p.netSalary.toStringAsFixed(2)}',
                    ),
                    subtitle: Text(
                      'Basic: ₹${p.basicSalary} | Allowances: ₹${p.allowances} | Deductions: ₹${p.deductions}\nDate: ${DateFormat.yMMMd().format(p.date)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePayroll(p.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PayrollAddEdit(employee: widget.employee),
            ),
          );
          _fetchPayrolls();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
