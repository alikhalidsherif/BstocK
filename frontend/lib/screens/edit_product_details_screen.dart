import 'package:bstock_app/providers/change_request_provider.dart';
import 'package:bstock_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import '../models/models.dart';

class EditProductDetailsScreen extends StatefulWidget {
  final Product product;
  const EditProductDetailsScreen({super.key, required this.product});

  @override
  State<EditProductDetailsScreen> createState() => _EditProductDetailsScreenState();
}

class _EditProductDetailsScreenState extends State<EditProductDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.product.barcode);
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _categoryController = TextEditingController(text: widget.product.category);
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProduct = Product(
      id: widget.product.id,
      barcode: _barcodeController.text,
      name: _nameController.text,
      price: double.parse(_priceController.text),
      quantity: int.parse(_quantityController.text),
      category: _categoryController.text,
    );
    try {
      await Provider.of<ProductProvider>(context, listen: false).updateProduct(updatedProduct);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully!')));
      context.pop(); // Go back to the previous screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteProduct() async {
    try {
      await Provider.of<ProductProvider>(context, listen: false).deleteProduct(widget.product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted successfully!')));
      context.go('/edit-product'); // Go back to the product list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteProduct();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(controller: _barcodeController, decoration: const InputDecoration(labelText: 'Barcode')),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextFormField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextFormField(controller: _quantityController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 20),
              CustomButton(
                onPressed: _updateProduct,
                text: 'Update Product',
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 