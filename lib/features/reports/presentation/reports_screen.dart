import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        body: const TabBarView(
          children: [
            _ProfitLossReport(),
            _BalanceSheetReport(),
            _CashFlowReport(),
            _AgingReport(),
            _TaxReports(),
          ],
        ),
      ),
    );
  }
}

class _ProfitLossReport extends StatelessWidget {
  const _ProfitLossReport();

  @override
  Widget build(BuildContext context) {
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
                            return const Text("Jan");
                          case 1:
                            return const Text("Feb");
                          case 2:
                            return const Text("Mar");
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
                    barRods: [BarChartRodData(toY: 50000, color: Colors.green)],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [BarChartRodData(toY: 30000, color: Colors.red)],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [BarChartRodData(toY: 70000, color: Colors.green)],
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
  const _BalanceSheetReport();

  @override
  Widget build(BuildContext context) {
    final items = [
      {"label": "Assets", "value": 250000},
      {"label": "Liabilities", "value": 100000},
      {"label": "Equity", "value": 150000},
    ];

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
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item["label"].toString()),
                  trailing: Text("₹${item["value"]}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowReport extends StatelessWidget {
  const _CashFlowReport();

  @override
  Widget build(BuildContext context) {
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
                      const FlSpot(0, 5000),
                      const FlSpot(1, 12000),
                      const FlSpot(2, 8000),
                      const FlSpot(3, 15000),
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
  const _AgingReport();

  @override
  Widget build(BuildContext context) {
    final debtors = [
      {"name": "Customer A", "amount": 15000, "days": 30},
      {"name": "Customer B", "amount": 22000, "days": 45},
      {"name": "Customer C", "amount": 8000, "days": 60},
    ];

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
              rows: debtors.map((d) {
                return DataRow(
                  cells: [
                    DataCell(Text(d["name"].toString())),
                    DataCell(Text("₹${d["amount"]}")),
                    DataCell(Text("${d["days"]} days")),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxReports extends StatelessWidget {
  const _TaxReports();

  @override
  Widget build(BuildContext context) {
    final taxes = [
      {"label": "GST Collected", "value": 18000},
      {"label": "GST Paid", "value": 12000},
      {"label": "VAT Liability", "value": 5000},
    ];

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tax Reports", style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 16.h),
          Expanded(
            child: ListView.separated(
              itemCount: taxes.length,
              separatorBuilder: (_, __) => Divider(),
              itemBuilder: (context, index) {
                final item = taxes[index];
                return ListTile(
                  title: Text(item["label"].toString()),
                  trailing: Text("₹${item["value"]}"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
