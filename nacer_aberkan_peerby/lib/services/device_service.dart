import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {
  final CollectionReference devicesCollection =
      FirebaseFirestore.instance.collection('devices');

  Future<void> addDevice({
    required String name,
    required String description,
    required double price,
    required String category,
    required double latitude, 
    required double longitude, 
  }) async {
    await devicesCollection.add({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'latitude': latitude, 
      'longitude': longitude, 
      'createdAt': Timestamp.now(),
    });
  }
}
