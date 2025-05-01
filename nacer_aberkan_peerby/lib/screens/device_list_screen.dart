import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devicesCollection = FirebaseFirestore.instance.collection('devices');

    return Scaffold(
      appBar: AppBar(title: const Text('Beschikbare Toestellen')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            devicesCollection
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nog geen toestellen beschikbaar.'),
            );
          }

          final devices = snapshot.data!.docs;

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final name = device['name'];
              final description = device['description'];
              final price = device['price'];
              final category = device['category'];
              final startDate = (device['startDate'] as Timestamp?)?.toDate();
              final endDate = (device['endDate'] as Timestamp?)?.toDate();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description),
                      const SizedBox(height: 4),
                      Text('Categorie: $category'),
                      Text('Prijs: €$price per dag'),
                      if (startDate != null && endDate != null)
                        Text(
                          'Beschikbaar van ${startDate.day}/${startDate.month}/${startDate.year} '
                          'tot ${endDate.day}/${endDate.month}/${endDate.year}',
                          style: const TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => DeviceDetailScreen(
                              name: name,
                              description: description,
                              price: price.toDouble(),
                              category: category,
                              startDate: startDate,
                              endDate: endDate,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
