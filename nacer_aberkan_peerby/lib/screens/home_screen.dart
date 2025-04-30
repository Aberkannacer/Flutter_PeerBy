import 'package:flutter/material.dart';
import 'add_device_screen.dart';
import 'map_screen.dart';
import 'device_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerBy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logout werkt nog niet')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Huur en deel eenvoudig!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Bekijk toestellen in jouw buurt.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Voeg toestel toe'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Bekijk kaart'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviceListScreen()),
                  );
                },
                icon: const Icon(Icons.list),
                label: const Text('Bekijk toestellenlijst'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Mijn gehuurde toestellen',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.build),
                    title: const Text('Boormachine (Antwerpen)'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.beach_access),
                    title: const Text('Tent (Gent)'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Mijn verhuurde toestellen',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.grass),
                    title: const Text('Grasmaaier (gehuurd door Tom)'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.party_mode),
                    title: const Text('Partytent (gehuurd door Lisa)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
