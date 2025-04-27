import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = MapController(); // ✅ mapController hier

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaart met toestellen'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('devices').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final devices = snapshot.data!.docs;

          return FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(50.8503, 4.3517), // Brussel als startpositie
              initialZoom: 7.0, // 🔥 meer uitgezoomd
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.peerby',
              ),
              MarkerLayer(
                markers: devices.map((device) {
                  final data = device.data() as Map<String, dynamic>;

                  if (data['latitude'] == null || data['longitude'] == null) {
                    return Marker(
                      width: 0,
                      height: 0,
                      point: LatLng(0, 0),
                      child: const SizedBox.shrink(),
                    );
                  }

                  final double latitude = (data['latitude'] as num).toDouble();
                  final double longitude = (data['longitude'] as num).toDouble();

                  return Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(latitude, longitude),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
