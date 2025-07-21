import 'package:flutter/material.dart';
import 'package:farmconnect/core/constants/app_constants.dart';

class CropsScreen extends StatelessWidget {
  const CropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search crops...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  // Show filter options
                },
                icon: const Icon(Icons.filter_list),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Vegetables'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Fruits'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Grains'),
                  selected: false,
                  onSelected: (selected) {},
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Herbs'),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Crops Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return _buildCropCard(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, int index) {
    final crops = [
      {'name': 'Tomatoes', 'price': '\$3.50/kg', 'farmer': 'John Doe'},
      {'name': 'Carrots', 'price': '\$2.25/kg', 'farmer': 'Jane Smith'},
      {'name': 'Lettuce', 'price': '\$1.80/kg', 'farmer': 'Bob Johnson'},
      {'name': 'Potatoes', 'price': '\$1.50/kg', 'farmer': 'Alice Brown'},
      {'name': 'Onions', 'price': '\$2.00/kg', 'farmer': 'Charlie Davis'},
      {'name': 'Peppers', 'price': '\$4.00/kg', 'farmer': 'Diana Wilson'},
    ];

    final crop = crops[index];
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to crop details
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Icon(
                  Icons.grass,
                  size: 48,
                  color: Colors.green[700],
                ),
              ),
            ),
            
            // Crop Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      crop['name']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      crop['price']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by ${crop['farmer']}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
