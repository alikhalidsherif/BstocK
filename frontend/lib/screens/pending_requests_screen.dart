import 'package:bstock_app/providers/change_request_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bstock_app/models/models.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChangeRequestProvider>(context, listen: false).fetchPendingRequests();
    });
  }

  final Map<int, bool> _isProcessing = {};

  Future<void> _handleRequest(Future<void> Function() action, int requestId) async {
    setState(() => _isProcessing[requestId] = true);
    await action();
    if (mounted) {
      setState(() => _isProcessing[requestId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Requests'),
      ),
      body: Consumer<ChangeRequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.requests.isEmpty) {
            return const Center(
              child: Text('No pending requests.'),
            );
          }
          return ListView.builder(
            itemCount: provider.requests.length,
            itemBuilder: (context, index) {
              final request = provider.requests[index];
              final actionText = request.action.name;
              final Color color;

              switch (request.action) {
                case ChangeRequestAction.add:
                  color = Colors.green;
                  break;
                case ChangeRequestAction.sell:
                  color = Colors.orange;
                  break;
                case ChangeRequestAction.create:
                  color = Colors.blue;
                  break;
                case ChangeRequestAction.update:
                  color = Colors.purple;
                  break;
                case ChangeRequestAction.delete:
                  color = Colors.red;
                  break;
                case ChangeRequestAction.markPaid:
                  color = Colors.teal;
                  break;
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      '${request.quantityChange ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('${actionText.toUpperCase()} - ${request.product?.name ?? request.newProductName ?? 'N/A'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Requester: ${request.requester.username}'),
                      if (request.product != null) Text('Barcode: ${request.product!.barcode}'),
                      if (request.newProductName != null) Text('New Name: ${request.newProductName}'),
                      if (request.newProductPrice != null) Text('New Price: \$${request.newProductPrice}'),
                      if (request.buyerName != null && request.buyerName!.isNotEmpty)
                        Text('Buyer: ${request.buyerName}'),
                      if (request.paymentStatus != null)
                        Text('Payment: ${request.paymentStatus}'),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing[request.id] ?? false)
                        const CircularProgressIndicator()
                      else ...[
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _handleRequest(() => provider.approveRequest(request.id), request.id),
                        tooltip: 'Approve',
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _handleRequest(() => provider.rejectRequest(request.id), request.id),
                        tooltip: 'Reject',
                      ),
                      ],
                    ],
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