import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/firebase/firebase_options.dart';
import 'package:ejp_ride_version/pages/dashboard.dart';
import 'package:ejp_ride_version/pages/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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
