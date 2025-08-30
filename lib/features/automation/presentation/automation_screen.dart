import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AutomationScreen extends StatelessWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Automation & Integrations")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: ListView(
          children: [
            _ActionCard(
              icon: Icons.upload_file,
              title: "Import Bank Statement",
              subtitle: "Import CSV / XLS files",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bank statement imported")),
                );
              },
            ),
            SizedBox(height: 12.h),
            _ActionCard(
              icon: Icons.picture_as_pdf,
              title: "Export Reports",
              subtitle: "Export Invoices, Ledgers, Reports to PDF/Excel",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reports exported")),
                );
              },
            ),
            SizedBox(height: 12.h),
            _ActionCard(
              icon: Icons.wifi,
              title: "Sync Offline Data",
              subtitle: "Sync local data with server when online",
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Data synced")));
              },
            ),
            SizedBox(height: 12.h),
            _ActionCard(
              icon: Icons.email,
              title: "Send Payment Reminders",
              subtitle: "Email reminders for overdue invoices",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment reminders sent")),
                );
              },
            ),
            SizedBox(height: 12.h),
            _ActionCard(
              icon: Icons.dashboard,
              title: "View Dashboard KPIs",
              subtitle: "Daily sales, top expenses, outstanding receivables",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Icon(icon, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kpiData = [
      {"label": "Daily Sales", "value": "₹ 75,000"},
      {"label": "Outstanding Receivables", "value": "₹ 1,20,000"},
      {"label": "Top Expense", "value": "₹ 15,000 - Rent"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Business Dashboard")),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Key Performance Indicators",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 16.h),
            ...kpiData.map(
              (kpi) => Card(
                margin: EdgeInsets.only(bottom: 12.h),
                child: ListTile(
                  title: Text(kpi["label"]!),
                  trailing: Text(
                    kpi["value"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
