import 'package:bstock_app/providers/product_provider.dart';
import 'package:bstock_app/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-new-product'),
        tooltip: 'Add New Product',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(context),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading && productProvider.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (productProvider.products.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return RefreshIndicator(
                  onRefresh: () => productProvider.fetchProducts(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 2 / 2.5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          context.push('/product/${product.barcode}', extra: product);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or barcode...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            ),
            onChanged: (value) {
              productProvider.searchProducts(value);
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryDropdown(context),
              _buildSortDropdown(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final categories = ['All Categories', ...productProvider.categories];
        String currentCategory = _selectedCategory ?? 'All Categories';
        if (!categories.contains(currentCategory)) {
          currentCategory = 'All Categories';
        }

        return DropdownButton<String>(
          value: currentCategory,
          hint: const Text('Filter by Category'),
          onChanged: (String? newValue) {
            setState(() {
              _selectedCategory = newValue;
              productProvider.selectCategory(newValue == 'All Categories' ? null : newValue);
            });
          },
          items: categories.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSortDropdown(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return DropdownButton<SortType>(
          value: productProvider.sortType,
          hint: const Text('Sort by'),
          onChanged: (SortType? newValue) {
            if (newValue != null) {
              productProvider.sortProducts(newValue);
            }
          },
          items: SortType.values.map((SortType classType) {
            return DropdownMenuItem<SortType>(
              value: classType,
              child: Text(classType.name.replaceAll('_', ' ')),
            );
          }).toList(),
        );
      },
    );
  }
} 