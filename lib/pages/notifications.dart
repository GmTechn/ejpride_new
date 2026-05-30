import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createNotification({
  required String userId,
  required String title,
  required String message,
  String type = 'general',
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'userId': userId,
    'title': title,
    'message': message,
    'type': type,
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
