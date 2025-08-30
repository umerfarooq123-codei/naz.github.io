import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:ledger_master/features/customers/presentation/customers_screen.dart';
import 'package:ledger_master/features/inventory/presentation/inventory_screen.dart';
import 'package:ledger_master/features/ledger/presentation/ledger_screen.dart';
import 'package:ledger_master/features/payroll/presentation/payroll_screen.dart';
import 'package:ledger_master/features/purchases/presentation/purchases_screen.dart';
import 'package:ledger_master/features/reports/presentation/reports_screen.dart';
import 'package:ledger_master/features/sales/presentation/sales_screen.dart';
import 'package:ledger_master/features/vendors/presentation/vendors_screen.dart';
import 'package:ledger_master/screens/dashboard_screen.dart';

import 'core/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/ledger',
          name: 'ledger',
          builder: (context, state) => const LedgerScreen(),
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          builder: (context, state) => const CustomersScreen(),
        ),
        GoRoute(
          path: '/vendors',
          name: 'vendors',
          builder: (context, state) => const VendorsScreen(),
        ),
        GoRoute(
          path: '/sales',
          name: 'sales',
          builder: (context, state) => const SalesScreen(),
        ),
        GoRoute(
          path: '/purchases',
          name: 'purchases',
          builder: (context, state) => const PurchasesScreen(),
        ),
        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/payroll',
          name: 'payroll',
          builder: (context, state) => const PayrollScreen(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(1440, 1024), // Desktop-first scaling
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'BizTrack',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: router,
        );
      },
    );
  }
}
