import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VendorsScreen extends StatelessWidget {
  const VendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendors = [
      {
        "name": "Tech Supplies Ltd",
        "contact": "support@techsupplies.com",
        "balance": "₹ 75,000",
      },
      {
        "name": "Global Traders",
        "contact": "global@trade.com",
        "balance": "₹ 45,000",
      },
      {
        "name": "Office Essentials",
        "contact": "info@officeessentials.com",
        "balance": "₹ 10,000",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Vendors")),
      body: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemBuilder: (context, index) {
          final vendor = vendors[index];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            tileColor: Colors.grey.shade100,
            leading: CircleAvatar(child: Text(vendor["name"]![0])),
            title: Text(vendor["name"]!),
            subtitle: Text(vendor["contact"]!),
            trailing: Text(
              vendor["balance"]!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorLedgerScreen(name: vendor["name"]!),
                ),
              );
            },
          );
        },
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemCount: vendors.length,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVendorForm(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Vendor"),
      ),
    );
  }

  void _openVendorForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _VendorForm());
  }
}

class VendorLedgerScreen extends StatelessWidget {
  final String name;

  const VendorLedgerScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      ["02/08/2025", "Purchase Order #PO-2001", "₹ 40,000", "Unpaid"],
      ["04/08/2025", "Payment Made", "₹ 25,000", "Settled"],
      ["06/08/2025", "Purchase Order #PO-2002", "₹ 20,000", "Unpaid"],
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

class _VendorForm extends StatelessWidget {
  const _VendorForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();

    return AlertDialog(
      title: const Text("Add Vendor"),
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
              ).showSnackBar(const SnackBar(content: Text("Vendor Added")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
