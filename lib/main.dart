import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ledger_master/core/theme/app_theme.dart';
import 'package:ledger_master/features/bank_reconciliation/bank_transaction_list.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/inventory/inventory_repository.dart';
import 'package:ledger_master/features/inventory/item_list.dart';
import 'package:ledger_master/features/ledger/ledger_home.dart';
import 'package:ledger_master/features/ledger/ledger_repository.dart';
import 'package:ledger_master/features/purchases_expenses/purchase_list.dart';
import 'package:ledger_master/features/reports/report_screen.dart';
import 'package:ledger_master/features/sales_invoicing/invoice_list.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'features/automation/automation_screen.dart';
import 'features/payroll/employee_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? true;
  Get.put(LedgerController(LedgerRepository()));
  Get.put(CustomerController(CustomerRepository()));
  Get.put(LedgerTableController());
  Get.put(ItemController(InventoryRepository()));
  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NAZ ENTERPRISES',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // final KPIRepository _kpiRepo = KPIRepository();
  double totalSales = 0;
  double receivables = 0;
  double expenses = 0;
  double inventoryValue = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadKPIs();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadKPIs() async {
    // Mock data for demonstration
    final sales = 7500000.0; // Mock total sales in PKR
    final rec = 2300000.0; // Mock receivables in PKR
    final exp = 4500000.0; // Mock expenses in PKR
    final inv = 12000000.0; // Mock inventory value in PKR

    setState(() {
      totalSales = sales;
      receivables = rec;
      expenses = exp;
      inventoryValue = inv;
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.2),
                Theme.of(context).cardTheme.color!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.3),
                    child: Icon(icon, color: Theme.of(context).iconTheme.color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '₨${(value / 100000).toStringAsFixed(2)}L', // Display in lakhs
                style: Theme.of(
                  context,
                ).textTheme.displayLarge!.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesTrendChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trend (Last 6 Months)',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2000000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text(
                                'Apr',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            case 1:
                              return Text(
                                'May',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            case 2:
                              return Text(
                                'Jun',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            case 3:
                              return Text(
                                'Jul',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            case 4:
                              return Text(
                                'Aug',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                            case 5:
                              return Text(
                                'Sep',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          '₨${(value / 1000000).toInt()}M',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: 10000000,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 4000000),
                        FlSpot(1, 5000000),
                        FlSpot(2, 4500000),
                        FlSpot(3, 6000000),
                        FlSpot(4, 7000000),
                        FlSpot(5, 7500000),
                      ],
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdownChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Breakdown',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Center(
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 40,
                        color: const Color(0xFFFF6B6B), // Coral red
                        title: 'Rent (40%)',
                        radius: 60,
                        titleStyle: Theme.of(context).textTheme.labelSmall!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      PieChartSectionData(
                        value: 30,
                        color: const Color(0xFF4ADE80), // Green
                        title: 'Salaries (30%)',
                        radius: 60,
                        titleStyle: Theme.of(context).textTheme.labelSmall!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      PieChartSectionData(
                        value: 20,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary, // Primary color
                        title: 'Utilities (20%)',
                        radius: 60,
                        titleStyle: Theme.of(context).textTheme.labelSmall!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      PieChartSectionData(
                        value: 10,
                        color: const Color(0xFFFFD60A), // Yellow
                        title: 'Others (10%)',
                        radius: 60,
                        titleStyle: Theme.of(context).textTheme.labelSmall!
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return BaseLayout(
      appBarTitle: 'Business Dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: width > 1200
                  ? 4
                  : width > 800
                  ? 3
                  : 2,
              childAspectRatio: 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildSummaryCard(
                  title: 'Total Sales',
                  value: totalSales,
                  color: const Color(0xFF4ADE80), // Green
                  icon: Icons.receipt_long,
                ),
                _buildSummaryCard(
                  title: 'Receivables',
                  value: receivables,
                  color: Theme.of(context).colorScheme.primary, // Primary
                  icon: Icons.account_balance,
                ),
                _buildSummaryCard(
                  title: 'Expenses',
                  value: expenses,
                  color: const Color(0xFFFF6B6B), // Coral red
                  icon: Icons.shopping_cart,
                ),
                _buildSummaryCard(
                  title: 'Inventory Value',
                  value: inventoryValue,
                  color: const Color(0xFFFFD60A), // Yellow
                  icon: Icons.inventory,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSalesTrendChart(),
            const SizedBox(height: 24),
            _buildExpenseBreakdownChart(),
          ],
        ),
      ),
    );
  }
}

class BaseLayout extends StatefulWidget {
  const BaseLayout({super.key, required this.child, required this.appBarTitle});
  final Widget child;
  final String appBarTitle;

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  bool _isSidebarCollapsed = true;
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Widget buildNavigationTile({
    required String title,
    required IconData icon,
    required Widget screen,
    required bool showLabel,
  }) {
    return Tooltip(
      message: showLabel ? "" : title,
      child: InkWell(
        onTap: () => NavigationHelper.push(context, screen),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(width: 12),
                // Use Expanded with ellipsis to avoid overflow even in tight widths.
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  final List<Widget> appPages = [];
  final List<Map<String, dynamic>> navigationItems = [
    {
      'title': 'Ledger & Accounting',
      'icon': Icons.account_balance,
      'page': LedgerHome(),
    },
    {
      'title': 'Customer & Vendor',
      'icon': Icons.people,
      'page': CustomerList(),
    },
    {
      'title': 'Sales & Invoicing',
      'icon': Icons.receipt_long,
      'page': InvoiceList(),
    },
    {
      'title': 'Purchases & Expenses',
      'icon': Icons.shopping_cart,
      'page': PurchaseList(),
    },
    {'title': 'Inventory', 'icon': Icons.inventory, 'page': ItemList()},
    {'title': 'Reports', 'icon': Icons.bar_chart, 'page': ReportsScreen()},
    {
      'title': 'Bank Reconciliation',
      'icon': Icons.account_balance_wallet,
      'page': BankTransactionList(),
    },
    {'title': 'Payroll', 'icon': Icons.payments, 'page': EmployeeList()},
    {'title': 'Automation', 'icon': Icons.settings, 'page': AutomationScreen()},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    return Theme(
      data: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            widget.appBarTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: Row(
          children: [
            if (isDesktop)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarCollapsed ? 60 : 250,
                clipBehavior: Clip.hardEdge, // avoid paint overflow on edges
                color: Theme.of(context).colorScheme.primaryContainer,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Only show labels once we have enough width to avoid overflow during animation.
                    final canShowLabel = constraints.maxWidth >= 140;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Tooltip(
                          message: _isSidebarCollapsed
                              ? "Open menu"
                              : "Close menu",
                          child: InkWell(
                            onTap: () => setState(
                              () => _isSidebarCollapsed = !_isSidebarCollapsed,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    _isSidebarCollapsed
                                        ? Icons.menu
                                        : Icons.menu_open,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    size: 24,
                                  ),
                                  Flexible(
                                    child: ClipRect(
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        // prevent keeping the old (wider) child's size during transition
                                        layoutBuilder:
                                            (currentChild, previousChildren) =>
                                                currentChild ??
                                                const SizedBox.shrink(),
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                              opacity: animation,
                                              child: SizeTransition(
                                                sizeFactor: animation,
                                                axis: Axis.horizontal,
                                                child: child,
                                              ),
                                            ),
                                        child: canShowLabel
                                            ? Padding(
                                                key: const ValueKey(
                                                  'menu-label',
                                                ),
                                                padding: const EdgeInsets.only(
                                                  left: 12,
                                                ),
                                                child: Text(
                                                  "Menu",
                                                  maxLines: 1,
                                                  softWrap: false,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge!
                                                      .copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.8,
                                                            ),
                                                      ),
                                                ),
                                              )
                                            : const SizedBox(
                                                key: ValueKey('menu-empty'),
                                                width: 0,
                                                height: 0,
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ...List.generate(navigationItems.length, (
                                    index,
                                  ) {
                                    return buildNavigationTile(
                                      title: navigationItems[index]['title'],
                                      icon: navigationItems[index]['icon'],
                                      screen: navigationItems[index]['page'],
                                      showLabel: canShowLabel,
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Optionally add the dark mode switch here.
                      ],
                    );
                  },
                ),
              ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
