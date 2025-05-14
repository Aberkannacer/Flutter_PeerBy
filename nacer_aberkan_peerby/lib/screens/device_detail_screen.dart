import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String name;
  final String description;
  final double price;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;
  final String deviceId;
  final String ownerId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.startDate,
    this.endDate,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  Future<void> _reserveDevice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final reservation = {
      'deviceId': widget.deviceId,
      'ownerId': widget.ownerId,
      'renterId': user.uid,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('reservations').add(reservation);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toestel gereserveerd!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(widget.description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Categorie: ${widget.category}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text(
              'Prijs: €${widget.price.toStringAsFixed(2)} per dag',
              style: const TextStyle(fontSize: 16),
            ),
            if (widget.startDate != null && widget.endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Beschikbaar van ${widget.startDate!.day}/${widget.startDate!.month}/${widget.startDate!.year} '
                  'tot ${widget.endDate!.day}/${widget.endDate!.month}/${widget.endDate!.year}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _reserveDevice,
              child: const Text('Reserveer'),
            ),
          ],
        ),
      ),
    );
  }
}
