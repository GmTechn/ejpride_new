import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/firebase/firebase_options.dart';
import 'package:ejp_ride_version/pages/dashboard.dart';
import 'package:ejp_ride_version/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<void> setupPushNotifications() async {
  final messaging = FirebaseMessaging.instance;

  await messaging.requestPermission(alert: true, badge: true, sound: true);

  final token = await messaging.getToken();
  debugPrint('====================');
  debugPrint('FCM TOKEN = $token');
  debugPrint('====================');

  debugPrint('FCM TOKEN: $token');

  final user = FirebaseAuth.instance.currentUser;

  if (user != null && token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': newToken},
      );
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }

  await setupPushNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ejp Ride',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color.fromARGB(255, 28, 28, 47),
            );
          }

          return snapshot.hasData ? const AuthGate() : const LoginPage();
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginPage();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color.fromARGB(255, 28, 28, 47),
            body: Center(child: CircularProgressIndicator(color: Colors.green)),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const LoginPage();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return DashboardPage(
          role: data['role'] ?? '',
          name: data['fullName'] ?? '',
          email: data['email'] ?? user.email ?? '',
          zone: data['zone'] ?? '',
          phone: data['phone'] ?? '',
          profileImageUrl: data['profileImageUrl'] ?? '',
        );
      },
    );
  }
}
