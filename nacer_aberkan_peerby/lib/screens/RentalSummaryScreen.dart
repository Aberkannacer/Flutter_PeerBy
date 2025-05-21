import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RentalSummaryScreen extends StatefulWidget {
  final String deviceId;
  final Map<String, dynamic> deviceData;

  const RentalSummaryScreen({
    super.key,
    required this.deviceId,
    required this.deviceData,
  });

  @override
  State<RentalSummaryScreen> createState() => _RentalSummaryScreenState();
}

class _RentalSummaryScreenState extends State<RentalSummaryScreen> {
  String? renterName;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('reservations')
            .where('deviceId', isEqualTo: widget.deviceId)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      setState(() {
        renterName = widget.deviceData['renterName'] ?? 'Onbekend';
        startDate = (data['startDate'] as Timestamp).toDate();
        endDate = (data['endDate'] as Timestamp).toDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.deviceData;

    return Scaffold(
      appBar: AppBar(title: Text(device['name'] ?? 'Toestel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device['name'] ?? 'Geen naam',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(device['description'] ?? 'Geen beschrijving'),
            const SizedBox(height: 16),
            Text('Categorie: ${device['category'] ?? '-'}'),
            Text('Prijs: €${(device['price'] ?? 0).toString()} per dag'),
            const SizedBox(height: 16),
            if (startDate != null && endDate != null)
              Text(
                'Verhuurd van ${startDate!.day}/${startDate!.month} '
                'tot ${endDate!.day}/${endDate!.month}',
              ),
            if (renterName != null)
              Text(
                'Verhuurd aan: $renterName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            const Text('📷 Foto van het toestel komt hier later...'),
          ],
        ),
      ),
    );
  }
}
