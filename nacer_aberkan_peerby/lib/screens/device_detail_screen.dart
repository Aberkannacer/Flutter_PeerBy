import 'package:flutter/material.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String name;
  final String description;
  final double price;
  final String category;

  const DeviceDetailScreen({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Categorie: $category',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Prijs: €$price per dag',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Later: reserveren
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reserveer functie komt later!')),
                );
              },
              child: const Text('Reserveer'),
            ),
          ],
        ),
      ),
    );
  }
}
