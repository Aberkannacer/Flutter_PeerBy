import 'package:flutter/material.dart';

class DeviceDetailScreen extends StatelessWidget {
  final String name;
  final String description;
  final double price;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;

  const DeviceDetailScreen({
    super.key,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.startDate,
    this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
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
            Text(description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Categorie: $category', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              'Prijs: €$price per dag',
              style: const TextStyle(fontSize: 16),
            ),
            if (startDate != null && endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Beschikbaar van ${startDate!.day}/${startDate!.month}/${startDate!.year} '
                  'tot ${endDate!.day}/${endDate!.month}/${endDate!.year}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reserveer functie komt later!'),
                  ),
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
