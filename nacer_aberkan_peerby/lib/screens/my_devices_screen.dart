import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyDevicesScreen extends StatefulWidget {
  const MyDevicesScreen({super.key});

  @override
  State<MyDevicesScreen> createState() => _MyDevicesScreenState();
}

class _MyDevicesScreenState extends State<MyDevicesScreen> {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Map<String, dynamic>>> _fetchMyDevices() async {
    final devices = await FirebaseFirestore.instance
        .collection('devices')
        .where('ownerId', isEqualTo: userId)
        .get();

    return devices.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }

  Future<bool> _hasReservations(String deviceId) async {
    final res = await FirebaseFirestore.instance
        .collection('reservations')
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();
    return res.docs.isNotEmpty;
  }

  Future<void> _deleteDevice(String deviceId) async {
    final hasReservations = await _hasReservations(deviceId);
    if (hasReservations) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dit toestel kan niet verwijderd worden omdat er nog reserveringen aan gekoppeld zijn.'),
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('devices').doc(deviceId).delete();
    setState(() {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toestel verwijderd.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Devices')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Je hebt nog geen toestellen toegevoegd.'));
          }

          final devices = snapshot.data!;

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(device['name'] ?? 'Onbekend'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Categorie: ${device['category'] ?? ''}'),
                      Text('Prijs: €${device['price']?.toStringAsFixed(2) ?? '-'} per dag'),
                      if (device['startDate'] != null && device['endDate'] != null)
                        Text(
                          'Beschikbaar van ${device['startDate'].toDate().day}/${device['startDate'].toDate().month}/${device['startDate'].toDate().year} tot ${device['endDate'].toDate().day}/${device['endDate'].toDate().month}/${device['endDate'].toDate().year}',
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDevice(device['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
