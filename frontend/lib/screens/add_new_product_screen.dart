import 'package:bstock_app/providers/product_provider.dart';
import 'package:bstock_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bstock_app/models/models.dart';
import 'package:bstock_app/providers/change_request_provider.dart';

class AddNewProductScreen extends StatefulWidget {
  const AddNewProductScreen({super.key});

  @override
  State<AddNewProductScreen> createState() => _AddNewProductScreenState();
}

class _AddNewProductScreenState extends State<AddNewProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitNewProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final isUnique = await _isBarcodeUnique(_barcodeController.text);
    if (!mounted) return;
    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A product with this barcode already exists.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await Provider.of<ChangeRequestProvider>(context, listen: false).submitRequest(
        action: ChangeRequestAction.create,
        newProductName: _nameController.text,
        newProductBarcode: _barcodeController.text,
        newProductPrice: double.parse(_priceController.text),
        newProductQuantity: int.parse(_quantityController.text),
        newProductCategory: _categoryController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product creation request submitted!')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _isBarcodeUnique(String barcode) async {
    final product = await Provider.of<ProductProvider>(context, listen: false)
        .fetchProductByBarcode(barcode);
    return product == null;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categoryOptions = productProvider.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  return null;
                },
              ),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price (e.g., 12.99)';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) {
                    return 'Please enter a whole number';
                  }
                  return null;
                },
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return categoryOptions;
                  }
                  return categoryOptions.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _categoryController.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  // This is a bit of a workaround to use our _categoryController
                  // with the Autocomplete widget's internal controller.
                  Future.microtask(() => fieldController.text = _categoryController.text);
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onChanged: (text) => _categoryController.text = text,
                  );
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                CustomButton(
                  onPressed: _submitNewProduct,
                  text: 'Create Product',
                  icon: Icons.add,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 