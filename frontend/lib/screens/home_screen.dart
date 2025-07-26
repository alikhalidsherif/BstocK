import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/change_request_provider.dart'; // Added import for ChangeRequestProvider
import '../api/api_service.dart';
import '../models/models.dart';
import '../widgets/reusable_widgets.dart';
import 'package:bstock_app/widgets/app_drawer.dart';
import 'package:bstock_app/widgets/product_search_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  @override
  void initState() {
    super.initState();
    // Fetch products when the screen is first initialized
    // We use addPostFrameCallback to ensure the context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  Future<void> _showInquireDialog() async {
    final Product? selectedProduct = await showProductSearchDialog(context);

    if (selectedProduct != null && mounted) {
      context.go('/product/${selectedProduct.barcode}');
    }
  }

  Future<void> _showStockChangeDialog(BuildContext context,
      {required ChangeRequestAction action}) async {
    final Product? selectedProduct = await showProductSearchDialog(context);

    if (selectedProduct == null) return;

    final product = selectedProduct;
    final quantityController = TextEditingController();
    final buyerController = TextEditingController();
    String paymentStatus = 'unpaid'; // Default value

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          // To update payment status dropdown
          builder: (context, setState) {
            return AlertDialog(
              title: Text(product.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current Quantity: ${product.quantity}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration:
                        InputDecoration(labelText: 'Quantity to ${action.name}'),
                    keyboardType: TextInputType.number,
                    autofocus: true,
                  ),
                  if (action == ChangeRequestAction.sell) ...[
                    TextField(
                      controller: buyerController,
                      decoration: const InputDecoration(labelText: 'Buyer Name (Optional)'),
                    ),
                    DropdownButton<String>(
                      value: paymentStatus,
                      items: const [
                        DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                        DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            paymentStatus = value;
                          });
                        }
                      },
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                TextButton(
                  child: const Text('Submit Request'),
                  onPressed: () async {
                    final quantity = int.tryParse(quantityController.text);
                    if (quantity != null && quantity > 0) {
                      try {
                        await Provider.of<ChangeRequestProvider>(context,
                                listen: false)
                            .submitRequest(
                          barcode: product.barcode,
                          action: action,
                          quantity: quantity,
                          buyerName: action == ChangeRequestAction.sell ? buyerController.text : null,
                          paymentStatus: action == ChangeRequestAction.sell ? paymentStatus : null,
                        );
                        if (mounted) {
                          Navigator.of(context).pop(); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request submitted successfully!')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isAdmin = authProvider.user?.role == UserRole.admin;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authProvider.user?.username ?? 'User'}!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                _buildQuickActionsGrid(context, isAdmin),
                const SizedBox(height: 24),
                Text(
                  'Product Inquiry',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _buildInquireCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, bool isAdmin) {
    final actions = [
      _buildActionCard(
        context,
        icon: Icons.add_shopping_cart_rounded,
        label: 'Add Stock',
        onTap: () => _showStockChangeDialog(context, action: ChangeRequestAction.add),
      ),
      _buildActionCard(
        context,
        icon: Icons.shopping_cart_checkout_rounded,
        label: 'Sell Stock',
        onTap: () => _showStockChangeDialog(context, action: ChangeRequestAction.sell),
      ),
      _buildActionCard(
        context,
        icon: Icons.add_business_rounded,
        label: 'New Product',
        onTap: () => context.push('/add-new-product'),
      ),
      if (isAdmin)
        _buildActionCard(
          context,
          icon: Icons.edit_document,
          label: 'Edit Product',
          onTap: () => context.push('/edit-product'),
        ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => actions[index],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(label, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildInquireCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Scan a barcode to quickly find a product.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _showInquireDialog,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 