import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/providers/ledger_providers.dart';
import 'package:uuid/uuid.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  final LedgerEntry? entry;
  const JournalEntryScreen({super.key, this.entry});

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtl = TextEditingController();
  DateTime _date = DateTime.now();
  List<LedgerLine> _lines = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    if (e != null) {
      _descCtl.text = e.description;
      _date = e.date;
      _lines = e.lines.map((l) => l.copyWith()).toList();
    } else {
      // start with two lines for double-entry convenience
      _lines = [
        LedgerLine(accountId: '', debit: 0.0, credit: 0.0),
        LedgerLine(accountId: '', debit: 0.0, credit: 0.0),
      ];
    }
  }

  @override
  void dispose() {
    _descCtl.dispose();
    super.dispose();
  }

  double get totalDebit => _lines.fold(0.0, (s, l) => s + l.debit);
  double get totalCredit => _lines.fold(0.0, (s, l) => s + l.credit);

  void _addLine() {
    setState(() {
      _lines = [..._lines, LedgerLine(accountId: '', debit: 0.0, credit: 0.0)];
    });
  }

  void _removeLine(int idx) {
    setState(() {
      final copy = [..._lines];
      copy.removeAt(idx);
      _lines = copy;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.entry?.id ?? _uuid.v4();
    final entry = LedgerEntry(
      id: id,
      date: _date,
      description: _descCtl.text.trim(),
      lines: _lines,
    );
    if (!entry.isBalanced()) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Not balanced'),
          content: Text(
            'Total debit ${totalDebit.toStringAsFixed(2)} != total credit ${totalCredit.toStringAsFixed(2)}. Do you want to save anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (!(ok ?? false)) return;
    }

    final notifier = ref.read(journalListNotifierProvider.notifier);
    if (widget.entry != null) {
      await notifier.updateEntry(entry);
    } else {
      await notifier.createEntry(entry);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry == null ? 'New Journal Entry' : 'Edit Journal Entry',
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _descCtl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(dateFmt.format(_date)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Line'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final line = _lines[i];
                  final acctCtl = TextEditingController(text: line.accountId);
                  final debitCtl = TextEditingController(
                    text: line.debit == 0.0 ? '' : line.debit.toString(),
                  );
                  final creditCtl = TextEditingController(
                    text: line.credit == 0.0 ? '' : line.credit.toString(),
                  );
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: acctCtl,
                                  decoration: const InputDecoration(
                                    labelText: 'Account ID',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) => setState(
                                    () => _lines[i] = _lines[i].copyWith(
                                      accountId: v,
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Account required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_forever),
                                onPressed: () {
                                  _removeLine(i);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: debitCtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Debit',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) {
                                    final parsed = double.tryParse(v) ?? 0.0;
                                    setState(
                                      () => _lines[i] = _lines[i].copyWith(
                                        debit: parsed,
                                        credit: 0.0,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: creditCtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Credit',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (v) {
                                    final parsed = double.tryParse(v) ?? 0.0;
                                    setState(
                                      () => _lines[i] = _lines[i].copyWith(
                                        credit: parsed,
                                        debit: 0.0,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Debit: ${totalDebit.toStringAsFixed(2)}'),
                      Text('Total Credit: ${totalCredit.toStringAsFixed(2)}'),
                      Text(
                        'Balanced: ${(totalDebit - totalCredit).abs() < 0.0001 ? "Yes" : "No"}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
