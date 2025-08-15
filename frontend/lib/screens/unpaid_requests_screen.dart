import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bstock_app/models/models.dart';
import 'package:bstock_app/providers/change_request_provider.dart';
import 'package:bstock_app/providers/history_provider.dart';

class UnpaidRequestsScreen extends StatefulWidget {
  const UnpaidRequestsScreen({super.key});

  @override
  State<UnpaidRequestsScreen> createState() => _UnpaidRequestsScreenState();
}

class _UnpaidRequestsScreenState extends State<UnpaidRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).fetchUnpaidSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<HistoryProvider>(context, listen: false).fetchUnpaidSales(),
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isUnpaidLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.unpaidError != null) {
            return Center(child: Text('Error: ${provider.unpaidError}'));
          }

          final unpaidRequests = provider.unpaidSales;

          if (unpaidRequests.isEmpty) {
            return const Center(
              child: Text('No unpaid transactions.'),
            );
          }
          return ListView.builder(
            itemCount: unpaidRequests.length,
            itemBuilder: (context, index) {
              final history = unpaidRequests[index];
              if (history.product == null) {
                // This entry is invalid, so we skip it.
                return const SizedBox.shrink();
              }
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(history.product!.name),
                  subtitle: Text('Buyer: ${history.buyerName ?? 'N/A'}'),
                  trailing: ElevatedButton(
                    onPressed: provider.isUnpaidLoading ? null : () async {
                      try {
                        await Provider.of<ChangeRequestProvider>(context, listen: false).submitRequest(
                          action: ChangeRequestAction.mark_paid,
                          barcode: history.id.toString(), // Pass history ID as barcode
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request to mark as paid submitted!')),
                          );
                          // Refresh the list
                          Provider.of<HistoryProvider>(context, listen: false).fetchUnpaidSales();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to submit request: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Request Paid'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 