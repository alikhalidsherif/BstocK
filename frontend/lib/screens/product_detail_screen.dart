import 'package:bstock_app/models/models.dart';
import 'package:bstock_app/providers/change_request_provider.dart';
import 'package:flutter/material.dart';
import 'package:bstock_app/providers/product_provider.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode: ${product.barcode}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Quantity: ${product.quantity}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Price: \$${product.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Category: ${product.category}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showStockChangeDialog(context, product: product, action: ChangeRequestAction.add),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Stock'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showStockChangeDialog(context, product: product, action: ChangeRequestAction.sell),
                  icon: const Icon(Icons.remove),
                  label: const Text('Sell Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showStockChangeDialog(BuildContext context, {required Product product, required ChangeRequestAction action}) {
    // Prevent selling when no stock is available
    if (action == ChangeRequestAction.sell && product.quantity == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stock available to sell'), backgroundColor: Colors.red),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        // We can reuse the dialog from the HomeScreen, but we need to pass the product.
        // For simplicity, I'll call a modified version of the dialog.
        // In a real app, you would factor this dialog out into its own widget.
        return StockChangeDialog(product: product, action: action);
      },
    );
  }
}

/// A loader that fetches the product by barcode when no product was passed.
class ProductDetailLoader extends StatefulWidget {
  final String barcode;
  const ProductDetailLoader({super.key, required this.barcode});

  @override
  _ProductDetailLoaderState createState() => _ProductDetailLoaderState();
}

class _ProductDetailLoaderState extends State<ProductDetailLoader> {
  Product? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      final fetched = await provider.fetchProductByBarcode(widget.barcode);
      setState(() {
        _product = fetched;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _product == null) {
      return Scaffold(
        body: Center(child: Text(_error ?? 'Product not found.')),
      );
    }
    return ProductDetailScreen(product: _product!);
  }
}

// A reusable dialog for add/sell stock requests
class StockChangeDialog extends StatefulWidget {
  final Product product;
  final ChangeRequestAction action;

  const StockChangeDialog({super.key, required this.product, required this.action});

  @override
  _StockChangeDialogState createState() => _StockChangeDialogState();
}

class _StockChangeDialogState extends State<StockChangeDialog> {
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _buyerController = TextEditingController();
  bool _isLoading = false;
  bool _isPaid = false; // Payment status for sell requests

  @override
  void dispose() {
    _quantityController.dispose();
    _buyerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final int? qty = int.tryParse(_quantityController.text);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid quantity'))
      );
      return;
    }
    // Prevent selling more than available stock
    if (widget.action == ChangeRequestAction.sell && qty > widget.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot sell more than available stock'), backgroundColor: Colors.red)
      );
      return;
    }
    final String? buyerName = widget.action == ChangeRequestAction.sell
        ? _buyerController.text
        : null;
    setState(() => _isLoading = true);
    try {
      final bool success = await Provider.of<ChangeRequestProvider>(context, listen: false).submitRequest(
        action: widget.action,
        barcode: widget.product.barcode,
        quantity: qty,
        buyerName: buyerName,
        paymentStatus: widget.action == ChangeRequestAction.sell ? (_isPaid ? 'paid' : 'unpaid') : null,
      );
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.action.name.toUpperCase()} request submitted'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request'))
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.action == ChangeRequestAction.sell
          ? 'Sell ${widget.product.name}'
          : 'Add Stock to ${widget.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          if (widget.action == ChangeRequestAction.sell) ...[
            TextField(
              controller: _buyerController,
              decoration: const InputDecoration(labelText: 'Buyer Name (Optional)'),
            ),
            CheckboxListTile(
              title: const Text('Paid'),
              value: _isPaid,
              onChanged: (v) { if (v != null) setState(() => _isPaid = v); },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Submit'),
        ),
      ],
    );
  }
} 