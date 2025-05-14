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
              final data = device.data() as Map<String, dynamic>?;

              final name = data?['name'] ?? 'Onbekend';
              final description = data?['description'] ?? '';
              final price = data?['price'] ?? 0;
              final category = data?['category'] ?? '';

              final startDate =
                  data != null && data.containsKey('startDate')
                      ? (data['startDate'] as Timestamp?)?.toDate()
                      : null;

              final endDate =
                  data != null && data.containsKey('endDate')
                      ? (data['endDate'] as Timestamp?)?.toDate()
                      : null;

              final deviceId = device.id;

              final ownerId =
                  data != null && data.containsKey('ownerId')
                      ? data['ownerId']
                      : 'onbekend';

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
                              deviceId: deviceId,
                              ownerId: ownerId,
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
