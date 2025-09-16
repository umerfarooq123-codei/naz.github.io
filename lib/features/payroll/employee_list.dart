import 'package:flutter/material.dart';

import '../../core/models/employee.dart';
import 'employee_add_edit.dart';
import 'payroll_list.dart';
import 'payroll_repository.dart';

class EmployeeList extends StatefulWidget {
  const EmployeeList({super.key});

  @override
  State<EmployeeList> createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList> {
  final PayrollRepository _repo = PayrollRepository();
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  void _fetchEmployees() async {
    final data = await _repo.getAllEmployees();
    setState(() => _employees = data);
  }

  void _deleteEmployee(int id) async {
    await _repo.deleteEmployee(id);
    _fetchEmployees();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: _employees.isEmpty
          ? const Center(child: Text('No employees found.'))
          : ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(emp.name),
                    subtitle: Text(
                      '${emp.position} | ₹${emp.basicSalary.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EmployeeAddEdit(emp: emp),
                              ),
                            );
                            _fetchEmployees();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEmployee(emp.id!),
                        ),
                        IconButton(
                          icon: const Icon(Icons.payment, color: Colors.green),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PayrollList(employee: emp),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeAddEdit()),
          );
          _fetchEmployees();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
