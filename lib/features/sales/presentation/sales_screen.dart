import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invoices = [
      {
        "id": "INV-1001",
        "customer": "John Doe",
        "amount": "₹ 20,000",
        "status": "Unpaid",
      },
      {
        "id": "INV-1002",
        "customer": "Acme Corp",
        "amount": "₹ 15,000",
        "status": "Partial",
      },
      {
        "id": "INV-1003",
        "customer": "Jane Smith",
        "amount": "₹ 10,000",
        "status": "Paid",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Sales & Invoicing")),
      body: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: invoices.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final inv = invoices[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16.w),
              leading: CircleAvatar(child: Text(inv["id"]!.split("-")[1])),
              title: Text(inv["id"]!),
              subtitle: Text("Customer: ${inv["customer"]}"),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inv["amount"]!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    inv["status"]!,
                    style: TextStyle(
                      color: inv["status"] == "Paid"
                          ? Colors.green
                          : inv["status"] == "Partial"
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InvoiceDetailScreen(invoice: inv),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openInvoiceForm(context),
        icon: const Icon(Icons.add),
        label: const Text("New Invoice"),
      ),
    );
  }

  void _openInvoiceForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _InvoiceForm());
  }
}

class InvoiceDetailScreen extends StatelessWidget {
  final Map<String, String> invoice;

  const InvoiceDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final items = [
      {"name": "Laptop", "qty": "2", "rate": "₹ 50,000", "total": "₹ 100,000"},
      {"name": "Mouse", "qty": "5", "rate": "₹ 500", "total": "₹ 2,500"},
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Invoice ${invoice["id"]}")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Customer: ${invoice["customer"]}",
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                border: TableBorder.all(color: Colors.grey.shade300),
                columns: const [
                  DataColumn(label: Text("Item")),
                  DataColumn(label: Text("Qty")),
                  DataColumn(label: Text("Rate")),
                  DataColumn(label: Text("Total")),
                ],
                rows: items
                    .map(
                      (item) => DataRow(
                        cells: [
                          DataCell(Text(item["name"]!)),
                          DataCell(Text(item["qty"]!)),
                          DataCell(Text(item["rate"]!)),
                          DataCell(Text(item["total"]!)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: 16.h),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invoice Exported as PDF")),
                  );
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Export PDF"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceForm extends StatelessWidget {
  const _InvoiceForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final customerController = TextEditingController();
    final amountController = TextEditingController();

    return AlertDialog(
      title: const Text("New Invoice"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: customerController,
                decoration: const InputDecoration(
                  labelText: "Customer",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Unpaid", child: Text("Unpaid")),
                  DropdownMenuItem(value: "Partial", child: Text("Partial")),
                  DropdownMenuItem(value: "Paid", child: Text("Paid")),
                ],
                onChanged: (val) {},
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
              ).showSnackBar(const SnackBar(content: Text("Invoice Created")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
