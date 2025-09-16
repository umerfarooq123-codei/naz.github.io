import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/invoice.dart';
import 'invoice_add_edit.dart';
import 'invoice_repository.dart';

class InvoiceList extends StatefulWidget {
  const InvoiceList({super.key});

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  final InvoiceRepository _repo = InvoiceRepository();
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  void _fetchInvoices() async {
    final data = await _repo.getAllInvoices();
    setState(() => _invoices = data);
  }

  void _deleteInvoice(int id) async {
    await _repo.deleteInvoice(id);
    _fetchInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: _invoices.isEmpty
          ? const Center(child: Text('No invoices found.'))
          : ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text('Invoice: ${invoice.invoiceNumber}'),
                    subtitle: Text(
                      'Total: ₹${invoice.totalAmount} | Paid: ₹${invoice.paidAmount} | Balance: ₹${invoice.balance} \nDate: ${DateFormat.yMMMd().format(invoice.date)}',
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
                                    InvoiceAddEdit(invoice: invoice),
                              ),
                            );
                            _fetchInvoices();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteInvoice(invoice.id!),
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
            MaterialPageRoute(builder: (_) => const InvoiceAddEdit()),
          );
          _fetchInvoices();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
