import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: "General Ledger"),
    Tab(text: "Journal Entries"),
    Tab(text: "Trial Balance"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ledger & Accounting"),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GeneralLedgerView(),
          _JournalEntriesView(),
          _TrialBalanceView(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _openJournalEntryForm(context),
              icon: const Icon(Icons.add),
              label: const Text("New Entry"),
            )
          : null,
    );
  }

  void _openJournalEntryForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _JournalEntryForm(),
    );
  }
}

class _GeneralLedgerView extends StatelessWidget {
  const _GeneralLedgerView();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ["01/08/2025", "Cash", "Debit", "₹ 20,000"],
      ["01/08/2025", "Sales", "Credit", "₹ 20,000"],
      ["02/08/2025", "Rent Expense", "Debit", "₹ 5,000"],
      ["02/08/2025", "Cash", "Credit", "₹ 5,000"],
    ];

    return _DataTableWidget(
      headers: const ["Date", "Account", "Type", "Amount"],
      rows: rows,
    );
  }
}

class _JournalEntriesView extends StatelessWidget {
  const _JournalEntriesView();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ["01/08/2025", "Invoice #INV-001", "₹ 20,000", "Approved"],
      ["02/08/2025", "Office Rent", "₹ 5,000", "Pending"],
    ];

    return _DataTableWidget(
      headers: const ["Date", "Description", "Amount", "Status"],
      rows: rows,
    );
  }
}

class _TrialBalanceView extends StatelessWidget {
  const _TrialBalanceView();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ["Cash", "Debit", "₹ 15,000"],
      ["Sales", "Credit", "₹ 20,000"],
      ["Rent Expense", "Debit", "₹ 5,000"],
    ];

    return _DataTableWidget(
      headers: const ["Account", "Type", "Balance"],
      rows: rows,
    );
  }
}

class _JournalEntryForm extends StatelessWidget {
  const _JournalEntryForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: const Text("New Journal Entry"),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
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
                const SnackBar(content: Text("Journal Entry Added")),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class _DataTableWidget extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _DataTableWidget({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
        border: TableBorder.all(color: Colors.grey.shade300),
        columns: headers
            .map(
              (h) => DataColumn(
                label: Text(
                  h,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: rows
            .map(
              (r) => DataRow(
                cells: r.map((cell) => DataCell(Text(cell))).toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}
