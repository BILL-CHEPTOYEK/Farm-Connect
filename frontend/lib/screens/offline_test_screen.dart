import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/services/sync_service.dart';

class OfflineTestScreen extends StatefulWidget {
  const OfflineTestScreen({super.key});

  @override
  State<OfflineTestScreen> createState() => _OfflineTestScreenState();
}

class _OfflineTestScreenState extends State<OfflineTestScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();
  List<Map<String, dynamic>> crops = [];
  List<Map<String, dynamic>> orders = [];
  bool isLoading = false;
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
    _checkConnectivity();
  }

  Future<void> _loadLocalData() async {
    setState(() {
      isLoading = true;
    });

    final localCrops = await _dbHelper.getAllCrops();
    final localOrders = await _dbHelper.getOrdersWithDetails();

    setState(() {
      crops = localCrops;
      orders = localOrders;
      isLoading = false;
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await _syncService.isOnline();
    setState(() {
      isOnline = online;
    });
  }

  Future<void> _addTestCrop() async {
    final testCrop = {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Test Crop ${DateTime.now().second}',
      'category': 'Test',
      'description': 'This is a test crop added offline',
      'price_per_unit': 10.0,
      'unit': 'kg',
      'image_url': 'https://via.placeholder.com/150',
    };

    await _dbHelper.insertCrop(testCrop);
    _loadLocalData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test crop added to local database')),
    );
  }

  Future<void> _addTestOrder() async {
    if (crops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some crops first')),
      );
      return;
    }

    final testOrder = {
      'id': 'order_${DateTime.now().millisecondsSinceEpoch}',
      'crop_id': crops.first['id'],
      'farmer_id': 'test_farmer_1',
      'quantity': 5,
      'total_price': 50.0,
      'status': 'pending',
      'order_date': DateTime.now().toIso8601String(),
    };

    await _dbHelper.insertOrder(testOrder);
    _loadLocalData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test order added to local database')),
    );
  }

  Future<void> _performSync() async {
    setState(() {
      isLoading = true;
    });

    final success = await _syncService.performFullSync();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync failed - check internet connection')),
      );
    }

    _loadLocalData();
    _checkConnectivity();
  }

  Future<void> _clearLocalData() async {
    await _dbHelper.clearAllData();
    _loadLocalData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local data cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Database Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(isOnline ? 'Online' : 'Offline'),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addTestCrop,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Test Crop'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addTestOrder,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Add Test Order'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _performSync,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync Data'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _clearLocalData,
                        icon: const Icon(Icons.delete),
                        label: const Text('Clear Local Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Local Crops
                  Text(
                    'Local Crops (${crops.length})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (crops.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No crops in local database'),
                      ),
                    )
                  else
                    ...crops.map((crop) => Card(
                          child: ListTile(
                            leading: crop['image_url'] != null
                                ? Image.network(
                                    crop['image_url'],
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.image_not_supported);
                                    },
                                  )
                                : const Icon(Icons.agriculture),
                            title: Text(crop['name'] ?? 'Unknown'),
                            subtitle: Text('${crop['category']} - \$${crop['price_per_unit']}/${crop['unit']}'),
                            trailing: Icon(
                              crop['synced'] == 1 ? Icons.cloud_done : Icons.cloud_upload,
                              color: crop['synced'] == 1 ? Colors.green : Colors.orange,
                            ),
                          ),
                        )),
                  
                  const SizedBox(height: 24),
                  
                  // Local Orders
                  Text(
                    'Local Orders (${orders.length})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (orders.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No orders in local database'),
                      ),
                    )
                  else
                    ...orders.map((order) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.shopping_bag),
                            title: Text(order['crop_name'] ?? 'Unknown Crop'),
                            subtitle: Text(
                              'Qty: ${order['quantity']} - Total: \$${order['total_price']}\n'
                              'Status: ${order['status']}',
                            ),
                            trailing: Icon(
                              order['synced'] == 1 ? Icons.cloud_done : Icons.cloud_upload,
                              color: order['synced'] == 1 ? Colors.green : Colors.orange,
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
