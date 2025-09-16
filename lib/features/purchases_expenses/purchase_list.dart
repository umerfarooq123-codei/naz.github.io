import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/purchase.dart';
import 'purchase_add_edit.dart';
import 'purchase_expense_repository.dart';

class PurchaseList extends StatefulWidget {
  const PurchaseList({super.key});

  @override
  State<PurchaseList> createState() => _PurchaseListState();
}

class _PurchaseListState extends State<PurchaseList> {
  final PurchaseExpenseRepository _repo = PurchaseExpenseRepository();
  List<Purchase> _purchases = [];

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  void _fetchPurchases() async {
    final data = await _repo.getAllPurchases();
    setState(() => _purchases = data);
  }

  void _deletePurchase(int id) async {
    await _repo.deletePurchase(id);
    _fetchPurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchases')),
      body: _purchases.isEmpty
          ? const Center(child: Text('No purchases found.'))
          : ListView.builder(
              itemCount: _purchases.length,
              itemBuilder: (context, index) {
                final purchase = _purchases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text('Purchase: ${purchase.purchaseNumber}'),
                    subtitle: Text(
                      'Total: ₹${purchase.totalAmount} | Paid: ₹${purchase.paidAmount} | Balance: ₹${purchase.balance} \nDate: ${DateFormat.yMMMd().format(purchase.date)}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PurchaseAddEdit(purchase: purchase),
                              ),
                            );
                            _fetchPurchases();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePurchase(purchase.id!),
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
            MaterialPageRoute(builder: (_) => const PurchaseAddEdit()),
          );
          _fetchPurchases();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
