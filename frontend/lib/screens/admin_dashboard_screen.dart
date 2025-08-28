import 'package:bstock_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bstock_app/api/api_service.dart'; // To get the base URL


class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _exportToExcel(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    // It's important to use the correct base URL from your ApiService
    final url = Uri.parse('${ApiService().baseUrl}/products/export?token=$token');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  Future<void> _importFromExcel(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true, // Important for web platform
    );
    
    if (result != null && result.files.single.name.isNotEmpty) {
      final file = result.files.single;
      
      try {
        Map<String, dynamic> response;
        
        if (kIsWeb) {
          // For web platform, use bytes
          if (file.bytes == null) {
            throw Exception('File data not available');
          }
          response = await ApiService().importProductsFromExcel(
            fileBytes: file.bytes!,
            fileName: file.name,
          );
        } else {
          // For mobile platforms, use file path
          if (file.path == null) {
            throw Exception('File path not available');
          }
          response = await ApiService().importProductsFromExcel(
            filePath: file.path!,
          );
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Import completed: ${response['created']} created, ${response['updated']} updated'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Content only; AppBar provided by ShellScreen - match homescreen exactly
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              _buildAdminActionsGrid(context),
              const SizedBox(height: 24),
              Text(
                'Data Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _buildDataManagementGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminActionsGrid(BuildContext context) {
    final actions = [
      _buildActionCard(
        context,
        icon: Icons.pending_actions,
        label: 'Pending Requests',
        onTap: () => context.push('/admin/pending-requests'),
      ),
      _buildActionCard(
        context,
        icon: Icons.people,
        label: 'Manage Users',
        onTap: () => context.push('/manage-users'),
      ),
      _buildActionCard(
        context,
        icon: Icons.history,
        label: 'Change History',
        onTap: () => context.push('/admin/history'),
      ),
      _buildActionCard(
        context,
        icon: Icons.attach_money,
        label: 'Sales Tracking',
        onTap: () => context.push('/sales'),
      ),
      _buildActionCard(
        context,
        icon: Icons.archive,
        label: 'Archived Products',
        onTap: () => context.push('/admin/archived-products'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildDataManagementGrid(BuildContext context) {
    final actions = [
      _buildActionCard(
        context,
        icon: Icons.download_for_offline,
        label: 'Export to Excel',
        onTap: () => _exportToExcel(context),
      ),
      _buildActionCard(
        context,
        icon: Icons.upload_file,
        label: 'Import from Excel',
        onTap: () => _importFromExcel(context),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
} 