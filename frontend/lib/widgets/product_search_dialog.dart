import 'package:bstock_app/models/models.dart';
import 'package:bstock_app/providers/product_provider.dart';
import 'package:bstock_app/widgets/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<Product?> showProductSearchDialog(BuildContext context) {
  return showDialog<Product>(
    context: context,
    builder: (context) => const ProductSearchDialog(),
  );
}

class ProductSearchDialog extends StatefulWidget {
  const ProductSearchDialog({super.key});

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  @override
  void initState() {
    super.initState();
    // Clear any previous search when the dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).searchProducts('');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Product'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () async {
                    // Navigate to the scanner screen and wait for the result
                    final barcode = await context.push<String>('/scan');
                    if (barcode != null) {
                      // When a barcode is returned, search for it
                      Provider.of<ProductProvider>(context, listen: false).searchProducts(barcode);
                    }
                  },
                ),
              ),
              onChanged: (value) {
                Provider.of<ProductProvider>(context, listen: false).searchProducts(value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, provider, child) {
                  if (provider.products.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final product = provider.products[index];
                      return GenericListItem(
                        title: product.name,
                        subtitle: 'Barcode: ${product.barcode}',
                        onTap: () {
                          // Return the selected product
                          Navigator.of(context).pop(product);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
} 