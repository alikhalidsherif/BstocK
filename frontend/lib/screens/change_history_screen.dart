import 'package:bstock_app/providers/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bstock_app/models/models.dart';

class ChangeHistoryScreen extends StatefulWidget {
  const ChangeHistoryScreen({super.key});

  @override
  State<ChangeHistoryScreen> createState() => _ChangeHistoryScreenState();
}

class _ChangeHistoryScreenState extends State<ChangeHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch history when the screen is initialized.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<HistoryProvider>(context, listen: false).fetchHistory(),
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isHistoryLoading && provider.history.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.historyError != null) {
            return Center(child: Text('Error: ${provider.historyError}'));
          }
          
          if (provider.history.isEmpty) {
            return const Center(
              child: Text('No history found.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchHistory(),
            child: ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                final entry = provider.history[index];
                final actionText = entry.action.name.toUpperCase();
                final statusText = entry.status.name.toUpperCase();
                final productName = entry.product?.name ?? 'Product Not Found';
                final reviewerName = entry.reviewer?.username ?? 'N/A';

                final Color color;
                final IconData icon;

                switch (entry.action) {
                  case ChangeRequestAction.add:
                    color = Colors.green;
                    icon = Icons.add;
                    break;
                  case ChangeRequestAction.sell:
                    color = Colors.orange;
                    icon = Icons.remove;
                    break;
                  case ChangeRequestAction.create:
                    color = Colors.blue;
                    icon = Icons.add_circle_outline;
                    break;
                  case ChangeRequestAction.delete:
                    color = Colors.red;
                    icon = Icons.delete_forever;
                    break;
                  case ChangeRequestAction.mark_paid:
                    color = Colors.teal;
                    icon = Icons.attach_money;
                    break;
                  case ChangeRequestAction.update:
                     color = Colors.purple;
                     icon = Icons.edit;
                     break;
                  default:
                    color = Colors.grey;
                    icon = Icons.help_outline;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Icon(icon, color: Colors.white),
                    ),
                    title: Text('$actionText - $productName'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qty: ${entry.quantityChange ?? 'N/A'}'),
                        if (entry.buyerName != null && entry.buyerName!.isNotEmpty)
                          Text('Buyer: ${entry.buyerName}'),
                        if (entry.paymentStatus != null)
                          Text('Payment: ${entry.paymentStatus}'),
                        Text('By: ${entry.requester.username}'),
                        Text('Reviewed by: $reviewerName'),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                        Text(DateFormat.yMd().add_jm().format(entry.timestamp.toLocal())),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}