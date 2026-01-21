import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/service_bindings.dart';
import 'package:ledger_master/core/theme/app_theme.dart';
import 'package:ledger_master/core/utils/data_grid_extension.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/inventory/item_list.dart';
import 'package:ledger_master/features/ledger/ledger_home.dart';
import 'package:ledger_master/features/purchases_expenses/purchase_and_expense_list_and_form.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'features/automation/automation_screen.dart';
import 'features/cans/cans_list.dart';

class ThemeController extends GetxController {
  RxBool isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadTheme();
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    saveTheme();
  }

  void saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode.value);
  }
}

void main() async {
  // Setup error handling before anything else
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      // In release mode, capture to Sentry
      Sentry.captureException(details.exception, stackTrace: details.stack);
    } else {
      // In debug mode, use default error handler
      FlutterError.presentError(details);
    }
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kReleaseMode) {
      Sentry.captureException(error, stackTrace: stack);
    }
    return true;
  };

  // Handle zone errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ExportRegistryInitializer.initializeCommonExtractors();
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      // Initialize all repositories and controllers via service bindings
      Get.put(ServiceBindings(), permanent: true);

      if (kReleaseMode) {
        await SentryFlutter.init((options) {
          options.dsn =
              'https://54b910cba2553a70302a8ebf758a2d60@o4510749281157120.ingest.us.sentry.io/4510749284302848';
          options.sendDefaultPii = true;
          options.tracesSampleRate = 0.1;
          // Capture breadcrumbs for better context
          options.maxBreadcrumbs = 200;
          // Enable environment metadata
          options.environment = kReleaseMode ? 'production' : 'development';
          // Attach stack traces
          options.attachStacktrace = true;
        }, appRunner: () => runApp(const MyApp()));
      } else {
        runApp(const MyApp());
      }
    },
    (error, stack) {
      if (kReleaseMode) {
        Sentry.captureException(error, stackTrace: stack);
      } else {
        debugPrintStack(stackTrace: stack, label: 'Uncaught Error: $error');
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NAZ ENTERPRISES',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      initialBinding: ServiceBindings(),
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final NumberFormat formatter = NumberFormat('#,##0.##');

  @override
  void initState() {
    super.initState();
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

  final LedgerController ledgerController = Get.find<LedgerController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final AutomationController automationController =
      Get.find<AutomationController>();

  // Updated to match screenshot: full gradient background, icon above title, large value
  Widget buildSummaryCard({
    required String title,
    required dynamic value,
    required Color color,
    required IconData icon,
    bool isClickable = false,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 100, // Fixed height for consistency
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15), // Softer start
              color.withValues(alpha: 0.05), // Fade to near-transparent
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon at top
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.25),
              child: Icon(icon, color: color, size: 24),
            ),
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: TextSizes.body, // Retain size
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Value(s) - large and bold
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (value is List<Item>)
                    ...List.generate(value.length, (index) {
                      final formattedStock = formatter.format(
                        value[index].availableStock,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          "${value[index].name}: $formattedStock",
                          style: Theme.of(context).textTheme.displaySmall!
                              .copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize:
                                    TextSizes.heading, // Retain large size
                              ),
                        ),
                      );
                    })
                  else ...[
                    Text(
                      formatter.format(value is RxDouble ? value.value : value),
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: TextSizes.heading, // Retain size
                      ),
                    ),
                    if (title ==
                        'Inventory Value') // Custom for screenshot example
                    ...[
                      const SizedBox(height: 4),
                      Text(
                        'WER: 9,000',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: color.withValues(alpha: 0.8),
                          fontSize: TextSizes.caption,
                        ),
                      ),
                      Text(
                        'HYPO: 15,040',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: color.withValues(alpha: 0.8),
                          fontSize: TextSizes.caption,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSalesTrendChart(List<Map<String, dynamic>> salesData) {
    final ledgerController = Get.find<LedgerController>();
    if (salesData.isEmpty) {
      return const Center(child: Text('No sales data available.'));
    }
    // Convert the SQL "YYYY-MM" to formatted labels & numeric data
    final spots = <FlSpot>[];
    final monthLabels = <String>[];
    for (var i = 0; i < salesData.length; i++) {
      final entry = salesData[i];
      final monthStr = entry['month']?.toString() ?? '';
      final total = (entry['total_sales'] as num?)?.toDouble() ?? 0.0;
      DateTime? date;
      try {
        date = DateTime.parse('$monthStr-01'); // e.g. "2025-11-01"
      } catch (_) {}
      // ✅ Show only short month name
      final label = date != null
          ? ledgerController.monthShortNames[date.month - 1]
          : monthStr;
      monthLabels.add(label);
      spots.add(FlSpot(i.toDouble(), total));
    }
    // Calculate maxY with fallback to prevent zero interval
    double maxYValue = 0.0;
    if (spots.isNotEmpty) {
      maxYValue = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    }
    final maxY = maxYValue > 0 ? maxYValue * 1.2 : 1.0;
    final interval = maxY / 5;
    return Card(
      elevation: 4, // Subtle for light theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20), // More padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Trend',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: TextSizes.subheading, // Retain
              ),
            ),
            const SizedBox(height: 20),
            // Dark chart background for contrast (matching screenshot)
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937), // Dark neutral for chart bg
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LineChart(
                  LineChartData(
                    backgroundColor: Colors.transparent, // Use container bg
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < monthLabels.length) {
                              // ✅ Prevent overlap by only showing every 2nd label if needed
                              if (monthLabels.length > 6 && index % 2 != 0) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  monthLabels[index],
                                  style: Theme.of(context).textTheme.labelSmall!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: TextSizes.caption, // Retain
                                      ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            String formatted;
                            if (value >= 1000000) {
                              formatted =
                                  '${(value / 1000000).toStringAsFixed(1)}M';
                            } else if (value >= 1000) {
                              formatted =
                                  '${(value / 1000).toStringAsFixed(0)}K';
                            } else {
                              formatted = value.toInt().toString();
                            }
                            return Text(
                              formatted,
                              style: Theme.of(context).textTheme.labelSmall!
                                  .copyWith(
                                    color: Colors.white70,
                                    fontSize: TextSizes.caption, // Retain
                                  ),
                            );
                          },
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
                    maxX: (spots.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF3B82F6), // Vibrant blue for line
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExpenseBreakdownChart(List<Map<String, dynamic>> expenseData) {
    final totalAmount = expenseData.fold<double>(
      0.0,
      (sum, e) => sum + (e['total'] as num).toDouble(),
    );

    final colors = [
      const Color(0xFFEF4444), // Red for general
      const Color(0xFF10B981), // Green for maintenance
      const Color(0xFF3B82F6), // Blue for salaries
      const Color(0xFFEAB308), // Yellow for travel
      const Color(0xFF8B5CF6), // Purple for others
      const Color(0xFFEC4899), // Pink for extras
    ];

    final sections = expenseData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final total = (data['total'] as num).toDouble();
      final percentage = totalAmount > 0 ? (total / totalAmount) * 100 : 0.0;

      return PieChartSectionData(
        value: total,
        color: colors[index % colors.length],
        title: "${percentage.toStringAsFixed(1)}%",
        radius: 70, // Slightly larger
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Breakdown',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: TextSizes.subheading, // Retain
              ),
            ),
            const SizedBox(height: 20),
            // Dark chart background for contrast
            Container(
              height: 200,
              decoration: BoxDecoration(
                // color: const Color(0xFF1F2937), // Dark neutral
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 3, // More space between sections
                      centerSpaceRadius: 45,
                      pieTouchData: PieTouchData(
                        enabled: false,
                      ), // Disable interaction for aesthetics
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend - Improved spacing and style
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: expenseData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final category = data['category'] ?? 'Unknown';
                final color = colors[index % colors.length];
                final total = (data['total'] as num).toDouble();
                final percentage = totalAmount > 0
                    ? (total / totalAmount) * 100
                    : 0.0;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6), // Rounded dots
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$category (${percentage.toStringAsFixed(1)}%)",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: TextSizes.caption, // Retain
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    Future.delayed(Duration(seconds: 1), () async {
      await ledgerController.getStats();
    });
    return BaseLayout(
      showBackButton: false,
      onBackButtonPressed: null,
      appBarTitle: 'Business Dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20), // More padding for modern spacing
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Metrics',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: TextSizes.heading, // Retain
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: width > 1200
                  ? 4
                  : width > 800
                  ? 3
                  : 2,
              childAspectRatio: 1.4, // Adjusted for taller cards
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20, // More space
              crossAxisSpacing: 20,
              children: [
                Obx(
                  () => buildSummaryCard(
                    title: 'Total Sales',
                    value: ledgerController.totalSales,
                    color: const Color(
                      0xFF10B981,
                    ), // Green, matching screenshot
                    icon: Icons.receipt_long,
                  ),
                ),
                Obx(
                  () => buildSummaryCard(
                    title: 'Receivables',
                    value: ledgerController.totalReceivables,
                    color: const Color(0xFF3B82F6), // Blue
                    icon: Icons.account_balance,
                  ),
                ),
                Obx(
                  () => buildSummaryCard(
                    title: '${automationController.selectedPeriod} Expenses',
                    value:
                        ledgerController
                            .expenses['${automationController.selectedPeriod}'] ??
                        0.0,
                    color: const Color(0xFFEF4444), // Red-ish
                    icon: Icons.shopping_cart,
                  ),
                ),
                Obx(
                  () => buildSummaryCard(
                    title: 'Inventory Value',
                    value: ledgerController.lowStockItems,
                    color: const Color(0xFFEAB308), // Yellow
                    icon: Icons.inventory_2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32), // More vertical space
            Obx(
              () => ledgerController.salesTrendLast6Months.isEmpty
                  ? SizedBox.shrink()
                  : buildSalesTrendChart(
                      ledgerController.salesTrendLast6Months,
                    ),
            ),
            const SizedBox(height: 32),
            Obx(
              () => ledgerController.expenseBreakdown.isEmpty
                  ? SizedBox.shrink()
                  : buildExpenseBreakdownChart(
                      ledgerController.expenseBreakdown,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class BaseLayout extends StatefulWidget {
  const BaseLayout({
    super.key,
    required this.child,
    required this.appBarTitle,
    required this.showBackButton,
    required this.onBackButtonPressed,
  });
  final Widget child;
  final String appBarTitle;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  bool _isSidebarCollapsed = true;
  final ThemeController themeController = Get.find<ThemeController>();

  Widget buildNavigationTile({
    required String title,
    required IconData icon,
    required Widget screen,
    required bool showLabel,
  }) {
    return Tooltip(
      message: showLabel ? "" : title,
      child: InkWell(
        onTap: () {
          if (title != 'Sales & Invoicing' &&
              title != 'Bank Reconciliation' &&
              title != 'Payroll') {
            NavigationHelper.push(context, screen);
          }
        },
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
    {'title': 'Dasboard', 'icon': Icons.dashboard, 'page': DashboardScreen()},
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
    // {
    //   'title': 'Sales & Invoicing',
    //   'icon': Icons.receipt_long,
    //   'page': InvoiceList(),
    // },
    {'title': 'Inventory', 'icon': Icons.warehouse, 'page': ItemList()},
    {
      'title': 'Purchases & Expenses',
      'icon': Icons.shopping_cart,
      'page': ExpensePurchaseScreen(),
    },
    {
      'title': 'Cans Management',
      'icon': Icons.inventory_2,
      'page': const CansList(),
    },
    // {
    //   'title': 'Bank Reconciliation',
    //   'icon': Icons.account_balance_wallet,
    //   'page': BankTransactionList(),
    // },
    // {'title': 'Payroll', 'icon': Icons.payments, 'page': EmployeeList()},
    {'title': 'Automation', 'icon': Icons.settings, 'page': AutomationScreen()},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 800;

    // Removed forced darkTheme wrapper to enable light theme (assuming parent MaterialApp uses lightTheme)
    return SelectionArea(
      child: Scaffold(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // Uses light surface
        appBar: AppBar(
          automaticallyImplyLeading:
              false, // Important: we provide our own back button
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBackButtonPressed,
                )
              : null,
          title: Text(
            widget.appBarTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          // actions: [ThemeToggleButton(showText: false)],
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primaryContainer, // Light blue tint
        ),
        body: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.horizontal,
                  child: child,
                ),
              ),
              child: (!widget.showBackButton && isDesktop)
                  ? AnimatedContainer(
                      key: const ValueKey('sidebar'),
                      duration: const Duration(milliseconds: 300),
                      width: _isSidebarCollapsed ? 60 : 250,
                      clipBehavior: Clip.hardEdge,
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer, // Light for sidebar
                      child: LayoutBuilder(
                        builder: (context, constraints) {
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
                                  onTap: () => setState(() {
                                    _isSidebarCollapsed = !_isSidebarCollapsed;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                              layoutBuilder:
                                                  (
                                                    currentChild,
                                                    previousChildren,
                                                  ) =>
                                                      currentChild ??
                                                      const SizedBox.shrink(),
                                              transitionBuilder:
                                                  (child, animation) =>
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
                                                      padding:
                                                          const EdgeInsets.only(
                                                            left: 12,
                                                          ),
                                                      child: Text(
                                                        "Menu",
                                                        maxLines: 1,
                                                        softWrap: false,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleLarge!
                                                            .copyWith(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .onSurface
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                            ),
                                                      ),
                                                    )
                                                  : const SizedBox(
                                                      key: ValueKey(
                                                        'menu-empty',
                                                      ),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ...List.generate(
                                          navigationItems.length,
                                          (index) => buildNavigationTile(
                                            title:
                                                navigationItems[index]['title'],
                                            icon:
                                                navigationItems[index]['icon'],
                                            screen:
                                                navigationItems[index]['page'],
                                            showLabel: canShowLabel,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('empty'),
                    ), // empty when hidden
            ),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}



// appScript url: https://script.google.com/macros/s/AKfycbyg81lgShbmwWhOKUmnJYMW6qMRPufzrx5YdWj-5loT8ytY1SF2bnp7qlSc57ejqnhi/exec