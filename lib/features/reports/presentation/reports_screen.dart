import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/providers/ledger_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerState = ref.watch(journalListNotifierProvider);

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reports & Analytics"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "P&L"),
              Tab(text: "Balance Sheet"),
              Tab(text: "Cash Flow"),
              Tab(text: "Aging"),
              Tab(text: "Tax Reports"),
            ],
          ),
        ),
        body: ledgerState.loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _ProfitLossReport(entries: ledgerState.entries),
                  _BalanceSheetReport(entries: ledgerState.entries),
                  _CashFlowReport(entries: ledgerState.entries),
                  _AgingReport(entries: ledgerState.entries),
                  _TaxReports(entries: ledgerState.entries),
                ],
              ),
      ),
    );
  }
}

class _ProfitLossReport extends StatelessWidget {
  final List<LedgerEntry> entries;
  const _ProfitLossReport({required this.entries});

  @override
  Widget build(BuildContext context) {
    double totalIncome = entries.fold(
      0.0,
      (sum, e) => sum + e.lines.fold(0, (s, l) => s + l.credit),
    );
    double totalExpense = entries.fold(
      0.0,
      (sum, e) => sum + e.lines.fold(0, (s, l) => s + l.debit),
    );

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Profit & Loss",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text("Income");
                          case 1:
                            return const Text("Expense");
                          case 2:
                            return const Text("Net");
                          default:
                            return const Text("");
                        }
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(toY: totalIncome, color: Colors.green),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(toY: totalExpense, color: Colors.red),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: totalIncome - totalExpense,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSheetReport extends StatelessWidget {
  final List<LedgerEntry> entries;
  const _BalanceSheetReport({required this.entries});

  @override
  Widget build(BuildContext context) {
    double assets = entries.fold(
      0.0,
      (sum, e) =>
          sum +
          e.lines.where((l) => l.debit > 0).fold(0.0, (s, l) => s + l.debit),
    );
    double liabilities = entries.fold(
      0.0,
      (sum, e) =>
          sum +
          e.lines.where((l) => l.credit > 0).fold(0.0, (s, l) => s + l.credit),
    );

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Balance Sheet",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text("Assets"),
                  trailing: Text("₹$assets"),
                ),
                ListTile(
                  title: const Text("Liabilities"),
                  trailing: Text("₹$liabilities"),
                ),
                ListTile(
                  title: const Text("Equity"),
                  trailing: Text("₹${assets - liabilities}"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowReport extends StatelessWidget {
  final List<LedgerEntry> entries;
  const _CashFlowReport({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Simple cash inflow/outflow using ledger lines
    double inflow = entries.fold(
      0.0,
      (sum, e) =>
          sum +
          e.lines.where((l) => l.credit > 0).fold(0.0, (s, l) => s + l.credit),
    );
    double outflow = entries.fold(
      0.0,
      (sum, e) =>
          sum +
          e.lines.where((l) => l.debit > 0).fold(0.0, (s, l) => s + l.debit),
    );

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cash Flow Statement",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, inflow),
                      FlSpot(1, outflow),
                      FlSpot(2, inflow - outflow),
                    ],
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blue,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgingReport extends StatelessWidget {
  final List<LedgerEntry> entries;
  const _AgingReport({required this.entries});

  @override
  Widget build(BuildContext context) {
    final debtors = entries
        .map(
          (e) => {
            "name": e.description,
            "amount": e.totalDebit(),
            "days": DateTime.now().difference(e.date).inDays,
          },
        )
        .toList();

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Debtors Aging Report",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 16.h),
          Expanded(
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Name")),
                DataColumn(label: Text("Amount")),
                DataColumn(label: Text("Days Outstanding")),
              ],
              rows: debtors
                  .map(
                    (d) => DataRow(
                      cells: [
                        DataCell(Text(d["name"].toString())),
                        DataCell(Text("₹${d["amount"]}")),
                        DataCell(Text("${d["days"]} days")),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxReports extends StatelessWidget {
  final List<LedgerEntry> entries;
  const _TaxReports({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Simple GST example: 18% of credit entries
    double gstCollected = entries.fold(
      0.0,
      (sum, e) =>
          sum +
          e.lines
              .where((l) => l.credit > 0)
              .fold(0.0, (s, l) => s + l.credit * 0.18),
    );
    double gstPaid = entries.fold(
      0.0,
      (sum, e) =>
          sum +
          e.lines
              .where((l) => l.debit > 0)
              .fold(0.0, (s, l) => s + l.debit * 0.18),
    );

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tax Reports", style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: const Text("GST Collected"),
                  trailing: Text("₹$gstCollected"),
                ),
                ListTile(
                  title: const Text("GST Paid"),
                  trailing: Text("₹$gstPaid"),
                ),
                ListTile(
                  title: const Text("VAT Liability"),
                  trailing: Text("₹${gstCollected - gstPaid}"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
