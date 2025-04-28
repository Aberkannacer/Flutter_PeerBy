import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../services/device_service.dart';
import '../screens/device_list_screen.dart'; 


class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategory = 'Overige';
  final DeviceService _deviceService = DeviceService();
  LatLng? _selectedLocation;

  final List<String> _categories = [
    'Huishouden',
    'Tuin',
    'Keuken',
    'Elektronica',
    'Overige',
  ];

  Future<void> _geocodeAddress() async {
    try {
      List<Location> locations = await locationFromAddress(
        _addressController.text.trim(),
      );
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _selectedLocation = LatLng(loc.latitude, loc.longitude);
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Locatie gevonden!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geen locatie gevonden voor dit adres.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fout bij zoeken van adres: $e')));
    }
  }

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final priceText = _priceController.text.trim();
      final category = _selectedCategory;

      final double? price = double.tryParse(priceText);

      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fout: Vul een geldig getal in voor de prijs.'),
          ),
        );
        return;
      }

      final latitude = _selectedLocation!.latitude;
      final longitude = _selectedLocation!.longitude;

      try {
        await _deviceService.addDevice(
          name: name,
          description: description,
          price: price,
          category: category,
          latitude: latitude,
          longitude: longitude,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DeviceListScreen()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toestel succesvol opgeslagen!')),
        );

        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _addressController.clear();
        setState(() {
          _selectedCategory = 'Overige';
          _selectedLocation = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fout bij opslaan: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gelieve een locatie te kiezen!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toestel Aanbieden')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Naam van toestel',
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Vul een naam in'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Beschrijving'),
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Vul een beschrijving in'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prijs per dag (€)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vul een prijs in';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Vul een geldig getal in';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Categorie'),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres invullen',
                  hintText: 'bv. Frankrijklei 1, Antwerpen',
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _geocodeAddress,
                child: const Text('Zoek adres op kaart'),
              ),
              const SizedBox(height: 24),
              const Text('Klik op de kaart om manueel een locatie te kiezen:'),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(50.8503, 4.3517),
                    zoom: 7.0,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.peerby',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80,
                            height: 80,
                            point: _selectedLocation!,
                            builder:
                                (ctx) => const Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDevice,
                child: const Text('Toestel Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
