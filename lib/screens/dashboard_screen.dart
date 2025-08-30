import 'package:flutter/material.dart';
import 'package:ledger_master/core/responsive.dart';
import 'package:ledger_master/widgets/responsive_scaffold.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final Widget subtitle;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 26, child: Icon(icon)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  subtitle,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardGrid extends StatelessWidget {
  const DashboardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final device = Responsive.getDeviceType(MediaQuery.of(context));
    int crossAxisCount = 1;
    if (device == DeviceType.desktop)
      crossAxisCount = 3;
    else if (device == DeviceType.tablet)
      crossAxisCount = 2;

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: const [
        DashboardCard(
          title: 'Daily Sales',
          subtitle: Text('\$0.00'),
          icon: Icons.sell,
        ),
        DashboardCard(
          title: 'Outstanding Receivables',
          subtitle: Text('\$0.00'),
          icon: Icons.receipt_long,
        ),
        DashboardCard(
          title: 'Low Stock Alerts',
          subtitle: Text('0 items'),
          icon: Icons.inventory_2,
        ),
        DashboardCard(
          title: 'Expenses Today',
          subtitle: Text('\$0.00'),
          icon: Icons.money_off,
        ),
        DashboardCard(
          title: 'Bank Balance',
          subtitle: Text('\$0.00'),
          icon: Icons.account_balance,
        ),
        DashboardCard(
          title: 'Pending Payments',
          subtitle: Text('0'),
          icon: Icons.pending_actions,
        ),
      ],
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Dashboard',
      navigation: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(child: Text('LedgerMaster')),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            ),
            // Add menu entries (Invoices, Customers, Inventory...) in Step 2
          ],
        ),
      ),
      bottomNavigation: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Invoices'),
        ],
      ),
      body: const DashboardGrid(),
    );
  }
}
