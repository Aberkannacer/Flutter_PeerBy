import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalDetailScreen extends StatelessWidget {
  final String deviceId;

  const RentalDetailScreen({super.key, required this.deviceId});

  Future<Map<String, dynamic>?> _fetchRentalDetails() async {
    final deviceDoc = await FirebaseFirestore.instance.collection('devices').doc(deviceId).get();
    final reservationQuery = await FirebaseFirestore.instance
        .collection('reservations')
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (!deviceDoc.exists || reservationQuery.docs.isEmpty) return null;

    final deviceData = deviceDoc.data()!;
    final reservation = reservationQuery.docs.first.data();

    return {
      'name': deviceData['name'],
      'description': deviceData['description'],
      'category': deviceData['category'],
      'startDate': (reservation['startDate'] as Timestamp).toDate(),
      'endDate': (reservation['endDate'] as Timestamp).toDate(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details gehuurd toestel')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchRentalDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Geen gegevens gevonden.'));
          }

          final data = snapshot.data!;
          final start = data['startDate'] as DateTime;
          final end = data['endDate'] as DateTime;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Onbekend',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Categorie: ${data['category']}'),
                const SizedBox(height: 8),
                Text('Gehuurd van ${start.day}/${start.month}/${start.year} tot ${end.day}/${end.month}/${end.year}'),
                const SizedBox(height: 16),
                Text(data['description'] ?? ''),
                const SizedBox(height: 16),
                const Text('Afbeelding komt later hier.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }
}
