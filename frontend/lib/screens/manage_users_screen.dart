import 'package:bstock_app/widgets/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/models.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-user'),
        tooltip: 'Add User',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                Provider.of<UserProvider>(context, listen: false).searchUsers(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userProvider.users.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: userProvider.users.length,
                  itemBuilder: (context, index) {
                    final user = userProvider.users[index];
                    return GenericListItem(
                      title: user.username,
                      subtitle: 'Role: ${user.role.toString().split('.').last}',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRolePopupMenu(context, user),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text('Are you sure you want to delete ${user.username}?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          Provider.of<UserProvider>(context, listen: false).deleteUser(user.id);
                                        },
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePopupMenu(BuildContext context, User user) {
    return PopupMenuButton<UserRole>(
      onSelected: (UserRole role) {
        Provider.of<UserProvider>(context, listen: false).updateUserRole(user.id, role);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<UserRole>>[
        const PopupMenuItem<UserRole>(
          value: UserRole.clerk,
          child: Text('Set as Clerk'),
        ),
        const PopupMenuItem<UserRole>(
          value: UserRole.supervisor,
          child: Text('Set as Supervisor'),
        ),
        const PopupMenuItem<UserRole>(
          value: UserRole.admin,
          child: Text('Set as Admin'),
        ),
      ],
      icon: const Icon(Icons.edit),
    );
  }
} 