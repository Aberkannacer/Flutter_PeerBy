import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';

class EditDeviceScreen extends StatefulWidget {
  final String deviceId;

  const EditDeviceScreen({super.key, required this.deviceId});

  @override
  State<EditDeviceScreen> createState() => _EditDeviceScreenState();
}

class _EditDeviceScreenState extends State<EditDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final MapController _mapController = MapController();

  String _selectedCategory = 'Overige';
  DateTime? _startDate;
  DateTime? _endDate;
  LatLng? _selectedLocation;

  final List<String> _categories = [
    'Huishouden',
    'Tuin',
    'Keuken',
    'Elektronica',
    'Overige',
  ];

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('devices')
            .doc(widget.deviceId)
            .get();

    final data = doc.data();
    if (data != null) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _priceController.text = data['price']?.toString() ?? '';
        _selectedCategory = data['category'] ?? 'Overige';
        _startDate = (data['startDate'] as Timestamp?)?.toDate();
        _endDate = (data['endDate'] as Timestamp?)?.toDate();
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _selectedLocation = LatLng(lat, lng);
        }
      });
    }
  }

  Future<void> _selectAvailability() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

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
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fout bij zoeken van adres: $e')));
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .update({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
            'category': _selectedCategory,
            'startDate': _startDate,
            'endDate': _endDate,
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Wijzigingen opgeslagen.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toestel Bewerken')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Naam'),
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prijs per dag'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                value: _selectedCategory,
                items:
                    _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged:
                    (value) =>
                        setState(() => _selectedCategory = value as String),
                decoration: const InputDecoration(labelText: 'Categorie'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectAvailability,
                child: const Text('Kies beschikbaarheid'),
              ),
              if (_startDate != null && _endDate != null)
                Text(
                  'Van ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} tot ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  style: const TextStyle(color: Colors.green),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adres (optioneel)',
                ),
              ),
              ElevatedButton(
                onPressed: _geocodeAddress,
                child: const Text('Zoek adres op kaart'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _selectedLocation ?? LatLng(50.85, 4.35),
                    zoom: 10,
                    onTap:
                        (_, point) => setState(() => _selectedLocation = point),
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
                            width: 40,
                            height: 40,
                            point: _selectedLocation!,
                            builder:
                                (ctx) => const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
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
                onPressed: _saveChanges,
                child: const Text('Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
