import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  final PopupController popupController = PopupController();

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

    print('📍 Huidige locatie: ${position.latitude}, ${position.longitude}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kaart met toestellen')),
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
                    items:
                        _categories.map((category) {
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
                  items:
                      [5.0, 10.0, 20.0, 50.0, 100.0].map((radius) {
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
              stream:
                  FirebaseFirestore.instance.collection('devices').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final devices = snapshot.data!.docs;

                final filteredDevices =
                    devices.where((device) {
                      final data = device.data() as Map<String, dynamic>;
                      final matchesCategory =
                          _selectedCategory == 'Alle' ||
                          data['category'] == _selectedCategory;

                      final lat = (data['latitude'] as num?)?.toDouble();
                      final lng = (data['longitude'] as num?)?.toDouble();
                      final matchesRadius =
                          lat != null && lng != null
                              ? _isWithinRadius(lat, lng)
                              : false;

                      return matchesCategory && matchesRadius;
                    }).toList();

                final markers =
                    filteredDevices.map((device) {
                      final data = device.data() as Map<String, dynamic>;

                      final lat = (data['latitude'] as num).toDouble();
                      final lng = (data['longitude'] as num).toDouble();

                      return Marker(
                        width: 80,
                        height: 80,
                        point: LatLng(lat, lng),
                        rotate: false,
                        builder:
                            (ctx) => const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                        key: ValueKey(device.id),
                      );
                    }).toList();

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        center: _currentLocation ?? LatLng(50.8503, 4.3517),
                        zoom: 7.0,
                        onTap: (_, __) => popupController.hideAllPopups(),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.peerby',
                        ),
                        PopupMarkerLayerWidget(
                          options: PopupMarkerLayerOptions(
                            markers: markers,
                            popupController: popupController,
                            popupBuilder: (
                              BuildContext context,
                              Marker marker,
                            ) {
                              final doc = devices.firstWhere(
                                (d) => d.id == (marker.key as ValueKey).value,
                              );
                              final data = doc.data() as Map<String, dynamic>;

                              final startDate =
                                  (data['startDate'] as Timestamp?)?.toDate();
                              final endDate =
                                  (data['endDate'] as Timestamp?)?.toDate();

                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prijs: €${data['price'].toString()} per dag',
                                      ),
                                      Text(
                                        'Categorie: ${data['category'] ?? 'Onbekend'}',
                                      ),
                                      if (startDate != null && endDate != null)
                                        Text(
                                          'Beschikbaar van ${startDate.day}/${startDate.month}/${startDate.year} tot ${endDate.day}/${endDate.month}/${endDate.year}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 20,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            mini: true,
                            heroTag: "zoomIn",
                            child: const Icon(Icons.zoom_in),
                            onPressed: () {
                              mapController.move(
                                mapController.center,
                                mapController.zoom + 1,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            heroTag: "zoomOut",
                            child: const Icon(Icons.zoom_out),
                            onPressed: () {
                              mapController.move(
                                mapController.center,
                                mapController.zoom - 1,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
