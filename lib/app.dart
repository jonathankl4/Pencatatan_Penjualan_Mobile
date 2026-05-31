import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'providers/auth_provider.dart';

import 'models/sale.dart';
import 'models/expense.dart';

import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/product_form_screen.dart';
import 'screens/sales/sale_list_screen.dart';
import 'screens/sales/sale_form_screen.dart';
import 'screens/expenses/expense_list_screen.dart';
import 'screens/expenses/expense_form_screen.dart';
import 'screens/reports/report_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    final GoRouter router = GoRouter(
      initialLocation: authProvider.isAuthenticated ? '/dashboard' : '/login',
      redirect: (context, state) {
        final isLoggedIn = context.read<AuthProvider>().isAuthenticated;
        final isLoggingIn = state.uri.toString() == '/login';

        if (!isLoggedIn && !isLoggingIn) return '/login';
        if (isLoggedIn && isLoggingIn) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (context, state) => const ProductListScreen(),
          routes: [
            GoRoute(
              path: 'form',
              builder: (context, state) => const ProductFormScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/sales',
          builder: (context, state) {
            final searchQuery = state.uri.queryParameters['searchQuery'];
            final startDateStr = state.uri.queryParameters['startDate'];
            final endDateStr = state.uri.queryParameters['endDate'];
            
            DateTime? startDate;
            DateTime? endDate;
            if (startDateStr != null) {
              startDate = DateTime.tryParse(startDateStr);
            }
            if (endDateStr != null) {
              endDate = DateTime.tryParse(endDateStr);
            }
            
            return SaleListScreen(
              initialSearchQuery: searchQuery,
              initialStartDate: startDate,
              initialEndDate: endDate,
              hasInitialFilters: searchQuery != null || startDateStr != null || endDateStr != null,
            );
          },
          routes: [
            GoRoute(
              path: 'form',
              builder: (context, state) {
                final sale = state.extra as Sale?;
                return SaleFormScreen(sale: sale);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) {
            final startDateStr = state.uri.queryParameters['startDate'];
            final endDateStr = state.uri.queryParameters['endDate'];
            
            DateTime? startDate;
            DateTime? endDate;
            if (startDateStr != null) {
              startDate = DateTime.tryParse(startDateStr);
            }
            if (endDateStr != null) {
              endDate = DateTime.tryParse(endDateStr);
            }
            
            return ExpenseListScreen(
              initialStartDate: startDate,
              initialEndDate: endDate,
              hasInitialFilters: startDateStr != null || endDateStr != null,
            );
          },
          routes: [
            GoRoute(
              path: 'form',
              builder: (context, state) {
                final expense = state.extra as Expense?;
                return ExpenseFormScreen(expense: expense);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
