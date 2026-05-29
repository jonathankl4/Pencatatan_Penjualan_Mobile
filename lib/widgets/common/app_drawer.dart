import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text(AppStrings.dashboard),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.inventory),
          //   title: const Text(AppStrings.products),
          //   onTap: () {
          //     Navigator.pop(context);
          //     context.go('/products');
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text(AppStrings.sales),
            onTap: () {
              Navigator.pop(context);
              context.go('/sales');
            },
          ),
          ListTile(
            leading: const Icon(Icons.money_off),
            title: const Text(AppStrings.expenses),
            onTap: () {
              Navigator.pop(context);
              context.go('/expenses');
            },
          ),
        ],
      ),
    );
  }
}
