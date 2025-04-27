import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // We gebruiken AuthService om uit te loggen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService(); // 🔥 Maak AuthService instance

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
      body: const Center(
        child: Text(
          'Welkom! Je bent ingelogd.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
