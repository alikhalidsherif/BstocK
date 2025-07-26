import 'package:bstock_app/widgets/reusable_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../models/models.dart';

class EditProductListScreen extends StatefulWidget {
  const EditProductListScreen({super.key});

  @override
  State<EditProductListScreen> createState() => _EditProductListScreenState();
}

class _EditProductListScreenState extends State<EditProductListScreen> {
  String? _selectedCategory;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Product to Edit'),
      ),
      body: Column(
        children: [
          // Simplified search and sort for this screen
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search...'),
                    onChanged: (value) =>
                        Provider.of<ProductProvider>(context, listen: false).searchProducts(value),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<SortType>(
                  value: Provider.of<ProductProvider>(context, listen: false).sortType,
                  items: SortType.values.map((type) {
                    return DropdownMenuItem<SortType>(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (SortType? newValue) {
                    if (newValue != null) {
                      Provider.of<ProductProvider>(context, listen: false).sortProducts(newValue);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                final categories = ['All Categories', ...productProvider.categories];
                String currentCategory = productProvider.products.isNotEmpty && _selectedCategory != null
                    ? _selectedCategory!
                    : 'All Categories';
                if(!categories.contains(currentCategory)) currentCategory = 'All Categories';
                
                return DropdownButton<String>(
                  value: currentCategory,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue == 'All Categories') {
                      productProvider.selectCategory(null);
                      _selectedCategory = null;
                    } else {
                      productProvider.selectCategory(newValue);
                      _selectedCategory = newValue;
                    }
                    setState(() {});
                  },
                  items: categories.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.products.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }

                return ListView.builder(
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final product = productProvider.products[index];
                    return GenericListItem(
                      title: product.name,
                      subtitle: 'Barcode: ${product.barcode} | Category: ${product.category}',
                      trailing: Text('Qty: ${product.quantity}'),
                      onTap: () {
                        context.push('/edit-product-details', extra: product);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 