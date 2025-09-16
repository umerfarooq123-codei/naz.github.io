import 'package:flutter/material.dart';

import 'report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportRepository _repo = ReportRepository();

  Map<String, double> _pnl = {};
  Map<String, double> _balanceSheet = {};
  Map<String, double> _cashFlow = {};
  List<Map<String, dynamic>> _debtors = [];
  List<Map<String, dynamic>> _creditors = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() async {
    final pnl = await _repo.getProfitAndLoss();
    final bs = await _repo.getBalanceSheet();
    final cf = await _repo.getCashFlow();
    final debtors = await _repo.getDebtorsAging();
    final creditors = await _repo.getCreditorsAging();

    setState(() {
      _pnl = pnl;
      _balanceSheet = bs;
      _cashFlow = cf;
      _debtors = debtors;
      _creditors = creditors;
    });
  }

  Widget _buildMapReport(Map<String, double> data) {
    return Column(
      children: data.entries
          .map(
            (e) => ListTile(
              title: Text(e.key),
              trailing: Text('₹${e.value.toStringAsFixed(2)}'),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListReport(
    List<Map<String, dynamic>> data,
    String keyField,
    String valueField,
  ) {
    return Column(
      children: data
          .map(
            (e) => ListTile(
              title: Text(e[keyField]),
              trailing: Text('₹${e[valueField]?.toStringAsFixed(2)}'),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profit & Loss',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildMapReport(_pnl),
            const Divider(),
            const Text(
              'Balance Sheet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildMapReport(_balanceSheet),
            const Divider(),
            const Text(
              'Cash Flow',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildMapReport(_cashFlow),
            const Divider(),
            const Text(
              'Debtors Aging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildListReport(_debtors, 'Customer', 'Outstanding'),
            const Divider(),
            const Text(
              'Creditors Aging',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _buildListReport(_creditors, 'Vendor', 'Outstanding'),
          ],
        ),
      ),
    );
  }
}
