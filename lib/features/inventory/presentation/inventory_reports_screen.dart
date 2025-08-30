import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class InventoryReportsScreen extends StatelessWidget {
  const InventoryReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample stock data
    final stockItems = [
      {"name": "Laptop", "category": "Electronics", "qty": 10, "cost": 50000},
      {"name": "Mouse", "category": "Electronics", "qty": 50, "cost": 500},
      {"name": "Chair", "category": "Furniture", "qty": 20, "cost": 2000},
      {"name": "Desk", "category": "Furniture", "qty": 5, "cost": 5000},
    ];

    // Low stock threshold
    const lowStockThreshold = 10;

    // Calculate total stock value
    final totalStockValue = stockItems.fold<int>(
      0,
      (sum, item) =>
          sum +
          (int.parse(item["qty"]!.toString()) *
              int.parse(item["cost"]!.toString())),
    );

    // Prepare stock movement sample data (IN/OUT)
    final stockMovement = [
      {"month": "Jan", "in": 30, "out": 10},
      {"month": "Feb", "in": 20, "out": 15},
      {"month": "Mar", "in": 25, "out": 5},
      {"month": "Apr", "in": 15, "out": 10},
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Value Summary
            Text(
              "Total Inventory Value",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Value", style: TextStyle(fontSize: 18.sp)),
                    Text(
                      "₹ $totalStockValue",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Low Stock Alerts
            Text(
              "Low Stock Alerts",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Column(
              children: stockItems
                  .where(
                    (item) =>
                        int.parse(item["qty"]!.toString()) <= lowStockThreshold,
                  )
                  .map(
                    (item) => Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        title: Text(item["name"]!.toString()),
                        subtitle: Text("Category: ${item["category"]}"),
                        trailing: Text(
                          "Qty: ${item["qty"]}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: 16.h),

            // Stock Movement Trends (Bar Chart)
            Text(
              "Stock Movement (IN/OUT)",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 250.h,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < stockMovement.length) {
                            return Text(
                              stockMovement[index]["month"]!.toString(),
                            );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  barGroups: List.generate(stockMovement.length, (index) {
                    final data = stockMovement[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: double.parse(data["in"]!.toString()),
                          color: Colors.green,
                        ),
                        BarChartRodData(
                          toY: double.parse(data["out"]!.toString()),
                          color: Colors.red,
                        ),
                      ],
                      showingTooltipIndicators: [0, 1],
                    );
                  }),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Optional: Stock table
            Text(
              "Current Stock List",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
              columns: const [
                DataColumn(label: Text("Item")),
                DataColumn(label: Text("Category")),
                DataColumn(label: Text("Quantity")),
                DataColumn(label: Text("Cost")),
              ],
              rows: stockItems
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(Text(item["name"]!.toString())),
                        DataCell(Text(item["category"]!.toString())),
                        DataCell(Text("${item["qty"]}")),
                        DataCell(Text("₹${item["cost"]}")),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
