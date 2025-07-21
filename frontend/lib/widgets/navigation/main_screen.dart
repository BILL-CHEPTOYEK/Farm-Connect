import 'package:flutter/material.dart';
import 'package:farmconnect/core/constants/app_constants.dart';
import 'package:farmconnect/screens/home_screen.dart';
import 'package:farmconnect/screens/farmers/farmers_screen.dart';
import 'package:farmconnect/screens/orders/orders_screen.dart';
import 'package:farmconnect/screens/crops/crops_screen.dart';
import 'package:farmconnect/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const HomeScreen(),
    const FarmersScreen(),
    const OrdersScreen(),
    const CropsScreen(),
    const ProfileScreen(),
  ];

  // Different titles for each screen (null means no AppBar)
  final List<String?> _screenTitles = [
    null, // Home screen - no AppBar (has its own header)
    'Farmers', // Farmers screen
    'Orders', // Orders screen  
    'Crops', // Crops screen
    'Profile', // Profile screen
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Helper method to determine which FAB to show
  Widget? _getFAB() {
    switch (_selectedIndex) {
      case 1: // Farmers screen
        return FloatingActionButton(
          onPressed: () {
            // Add new farmer
          },
          child: const Icon(Icons.add),
        );
      case 2: // Orders screen
        return FloatingActionButton(
          onPressed: () {
            // Create new order
          },
          child: const Icon(Icons.add_shopping_cart),
        );
      case 3: // Crops screen
        return FloatingActionButton(
          onPressed: () {
            // Add new crop listing
          },
          child: const Icon(Icons.add),
        );
      default:
        return null; // No FAB for home and profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show AppBar only for non-home screens
      appBar: _screenTitles[_selectedIndex] != null
          ? AppBar(
              title: Text(_screenTitles[_selectedIndex]!),
              centerTitle: true,
              elevation: 0, // Modern flat design
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      body: _screens[_selectedIndex],
      // Show FAB only for specific screens
      floatingActionButton: _getFAB(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: AppStrings.homeLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: AppStrings.farmersLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: AppStrings.ordersLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grass),
            label: AppStrings.cropsLabel,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: AppStrings.profileLabel,
          ),
        ],
      ),
    );
  }
}
