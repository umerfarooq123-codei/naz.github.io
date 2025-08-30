import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = [
      {"name": "John Doe", "contact": "9876543210", "balance": "₹ 25,000"},
      {
        "name": "Acme Corp",
        "contact": "info@acme.com",
        "balance": "₹ 1,20,000",
      },
      {"name": "Jane Smith", "contact": "9998877665", "balance": "₹ 8,500"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Customers")),
      body: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            tileColor: Colors.grey.shade100,
            leading: CircleAvatar(child: Text(customer["name"]![0])),
            title: Text(customer["name"]!),
            subtitle: Text(customer["contact"]!),
            trailing: Text(
              customer["balance"]!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerLedgerScreen(name: customer["name"]!),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemCount: customers.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomerForm(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Customer"),
      ),
    );
  }

  void _openCustomerForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _CustomerForm());
  }
}

class CustomerLedgerScreen extends StatelessWidget {
  final String name;

  const CustomerLedgerScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      ["01/08/2025", "Invoice #1001", "₹ 20,000", "Pending"],
      ["03/08/2025", "Payment Received", "₹ 10,000", "Settled"],
      ["05/08/2025", "Invoice #1002", "₹ 15,000", "Pending"],
    ];

    return Scaffold(
      appBar: AppBar(title: Text("$name - Ledger")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
          border: TableBorder.all(color: Colors.grey.shade300),
          columns: const [
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Description")),
            DataColumn(label: Text("Amount")),
            DataColumn(label: Text("Status")),
          ],
          rows: transactions
              .map(
                (row) => DataRow(
                  cells: row.map((cell) => DataCell(Text(cell))).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _CustomerForm extends StatelessWidget {
  const _CustomerForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    return AlertDialog(
      title: const Text("Add Customer"),
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
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: "Contact Info",
                  border: OutlineInputBorder(),
                ),
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
              ).showSnackBar(const SnackBar(content: Text("Customer Added")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
