import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'device_detail_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final devicesCollection = FirebaseFirestore.instance.collection('devices');

  String _selectedCategory = 'Alle';
  double _radiusInKm = 10.0;
  LatLng? _currentLocation;

  final List<String> _categories = [
    'Alle',
    'Huishouden',
    'Tuin',
    'Keuken',
    'Elektronica',
    'Overige',
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  bool _isWithinRadius(double lat, double lng) {
    if (_currentLocation == null) return true;
    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      lat,
      lng,
    );
    return distance <= _radiusInKm * 1000;
  }

  Future<List<DateTime>> _getAvailableDates(String deviceId, DateTime start, DateTime end) async {
    final reservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('deviceId', isEqualTo: deviceId)
        .get();

    final reservedRanges = reservations.docs.map((doc) {
      final data = doc.data();
      final startDate = (data['startDate'] as Timestamp).toDate();
      final endDate = (data['endDate'] as Timestamp).toDate();
      return [startDate, endDate];
    }).toList();

    List<DateTime> availableDays = [];
    DateTime current = start;
    while (!current.isAfter(end)) {
      final isReserved = reservedRanges.any((range) => current.isAfter(range[0].subtract(const Duration(days: 1))) && current.isBefore(range[1].add(const Duration(days: 1))));
      if (!isReserved) availableDays.add(current);
      current = current.add(const Duration(days: 1));
    }

    return availableDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beschikbare Toestellen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<double>(
                  value: _radiusInKm,
                  items: [5.0, 10.0, 20.0, 50.0, 100.0].map((radius) {
                    return DropdownMenuItem(
                      value: radius,
                      child: Text('${radius.toInt()} km'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _radiusInKm = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: devicesCollection.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nog geen toestellen beschikbaar.'));
                }

                final devices = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null || data['ownerId'] == currentUserId) return false;

                  final matchesCategory = _selectedCategory == 'Alle' || data['category'] == _selectedCategory;

                  final lat = (data['latitude'] as num?)?.toDouble();
                  final lng = (data['longitude'] as num?)?.toDouble();
                  final matchesRadius = lat != null && lng != null ? _isWithinRadius(lat, lng) : false;

                  return matchesCategory && matchesRadius;
                }).toList();

                if (devices.isEmpty) {
                  return const Center(child: Text('Geen toestellen in de buurt gevonden.'));
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

                    return FutureBuilder<List<DateTime>>(
                      future: _getAvailableDates(deviceId, startDate!, endDate!),
                      builder: (context, snapshot) {
                        final availableDates = snapshot.data;

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
                                    'Beschikbaar van ${startDate.day}/${startDate.month}/${startDate.year} tot ${endDate.day}/${endDate.month}/${endDate.year}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                if (availableDates != null && availableDates.isNotEmpty)
                                  Text(
                                    'Vrij: ${availableDates.map((d) => '${d.day}/${d.month}').join(', ')}',
                                    style: const TextStyle(color: Colors.blueGrey),
                                  )
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeviceDetailScreen(
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
          ),
        ],
      ),
    );
  }
}
