import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_device_screen.dart';
import 'map_screen.dart';
import 'device_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String userId;
  late Future<List<Map<String, dynamic>>> _myRentals;
  late Future<List<Map<String, dynamic>>> _myDevicesRented;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _myRentals = _loadMyRentals();
    _myDevicesRented = _loadMyDevicesRented();
  }

  Future<List<Map<String, dynamic>>> _loadMyRentals() async {
    final reservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('renterId', isEqualTo: userId)
        .get();

    final deviceIds = reservations.docs.map((doc) => doc['deviceId']).toList();
    if (deviceIds.isEmpty) return [];

    final devices = await FirebaseFirestore.instance
        .collection('devices')
        .where(FieldPath.documentId, whereIn: deviceIds)
        .get();

    return devices.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> _loadMyDevicesRented() async {
    final reservations = await FirebaseFirestore.instance
        .collection('reservations')
        .where('ownerId', isEqualTo: userId)
        .get();

    final deviceIds = reservations.docs.map((doc) => doc['deviceId']).toList();
    if (deviceIds.isEmpty) return [];

    final devices = await FirebaseFirestore.instance
        .collection('devices')
        .where(FieldPath.documentId, whereIn: deviceIds)
        .get();

    return devices.docs.map((d) => d.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerBy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Huur en deel eenvoudig!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text('Bekijk toestellen in jouw buurt.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDeviceScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Voeg toestel toe'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              ),
              icon: const Icon(Icons.map),
              label: const Text('Bekijk kaart'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DeviceListScreen()),
              ),
              icon: const Icon(Icons.list),
              label: const Text('Bekijk toestellenlijst'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Mijn gehuurde toestellen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _myRentals,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Geen gehuurde toestellen.');
                }
                return Column(
                  children: snapshot.data!
                      .map((device) => ListTile(
                            leading: const Icon(Icons.shopping_bag),
                            title: Text(device['name'] ?? 'Onbekend'),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Mijn verhuurde toestellen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _myDevicesRented,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nog geen toestellen verhuurd.');
                }
                return Column(
                  children: snapshot.data!
                      .map((device) => ListTile(
                            leading: const Icon(Icons.engineering),
                            title: Text(device['name'] ?? 'Onbekend'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
