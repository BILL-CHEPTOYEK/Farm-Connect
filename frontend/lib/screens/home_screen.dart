import 'package:flutter/material.dart';
import 'package:farmconnect/core/constants/app_constants.dart';
import 'package:farmconnect/core/database/database_helper.dart';
import 'package:farmconnect/core/services/sync_service.dart';
import 'package:farmconnect/screens/offline_test_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> crops = [];
  bool isLoading = true;
  String error = '';
  bool isOnline = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SyncService _syncService = SyncService();

  @override
  void initState() {
    super.initState();
    fetchCrops();
    _checkConnectivityAndSync();
  }

  Future<void> _checkConnectivityAndSync() async {
    isOnline = await _syncService.isOnline();
    if (isOnline) {
      // Perform background sync
      _syncService.performFullSync();
    }
  }

  Future<void> fetchCrops() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      // Check if online
      isOnline = await _syncService.isOnline();
      
      if (isOnline) {
        // Try to fetch from server
        final response = await http.get(Uri.parse('http://192.168.100.144:6000/api/crops'));
        if (response.statusCode == 200) {
          final serverCrops = jsonDecode(response.body)['data'];
          
          // Update local database
          await _dbHelper.bulkInsertCrops(List<Map<String, dynamic>>.from(serverCrops));
          
          setState(() {
            crops = serverCrops;
            isLoading = false;
          });
          return;
        }
      }
      
      // Fallback to local database
      final localCrops = await _dbHelper.getAllCrops();
      setState(() {
        crops = localCrops;
        isLoading = false;
        if (localCrops.isEmpty && !isOnline) {
          error = 'No internet connection and no cached data available';
        }
      });
      
    } catch (e) {
      // If network fails, try local database
      final localCrops = await _dbHelper.getAllCrops();
      setState(() {
        crops = localCrops;
        isLoading = false;
        if (localCrops.isEmpty) {
          error = 'No internet connection and no cached data available';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Welcome Section with Background Image
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/farmconnect.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        BlendMode.overlay,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good Morning!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.agriculture, color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'FarmConnect',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Connecting farmers to markets directly',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'View All',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick Action Cards
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildQuickActionCard(
                        context,
                        assetImage: 'assets/images/findfarmer.jpeg',
                        icon: Icons.people,
                        title: 'Find Farmers',
                        subtitle: 'Connect with local farmers',
                        gradient: const [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                      ),
                      _buildQuickActionCard(
                        context,
                        assetImage: 'assets/images/order.png',
                        icon: Icons.shopping_cart,
                        title: 'Place Order',
                        subtitle: 'Order fresh produce',
                        gradient: const [Color(0xFFFFB74D), Color(0xFFFF9800)],
                      ),
                      _buildQuickActionCard(
                        context,
                        assetImage: 'assets/images/crops.png',
                        icon: Icons.grass,
                        title: 'Browse Crops',
                        subtitle: 'View available crops',
                        gradient: const [Color(0xFF81C784), Color(0xFF66BB6A)],
                      ),
                      _buildQuickActionCard(
                        context,
                        assetImage: 'assets/images/history.png',
                        icon: Icons.history,
                        title: 'Order History',
                        subtitle: 'View past orders',
                        gradient: const [Color(0xFFBA68C8), Color(0xFFAB47BC)],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Debug/Test Button for Offline Database
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OfflineTestScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Test Offline Database'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Crops Section (dynamic from database with offline support)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Available Crops',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isOnline ? Icons.cloud_done : Icons.cloud_off,
                            size: 16,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (error.isNotEmpty)
                    Text(error, style: const TextStyle(color: Colors.red)),
                  if (!isLoading && error.isEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: crops.length,
                      itemBuilder: (context, index) {
                        final crop = crops[index];
                        return Card(
                          child: ListTile(
                            leading: crop['image_url'] != null
                                ? Image.network(
                                    crop['image_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.agriculture);
                                    },
                                  )
                                : const Icon(Icons.agriculture),
                            title: Text(crop['name'] ?? ''),
                            subtitle: Text(crop['category'] ?? ''),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 32),
                  // ...existing code for statistics and recent activity...
                  // Statistics Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your FarmConnect Stats',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              context,
                              icon: Icons.shopping_bag,
                              value: '12',
                              label: 'Orders',
                              color: Colors.blue,
                            ),
                            _buildStatItem(
                              context,
                              icon: Icons.people,
                              value: '8',
                              label: 'Farmers',
                              color: Colors.green,
                            ),
                            _buildStatItem(
                              context,
                              icon: Icons.savings,
                              value: '\$245',
                              label: 'Saved',
                              color: Colors.orange,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Recent Activity Section
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildActivityItem(
                          context,
                          icon: Icons.local_shipping,
                          title: 'Order Delivered',
                          subtitle: 'Fresh tomatoes from John\'s Farm',
                          time: '2 hours ago',
                          iconColor: Colors.green,
                        ),
                        const Divider(height: 1),
                        _buildActivityItem(
                          context,
                          icon: Icons.new_releases,
                          title: 'New Farmer Available',
                          subtitle: 'Sarah\'s Organic Farm joined',
                          time: '1 day ago',
                          iconColor: Colors.blue,
                        ),
                        const Divider(height: 1),
                        _buildActivityItem(
                          context,
                          icon: Icons.info_outline,
                          title: 'Welcome to FarmConnect!',
                          subtitle: 'Start by exploring farmers and available crops',
                          time: '3 days ago',
                          iconColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    String? assetImage,
    IconData? icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Handle quick action tap
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: assetImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              assetImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    icon ?? Icons.help_outline,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon ?? Icons.help_outline,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[500],
        ),
      ),
      onTap: () {
        // Navigate to activity details
      },
    );
  }
}
