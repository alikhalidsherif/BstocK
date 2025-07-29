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

  Widget _getLeadingWidget(ChangeRequest request) {
    switch (request.action) {
      case ChangeRequestAction.add:
        return const Icon(Icons.add, color: Colors.white);
      case ChangeRequestAction.sell:
        return const Icon(Icons.remove, color: Colors.white);
      case ChangeRequestAction.create:
        return const Icon(Icons.add_circle_outline, color: Colors.white);
      case ChangeRequestAction.update:
        return const Icon(Icons.edit, color: Colors.white);
      case ChangeRequestAction.delete:
        return const Icon(Icons.delete_forever, color: Colors.white);
      case ChangeRequestAction.mark_paid:
        return const Icon(Icons.attach_money, color: Colors.white);
      default:
        return const Icon(Icons.help_outline, color: Colors.white);
    }
  }

  List<Widget> _getSubtitleWidgets(ChangeRequest request) {
    final List<Widget> widgets = [];
    
    switch (request.action) {
      case ChangeRequestAction.create:
        // For create, show the new product details without "New" prefix
        if (request.newProductBarcode != null) {
          widgets.add(Text('Barcode: ${request.newProductBarcode}'));
        }
        if (request.newProductPrice != null) {
          widgets.add(Text('Price: \$${request.newProductPrice!.toStringAsFixed(2)}'));
        }
        if (request.newProductQuantity != null) {
          widgets.add(Text('Quantity: ${request.newProductQuantity}'));
        }
        if (request.newProductCategory != null) {
          widgets.add(Text('Category: ${request.newProductCategory}'));
        }
        break;
        
      case ChangeRequestAction.add:
      case ChangeRequestAction.sell:
        if (request.product != null) {
          widgets.add(Text('Barcode: ${request.product!.barcode}'));
        }
        if (request.quantityChange != null) {
          widgets.add(Text('Quantity: ${request.quantityChange}'));
        }
        if (request.buyerName != null && request.buyerName!.isNotEmpty) {
          widgets.add(Text('Buyer: ${request.buyerName}'));
        }
        if (request.paymentStatus != null) {
          widgets.add(Text('Payment: ${request.paymentStatus}'));
        }
        break;
        
      case ChangeRequestAction.update:
        // For update, show "Old -> New" format for changed fields
        if (request.product != null) {
          widgets.add(Text('Barcode: ${request.product!.barcode}'));
        }
        if (request.newProductName != null) {
          final oldName = request.product?.name ?? 'Unknown';
          widgets.add(Text('Name: $oldName → ${request.newProductName}'));
        }
        if (request.newProductPrice != null) {
          final oldPrice = request.product?.price?.toStringAsFixed(2) ?? 'Unknown';
          widgets.add(Text('Price: \$$oldPrice → \$${request.newProductPrice!.toStringAsFixed(2)}'));
        }
        break;
        
      case ChangeRequestAction.delete:
        if (request.product != null) {
          widgets.add(Text('Barcode: ${request.product!.barcode}'));
          widgets.add(Text('This product will be deleted'));
        }
        break;
        
      case ChangeRequestAction.mark_paid:
        if (request.product != null) {
          widgets.add(Text('Barcode: ${request.product!.barcode}'));
        }
        widgets.add(const Text('Mark as paid'));
        break;
    }
    
    return widgets;
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
                case ChangeRequestAction.mark_paid:
                  color = Colors.teal;
                  break;
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: _getLeadingWidget(request),
                  ),
                  title: Text('${actionText.toUpperCase()} - ${request.product?.name ?? request.newProductName ?? 'Unknown'}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Requester: ${request.requester.username}'),
                      ..._getSubtitleWidgets(request),
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