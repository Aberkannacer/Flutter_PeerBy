import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeviceService {
  final CollectionReference devicesCollection = FirebaseFirestore.instance
      .collection('devices');

  Future<void> addDevice({
    required String name,
    required String description,
    required double price,
    required String category,
    required double latitude,
    required double longitude,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await FirebaseFirestore.instance.collection('devices').add({
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': Timestamp.now(),
      'ownerId': FirebaseAuth.instance.currentUser!.uid,
    });
  }
}
