import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PayrollScreen extends StatelessWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employees = [
      {"name": "John Doe", "designation": "Manager", "salary": "₹ 50,000"},
      {"name": "Jane Smith", "designation": "Developer", "salary": "₹ 35,000"},
      {
        "name": "Robert Brown",
        "designation": "Accountant",
        "salary": "₹ 40,000",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Payroll Management")),
      body: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: employees.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final emp = employees[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16.w),
              leading: CircleAvatar(child: Text(emp["name"]![0])),
              title: Text(emp["name"]!),
              subtitle: Text(emp["designation"]!),
              trailing: Text(
                emp["salary"]!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SalarySlipScreen(employee: emp),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEmployeeForm(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Employee"),
      ),
    );
  }

  void _openAddEmployeeForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddEmployeeForm());
  }
}

class SalarySlipScreen extends StatelessWidget {
  final Map<String, String> employee;
  const SalarySlipScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final allowances = [
      {"label": "HRA", "amount": "₹ 5,000"},
      {"label": "Bonus", "amount": "₹ 3,000"},
    ];
    final deductions = [
      {"label": "PF", "amount": "₹ 2,500"},
      {"label": "Tax", "amount": "₹ 4,000"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("${employee["name"]} - Salary Slip")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Designation: ${employee["designation"]}",
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              "Basic Salary: ${employee["salary"]}",
              style: TextStyle(fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Text("Allowances", style: Theme.of(context).textTheme.titleMedium),
            ...allowances.map(
              (a) => ListTile(
                title: Text(a["label"]!),
                trailing: Text(a["amount"]!),
              ),
            ),
            SizedBox(height: 8.h),
            Text("Deductions", style: Theme.of(context).textTheme.titleMedium),
            ...deductions.map(
              (d) => ListTile(
                title: Text(d["label"]!),
                trailing: Text(d["amount"]!),
              ),
            ),
            SizedBox(height: 16.h),
            Divider(),
            ListTile(
              title: const Text("Net Salary"),
              trailing: const Text(
                "₹ 51,500",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddEmployeeForm extends StatelessWidget {
  const _AddEmployeeForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final designationController = TextEditingController();
    final salaryController = TextEditingController();

    return AlertDialog(
      title: const Text("Add Employee"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: designationController,
                decoration: const InputDecoration(
                  labelText: "Designation",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Salary",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Employee Added")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
