import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/bank_transaction.dart';
import 'bank_repository.dart';
import 'bank_transaction_add_edit.dart';

class BankTransactionList extends StatefulWidget {
  const BankTransactionList({super.key});

  @override
  State<BankTransactionList> createState() => _BankTransactionListState();
}

class _BankTransactionListState extends State<BankTransactionList> {
  final BankRepository _repo = BankRepository();
  List<BankTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  void _fetchTransactions() async {
    final data = await _repo.getAllTransactions();
    setState(() => _transactions = data);
  }

  void _deleteTransaction(int id) async {
    await _repo.deleteTransaction(id);
    _fetchTransactions();
  }

  void _toggleCleared(BankTransaction tx) async {
    await _repo.markCleared(tx.id!, !tx.cleared);
    _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Transactions')),
      body: _transactions.isEmpty
          ? const Center(child: Text('No bank transactions.'))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(tx.description),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(tx.date)} | ${tx.type} | ₹${tx.amount.toStringAsFixed(2)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: tx.cleared,
                          onChanged: (_) => _toggleCleared(tx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.indigo),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BankTransactionAddEdit(tx: tx),
                              ),
                            );
                            _fetchTransactions();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTransaction(tx.id!),
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
            MaterialPageRoute(builder: (_) => const BankTransactionAddEdit()),
          );
          _fetchTransactions();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
