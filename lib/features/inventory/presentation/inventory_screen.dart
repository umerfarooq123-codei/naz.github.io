import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "sku": "ITEM-001",
        "name": "Laptop",
        "cost": 45000,
        "price": 55000,
        "stock": 12,
      },
      {
        "sku": "ITEM-002",
        "name": "Office Chair",
        "cost": 3000,
        "price": 4500,
        "stock": 3,
      },
      {
        "sku": "ITEM-003",
        "name": "Printer Ink",
        "cost": 800,
        "price": 1200,
        "stock": 50,
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Management")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final lowStock = item["stock"] as int <= 5;

            return Card(
              margin: EdgeInsets.only(bottom: 12.h),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16.w),
                leading: CircleAvatar(
                  backgroundColor: lowStock
                      ? Colors.red[100]
                      : Colors.blue[100],
                  child: Icon(
                    lowStock ? Icons.warning_amber_rounded : Icons.inventory_2,
                    color: lowStock ? Colors.red : Colors.blue,
                  ),
                ),
                title: Text("${item["sku"]} - ${item["name"]}"),
                subtitle: Text(
                  "Cost: ₹${item["cost"]} | Price: ₹${item["price"]}",
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Stock: ${item["stock"]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: lowStock ? Colors.red : Colors.black,
                      ),
                    ),
                    if (lowStock)
                      const Text(
                        "Low Stock!",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
                onTap: () {
                  _openStockMovementDialog(context, item["name"].toString());
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openItemForm(context),
        icon: const Icon(Icons.add),
        label: const Text("New Item"),
      ),
    );
  }

  void _openItemForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ItemForm());
  }

  void _openStockMovementDialog(BuildContext context, String itemName) {
    showDialog(
      context: context,
      builder: (_) => _StockMovementForm(itemName: itemName),
    );
  }
}

class _ItemForm extends StatelessWidget {
  const _ItemForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final skuController = TextEditingController();
    final nameController = TextEditingController();
    final costController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    return AlertDialog(
      title: const Text("Add New Item"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: skuController,
                decoration: const InputDecoration(
                  labelText: "SKU",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Cost",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Selling Price",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Initial Stock",
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
              ).showSnackBar(const SnackBar(content: Text("Item Added")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class _StockMovementForm extends StatelessWidget {
  final String itemName;
  const _StockMovementForm({required this.itemName});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final qtyController = TextEditingController();
    String movementType = "In";

    return AlertDialog(
      title: Text("Stock Movement - $itemName"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 350.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: movementType,
                decoration: const InputDecoration(
                  labelText: "Movement Type",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "In", child: Text("Stock In")),
                  DropdownMenuItem(value: "Out", child: Text("Stock Out")),
                ],
                onChanged: (val) {
                  movementType = val ?? "In";
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Stock $movementType recorded for $itemName"),
                ),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
