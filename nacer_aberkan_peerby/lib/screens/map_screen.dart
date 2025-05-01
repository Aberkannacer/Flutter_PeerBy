import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  final PopupController popupController = PopupController();

  String _selectedCategory = 'Alle';
  final List<String> _categories = [
    'Alle',
    'Huishouden',
    'Tuin',
    'Keuken',
    'Elektronica',
    'Overige',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kaart met toestellen')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedCategory,
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
                    _selectedCategory == 'Alle'
                        ? devices
                        : devices.where((device) {
                          final data = device.data() as Map<String, dynamic>;
                          return data['category'] == _selectedCategory;
                        }).toList();

                final markers =
                    filteredDevices.map((device) {
                      final data = device.data() as Map<String, dynamic>;

                      if (data['latitude'] == null ||
                          data['longitude'] == null) {
                        return Marker(
                          width: 0,
                          height: 0,
                          point: LatLng(0, 0),
                          rotate: false,
                          builder: (ctx) => const SizedBox.shrink(),
                        );
                      }

                      final double latitude =
                          (data['latitude'] as num).toDouble();
                      final double longitude =
                          (data['longitude'] as num).toDouble();

                      return Marker(
                        width: 80,
                        height: 80,
                        point: LatLng(latitude, longitude),
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
                        center: LatLng(50.8503, 4.3517),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        'Categorie: ${data['category'] ?? 'Onbekend'}',
                                      ),
                                      const SizedBox(height: 4),
                                      if (startDate != null && endDate != null)
                                        Text(
                                          'Beschikbaar van ${startDate.day}/${startDate.month}/${startDate.year} '
                                          'tot ${endDate.day}/${endDate.month}/${endDate.year}',
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
