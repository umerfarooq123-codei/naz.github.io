import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledger_master/screens/dashboard_screen.dart';
import 'package:ledger_master/screens/journal_entry_screen.dart';
import 'package:ledger_master/screens/journal_list_screen.dart';

// GoRouter provider so we can access it via Riverpod in the app
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/journals',
        builder: (context, state) => const JournalListScreen(),
      ),
      GoRoute(
        path: '/journals/new',
        builder: (context, state) => const JournalEntryScreen(),
      ),
      // Future routes will be added here (invoices, customers, vendors, inventory etc.)
    ],
    debugLogDiagnostics: false,
  );
});
