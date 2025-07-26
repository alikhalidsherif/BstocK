import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Wrap(
            spacing: 16.0,
            runSpacing: 16.0,
            alignment: WrapAlignment.center,
            children: [
              _buildAdminTile(
                context,
                icon: Icons.pending_actions,
                label: 'Pending Requests',
                onTap: () => context.push('/admin/pending-requests'),
              ),
              _buildAdminTile(
                context,
                icon: Icons.manage_accounts,
                label: 'Manage Users',
                onTap: () => context.push('/manage-users'),
              ),
              _buildAdminTile(
                context,
                icon: Icons.history,
                label: 'Change History',
                onTap: () => context.push('/admin/history'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return SizedBox(
      width: 160,
      height: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 48.0, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 