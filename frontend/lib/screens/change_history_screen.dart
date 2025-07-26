import 'package:bstock_app/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ChangeHistoryScreen extends StatelessWidget {
  const ChangeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change History'),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.history.isEmpty) {
            return const Center(
              child: Text('No history found.'),
            );
          }
          return ListView.builder(
            itemCount: provider.history.length,
            itemBuilder: (context, index) {
              final entry = provider.history[index];
              final actionText = entry.action.name.toUpperCase();
              final statusText = entry.status.name.toUpperCase();
              final color = entry.status.name == 'approved'
                  ? (entry.action.name == 'add' ? Colors.green : Colors.blue)
                  : Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      entry.action.name == 'add' ? Icons.add : Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                  title: Text('$actionText ${entry.quantityChange} x ${entry.product.name}'),
                  subtitle: Text(
                      'By: ${entry.requester.username}\nReviewed by: ${entry.reviewer.username}\nDate: ${DateFormat.yMd().add_jm().format(entry.timestamp.toLocal())}'),
                  trailing: Text(
                    statusText,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 