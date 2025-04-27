import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceService {
  final CollectionReference devicesCollection =
      FirebaseFirestore.instance.collection('devices'); // collectie 'devices' aanmaken

  Future<void> addDevice({
    required String name,
    required String description,
    required double price,
    required String category,
  }) async {
    await devicesCollection.add({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'createdAt': Timestamp.now(),
    });
  }
}
