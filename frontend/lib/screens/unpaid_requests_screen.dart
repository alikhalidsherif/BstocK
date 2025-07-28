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
      Provider.of<HistoryProvider>(context, listen: false).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unpaid Transactions'),
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final unpaidRequests = provider.history
              .where((h) => h.paymentStatus == 'unpaid')
              .toList();

          if (unpaidRequests.isEmpty) {
            return const Center(
              child: Text('No unpaid transactions.'),
            );
          }
          return ListView.builder(
            itemCount: unpaidRequests.length,
            itemBuilder: (context, index) {
              final history = unpaidRequests[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(history.product.name),
                  subtitle: Text('Buyer: ${history.buyerName ?? 'N/A'}'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Provider.of<ChangeRequestProvider>(context, listen: false).submitRequest(
                        action: ChangeRequestAction.markPaid,
                        barcode: history.product.barcode,
                      );
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