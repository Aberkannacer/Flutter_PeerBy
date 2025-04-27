import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'add_device_screen.dart';
import 'device_list_screen.dart'; // 🔥 Importeren!

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welkom! Je bent ingelogd.',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDeviceScreen()),
                );
              },
              child: const Text('Voeg toestel toe'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DeviceListScreen()),
                );
              },
              child: const Text('Toestellen bekijken'),
            ),
          ],
        ),
      ),
    );
  }
}
