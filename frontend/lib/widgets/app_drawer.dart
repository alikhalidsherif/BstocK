import 'package:bstock_app/providers/auth_provider.dart';
import 'package:bstock_app/widgets/ashreef_footer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Brand Theme Colors
    final Color headerColor =
        isDark ? const Color(0xFF0F1426) : const Color(0xFF322B8C);
    final Color headerTextColor = Colors.white;

    return Drawer(
      child: Column(
        children: [
          // ─────────────────────────────────────────────────────────
          // HEADER: User Profile Section
          // ─────────────────────────────────────────────────────────
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: headerColor,
            ),
            margin: EdgeInsets.zero,
            currentAccountPicture: CircleAvatar(
              backgroundColor: isDark
                  ? const Color(0xFF63D3FF).withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              child: Text(
                _getInitials(user?.username ?? 'U'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: headerTextColor,
                ),
                      ),
                    ),
            accountName: Text(
              user?.username ?? 'User',
                      style: TextStyle(
                color: headerTextColor,
                fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            accountEmail: Text(
              _getRoleDisplay(user?.role),
              style: TextStyle(
                color: headerTextColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────
          // BODY: Navigation Items
          // ─────────────────────────────────────────────────────────
                Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/settings');
                  },
                ),
                const Divider(height: 24),
                ListTile(
                  leading: Icon(
                    Icons.logout_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Logout',
                          style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                  onTap: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
            ),
          ),

          // ─────────────────────────────────────────────────────────
          // FOOTER: AshReef Labs Branding (Full Product Style)
          // ─────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
          ),
            child: SafeArea(
              top: false,
              child: const AshReefFooter(style: FooterStyle.fullProduct),
            ),
          ),
        ],
      ),
    );
  }

  /// Get initials from username (e.g., "John Doe" -> "JD", "admin" -> "A")
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Get display text for user role
  String _getRoleDisplay(dynamic role) {
    if (role == null) return 'User';
    final roleStr = role.toString().toLowerCase();
    if (roleStr.contains('admin')) return 'Administrator';
    if (roleStr.contains('manager')) return 'Manager';
    return 'Staff Member';
  }
}
