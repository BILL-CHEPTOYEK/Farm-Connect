import 'package:flutter/material.dart';
import 'package:farmconnect/core/constants/app_constants.dart';

class FarmersScreen extends StatelessWidget {
  const FarmersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,        children: [
          // Search Bar
          TextField(
              decoration: InputDecoration(
                hintText: 'Search farmers...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Filter Chips
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Farmers List (placeholder)
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Icon(
                          Icons.person,
                          color: Colors.green[700],
                        ),
                      ),
                      title: Text('Farmer ${index + 1}'),
                      subtitle: const Text('Location • Specialties'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to farmer details
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
}
