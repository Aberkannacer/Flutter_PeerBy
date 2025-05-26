import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nacer_aberkan_peerby/screens/RentalDetailScreen.dart';
import 'package:nacer_aberkan_peerby/screens/RentalSummaryScreen.dart';
import 'add_device_screen.dart';
import 'map_screen.dart';
import 'device_list_screen.dart';
import 'my_devices_screen.dart';

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
    final reservations =
        await FirebaseFirestore.instance
            .collection('reservations')
            .where('renterId', isEqualTo: userId)
            .get();

    final deviceIds = reservations.docs.map((doc) => doc['deviceId']).toList();
    if (deviceIds.isEmpty) return [];

    final devices =
        await FirebaseFirestore.instance
            .collection('devices')
            .where(FieldPath.documentId, whereIn: deviceIds)
            .get();

    return devices.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _loadMyDevicesRented() async {
    final reservations =
        await FirebaseFirestore.instance
            .collection('reservations')
            .where('ownerId', isEqualTo: userId)
            .get();

    final deviceIds = reservations.docs.map((doc) => doc['deviceId']).toList();
    if (deviceIds.isEmpty) return [];

    final devices =
        await FirebaseFirestore.instance
            .collection('devices')
            .where(FieldPath.documentId, whereIn: deviceIds)
            .get();

    return devices.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return data;
    }).toList();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDeviceList(
    Future<List<Map<String, dynamic>>> future,
    bool isRental,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text(
            isRental
                ? 'Geen gehuurde toestellen.'
                : 'Nog geen toestellen verhuurd.',
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final device = snapshot.data![index];
            return Card(
              elevation: 2,
              child: ListTile(
                leading:
                    device['photoUrl'] != null
                        ? Image.network(
                          device['photoUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                        : const Icon(Icons.devices),
                title: Text(device['name'] ?? 'Onbekend'),
                subtitle: Text(device['category'] ?? ''),
                trailing: Icon(
                  isRental ? Icons.shopping_bag : Icons.engineering,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              isRental
                                  ? RentalDetailScreen(deviceId: device['id'])
                                  : RentalSummaryScreen(
                                    deviceId: device['id'],
                                    deviceData: device,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welkom bij PeerBy!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Huur en deel eenvoudig met anderen.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddDeviceScreen(),
                        ),
                      ),
                  icon: const Icon(Icons.add),
                  label: const Text('Voeg toestel toe'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      ),
                  icon: const Icon(Icons.map),
                  label: const Text('Bekijk kaart'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DeviceListScreen(),
                        ),
                      ),
                  icon: const Icon(Icons.list),
                  label: const Text('Toestellenlijst'),
                ),
                ElevatedButton.icon(
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyDevicesScreen(),
                        ),
                      ),
                  icon: const Icon(Icons.settings),
                  label: const Text('Mijn toestellen'),
                ),
              ],
            ),
            const Divider(height: 40, thickness: 1),
            _buildSectionTitle('Mijn gehuurde toestellen'),
            _buildDeviceList(_myRentals, true),
            const SizedBox(height: 24),
            _buildSectionTitle('Mijn verhuurde toestellen'),
            _buildDeviceList(_myDevicesRented, false),
          ],
        ),
      ),
    );
  }
}
