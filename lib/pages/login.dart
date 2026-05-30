// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ejp_ride_version/elements/mytextfield.dart';
import 'package:ejp_ride_version/firebase/firebase.dart';
import 'package:ejp_ride_version/pages/dashboard.dart';
import 'package:ejp_ride_version/pages/rolepage.dart';
import 'package:ejp_ride_version/pages/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool showPassword = false;

  //login function

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Aucun utilisateur trouvé.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (!userDoc.exists || userDoc.data() == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RolePage()),
        );
        return;
      }

      final data = userDoc.data()!;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(
            role: data['role'] ?? '',
            name: data['fullName'] ?? '',
            email: data['email'] ?? user.email ?? '',
            zone: data['zone'] ?? '',
            phone: data['phone'] ?? '',
            profileImageUrl: data['profileImageUrl'] ?? '',
          ),
        ),
      );
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // forgot password
  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer votre courriel d’abord.'),
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un courriel de réinitialisation vous a été envoyé.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’envoyer le courriel de réinitialisation.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 28, 28, 47),
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).viewInsets.bottom -
                      80,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'EJP Ride',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.car_detailed,
                            color: Colors.green,
                            size: 64,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Bienvenue',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 30),

                        MyTextFormField(
                          controller: emailController,
                          labelText: 'Courriel',
                          hintText: 'Saisissez votre courriel',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le courriel est requis.';
                            }

                            if (!value.contains('@')) {
                              return 'Veuillez saisir un courriel valide.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 18),

                        MyTextFormField(
                          controller: passwordController,
                          labelText: 'Mot de passe',
                          hintText: 'Saisissez votre mot de passe',
                          obscureText: !showPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showPassword
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le mot de passe est requis.';
                            }

                            if (value.length < 6) {
                              return 'Le mot de passe doit comporter au moins 6 caractères.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: resetPassword,
                            child: const Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isLoading ? null : login,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Connexion',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Vous n'avez pas encore de compte ?",
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                " S'inscrire",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
