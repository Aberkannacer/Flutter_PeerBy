import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;
  final String ownerId;
  final String name;
  final String description;
  final double price;
  final String category;
  final DateTime? startDate;
  final DateTime? endDate;

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
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  bool _isSubmitting = false;

  Future<void> _selectDates() async {
    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: widget.startDate ?? DateTime.now(),
      lastDate: widget.endDate ?? DateTime.now().add(const Duration(days: 365)),
    );

    if (range != null) {
      setState(() {
        _selectedStart = range.start;
        _selectedEnd = range.end;
      });
    }
  }


  Future<void> _reserveDevice() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (currentUser.uid == widget.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Je kan je eigen toestel niet reserveren.')),
      );
      return;
    }

    if (_selectedStart == null || _selectedEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kies een periode om te reserveren.')),
      );
      return;
    }

    if (widget.startDate != null && _selectedStart!.isBefore(widget.startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Startdatum valt buiten de beschikbaarheid.')),
      );
      return;
    }
    if (widget.endDate != null && _selectedEnd!.isAfter(widget.endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einddatum valt buiten de beschikbaarheid.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final reservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('deviceId', isEqualTo: widget.deviceId)
        .get();

    for (var doc in reservations.docs) {
      final data = doc.data();
      final Timestamp? startTimestamp = data['startDate'];
      final Timestamp? endTimestamp = data['endDate'];
      final String renterId = data['renterId'];

      if (startTimestamp == null || endTimestamp == null) continue;

      final existingStart = startTimestamp.toDate();
      final existingEnd = endTimestamp.toDate();

      if (renterId == currentUser.uid &&
          _selectedStart!.isBefore(existingEnd) &&
          _selectedEnd!.isAfter(existingStart)) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Je hebt dit toestel al in die periode gereserveerd.')),
        );
        return;
      }

      if (_selectedStart!.isBefore(existingEnd) &&
          _selectedEnd!.isAfter(existingStart)) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deze periode is al (deels) gereserveerd.')),
        );
        return;
      }
    }

    await FirebaseFirestore.instance.collection('reservations').add({
      'deviceId': widget.deviceId,
      'ownerId': widget.ownerId,
      'renterId': currentUser.uid,
      'startDate': _selectedStart,
      'endDate': _selectedEnd,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservering succesvol!')),
    );

    setState(() => _isSubmitting = false);
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
            Text(widget.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(widget.description, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text('Categorie: ${widget.category}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Prijs: €${widget.price.toStringAsFixed(2)} per dag', style: const TextStyle(fontSize: 16)),
            if (widget.startDate != null && widget.endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Beschikbaar van ${widget.startDate!.day}/${widget.startDate!.month}/${widget.startDate!.year} '
                  'tot ${widget.endDate!.day}/${widget.endDate!.month}/${widget.endDate!.year}',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectDates,
              child: const Text('Kies periode'),
            ),
            if (_selectedStart != null && _selectedEnd != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Gekozen: ${_selectedStart!.day}/${_selectedStart!.month}/${_selectedStart!.year} - '
                  '${_selectedEnd!.day}/${_selectedEnd!.month}/${_selectedEnd!.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _reserveDevice,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Reserveer'),
            ),
          ],
        ),
      ),
    );
  }
}
