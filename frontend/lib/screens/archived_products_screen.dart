import 'package:bstock_app/widgets/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../providers/change_request_provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';

class ArchivedProductsScreen extends StatefulWidget {
  const ArchivedProductsScreen({super.key});

  @override
  State<ArchivedProductsScreen> createState() => _ArchivedProductsScreenState();
}

class _ArchivedProductsScreenState extends State<ArchivedProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts(includeArchived: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final archivedProducts = productProvider.products.where((p) => p.isArchived).toList();

          if (archivedProducts.isEmpty) {
            return const Center(child: Text('No archived products found.'));
          }

          return ListView.builder(
            itemCount: archivedProducts.length,
            itemBuilder: (context, index) {
              final product = archivedProducts[index];
              return GenericListItem(
                title: product.name,
                subtitle: 'Barcode: ${product.barcode} | Category: ${product.category}',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Unarchive',
                      icon: const Icon(Icons.unarchive, color: Colors.green),
                      onPressed: () async {
                        final isAdmin = Provider.of<AuthProvider>(context, listen: false).user?.role == UserRole.admin;
                        if (isAdmin) {
                          await Provider.of<ChangeRequestProvider>(context, listen: false).submitAutoRequest(
                            action: ChangeRequestAction.restore,
                            barcode: product.id.toString(),
                          );
                        } else {
                          await Provider.of<ChangeRequestProvider>(context, listen: false).submitRequest(
                            action: ChangeRequestAction.restore,
                            barcode: product.id.toString(),
                          );
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore request submitted')));
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete permanently',
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete permanently?'),
                            content: const Text('This will permanently remove the product. History will remain.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await Provider.of<ProductProvider>(context, listen: false).deleteProduct(product.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
                          }
                        }
                      },
                    ),
                  ],
                ),
                onTap: null,
              );
            },
          );
        },
      ),
    );
  }
}
