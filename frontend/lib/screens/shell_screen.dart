import 'package:bstock_app/providers/auth_provider.dart';
import 'package:bstock_app/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bstock_app/models/models.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = Provider.of<AuthProvider>(context).user?.role == UserRole.admin;
    final String title = _getTitleForLocation(GoRouterState.of(context).matchedLocation);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: const AppDrawer(),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_customize),
              label: 'Admin',
            ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) => _onItemTapped(index, context, isAdmin),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/products')) {
      return 1;
    }
    if (location.startsWith('/admin')) {
      return 2;
    }
    return 0; // Home
  }

  void _onItemTapped(int index, BuildContext context, bool isAdmin) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        if (isAdmin) context.go('/admin');
        break;
    }
  }

  String _getTitleForLocation(String location) {
    if (location.startsWith('/products')) {
      return 'Products';
    }
    if (location.startsWith('/admin')) {
      return 'Admin Dashboard';
    }
    return 'Home';
  }
} 