import 'package:flutter/material.dart';
import '../services/device_service.dart'; // 🔥 importeren!

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
  String _selectedCategory = 'Overige';

  final DeviceService _deviceService = DeviceService(); // 🔥 instance maken

  final List<String> _categories = [
    'Huishouden',
    'Tuin',
    'Keuken',
    'Elektronica',
    'Overige',
  ];

  Future<void> _saveDevice() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final category = _selectedCategory;

      try {
        await _deviceService.addDevice(
          name: name,
          description: description,
          price: price,
          category: category,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toestel succesvol opgeslagen!')),
        );

        // Velden leegmaken
        _formKey.currentState!.reset();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        setState(() {
          _selectedCategory = 'Overige';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fout bij opslaan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toestel Aanbieden'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Naam van toestel'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vul een naam in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Beschrijving'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vul een beschrijving in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prijs per dag (€)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vul een prijs in';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Vul een geldig getal in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Categorie'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveDevice,
                child: const Text('Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
