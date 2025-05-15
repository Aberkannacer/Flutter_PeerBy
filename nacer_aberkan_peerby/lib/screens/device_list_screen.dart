import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  Future<bool> _isReserved(String deviceId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('reservations')
            .where('deviceId', isEqualTo: deviceId)
            .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
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

          // 🔥 Filter eigen toestellen eruit
          final devices =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data != null && data['ownerId'] != currentUserId;
              }).toList();

          if (devices.isEmpty) {
            return const Center(
              child: Text('Geen externe toestellen gevonden.'),
            );
          }

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final data = device.data() as Map<String, dynamic>?;

              final name = data?['name'] ?? 'Onbekend';
              final description = data?['description'] ?? '';
              final price = data?['price'] ?? 0;
              final category = data?['category'] ?? '';
              final startDate = (data?['startDate'] as Timestamp?)?.toDate();
              final endDate = (data?['endDate'] as Timestamp?)?.toDate();
              final deviceId = device.id;
              final ownerId = data?['ownerId'] ?? 'onbekend';

              return FutureBuilder<bool>(
                future: _isReserved(deviceId),
                builder: (context, reservedSnapshot) {
                  final isReserved = reservedSnapshot.data ?? false;

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
                          if (isReserved)
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text(
                                '⚠️ Reeds gereserveerd',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
          );
        },
      ),
    );
  }
}
