import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../api/api_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  List<ChangeHistory> _sales = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().getSalesHistory();
      setState(() => _sales = response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sales: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportSalesToExcel() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error. Please log in again.')),
      );
      return;
    }

    final url = Uri.parse('${ApiService().baseUrl}/history/sales/export?token=$token');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  List<ChangeHistory> get filteredSales {
    if (_searchQuery.isEmpty) return _sales;
    return _sales.where((sale) {
      final productName = sale.product?.name?.toLowerCase() ?? '';
      final buyerName = sale.buyerName?.toLowerCase() ?? '';
      final barcode = sale.product?.barcode?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return productName.contains(query) || 
             buyerName.contains(query) || 
             barcode.contains(query);
    }).toList();
  }

  double get totalSalesAmount {
    return filteredSales.fold(0.0, (sum, sale) {
      final quantity = sale.quantityChange?.abs() ?? 0;
      final price = sale.product?.price ?? 0;
      return sum + (quantity * price);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Tracking'),
        actions: [
          IconButton(
            onPressed: _exportSalesToExcel,
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
          ),
          IconButton(
            onPressed: _fetchSales,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Summary
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search sales...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('${filteredSales.length}', 
                                 style: Theme.of(context).textTheme.headlineSmall),
                            const Text('Sales'),
                          ],
                        ),
                        Column(
                          children: [
                            Text('\$${totalSalesAmount.toStringAsFixed(2)}', 
                                 style: Theme.of(context).textTheme.headlineSmall),
                            const Text('Total Revenue'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sales List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filteredSales.isEmpty
                ? const Center(child: Text('No sales found'))
                : ListView.builder(
                    itemCount: filteredSales.length,
                    itemBuilder: (context, index) {
                      final sale = filteredSales[index];
                      final quantity = sale.quantityChange?.abs() ?? 0;
                      final price = sale.product?.price ?? 0;
                      final total = quantity * price;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text('$quantity'),
                          ),
                          title: Text(sale.product?.name ?? 'Unknown Product'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Buyer: ${sale.buyerName ?? 'N/A'}'),
                              Text('Payment: ${sale.paymentStatus?.toString().split('.').last ?? 'N/A'}'),
                              Text('Date: ${DateFormat('MMM dd, yyyy HH:mm').format(sale.timestamp)}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${total.toStringAsFixed(2)}', 
                                   style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('\$${price.toStringAsFixed(2)} each'),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 