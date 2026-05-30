// ignore_for_file: deprecated_member_use

import 'package:ejp_ride_version/elements/mytextfield.dart';
import 'package:ejp_ride_version/firebase/firebase.dart';
import 'package:ejp_ride_version/pages/rolepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool showPassword = false;
  bool showconfirmPassword = false;

  Future<void> signUp() async {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les mots de passe ne correspondent pas.'),
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        await _authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RolePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Une erreur est survenue lors de la création du compte.',
            ),
          ),
        );
      }

      setState(() {
        isLoading = false;
      });
    }
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

                        const SizedBox(height: 20),

                        const Text(
                          'Créer un compte',
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
                          hintText: 'Entrez votre courriel',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Le courriel est requis.';
                            }

                            if (!value.contains('@')) {
                              return 'Veuillez entrer un courriel valide.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

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

                        const SizedBox(height: 16),

                        MyTextFormField(
                          controller: confirmPasswordController,
                          labelText: 'Confirmation du mot de passe',
                          hintText: 'Confirmez votre mot de passe',
                          obscureText: !showconfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              showconfirmPassword
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                showconfirmPassword = !showconfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez confirmer votre mot de passe.';
                            }

                            if (value != passwordController.text) {
                              return 'Les mots de passe ne correspondent pas.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

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
                            onPressed: isLoading ? null : signUp,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Créer un compte',
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
                              'Vous avez déjà un compte ? ',
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Connexion',
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
